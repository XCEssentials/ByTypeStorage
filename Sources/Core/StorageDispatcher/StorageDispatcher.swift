/*
 
 MIT License
 
 Copyright (c) 2016 Maxim Khatskevich (maxim@khatskevi.ch)
 
 Permission is hereby granted, free of charge, to any person obtaining a copy
 of this software and associated documentation files (the "Software"), to deal
 in the Software without restriction, including without limitation the rights
 to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the Software is
 furnished to do so, subject to the following conditions:
 
 The above copyright notice and this permission notice shall be included in all
 copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 SOFTWARE.
 
 */

import Combine

//---

@MainActor
public
final
class StorageDispatcher
{
    private
    var storage: ByTypeStorage
    
    private
    var bindings: [String: [AnyCancellable]] = [:]
    
    private
    let _accessLog = PassthroughSubject<AccessReport, Never>()
    
    private
    let _bindingsStatusLog = PassthroughSubject<AccessReportBindingStatus, Never>()
    
    //---
    
    public
    var accessLog: AnyPublisher<AccessReport, Never>
    {
        _accessLog.eraseToAnyPublisher()
    }
    
    public
    var bindingsStatusLog: AnyPublisher<AccessReportBindingStatus, Never>
    {
        _bindingsStatusLog.eraseToAnyPublisher()
    }
    
    //---
    
    public
    init(
        with storage: ByTypeStorage = ByTypeStorage()
    ) {
        
        self.storage = storage
    }
}

// MARK: - Nested types

public
extension StorageDispatcher
{
    enum AccessReportBindingSource
    {
        case keyType(SomeKey.Type)
        case observerType(StorageObserver.Type)
    }
    
    struct AccessReportBinding<W: Publisher, G>: SomeAccessEventBinding
    {
        public
        let source: AccessReportBindingSource
        
        public
        let description: String
        
        public
        let scope: String
        
        public
        let location: Int
        
        //internal
        let when: (AnyPublisher<StorageDispatcher.AccessReport, Never>) -> W
        
        //internal
        let given: (StorageDispatcher, W.Output) throws -> G?
        
        //internal
        let then: (StorageDispatcher, G) -> Void
        
        @MainActor
        public
        func construct(with dispatcher: StorageDispatcher) -> AnyCancellable
        {
            when(dispatcher.accessLog)
                .tryCompactMap { [weak dispatcher] in
                    
                    guard let dispatcher = dispatcher else { return nil }
                    
                    //---
                    
                    return try given(dispatcher, $0)
                }
                .handleEvents(
                    receiveOutput: { [weak dispatcher] (_: G) in
                        
                        guard let dispatcher = dispatcher else { return }
                        
                        //---
                        
                        dispatcher
                            ._bindingsStatusLog
                            .send(
                                .triggered(self)
                            )
                    }
                )
                .compactMap { [weak dispatcher] in
                    
                    guard let dispatcher = dispatcher else { return nil }

                    //---

                    return then(dispatcher, $0) // map into `Void` to erase type info
                }
                .handleEvents(
                    receiveSubscription: { [weak dispatcher] _ in
                        
                        guard let dispatcher = dispatcher else { return }
                        
                        //---
                        
                        dispatcher
                            ._bindingsStatusLog
                            .send(
                                .activated(self)
                            )
                    },
                    receiveCancel: { [weak dispatcher] in
                        
                        guard let dispatcher = dispatcher else { return }
                        
                        //---
                        
                        dispatcher
                            ._bindingsStatusLog
                            .send(
                                .cancelled(self)
                            )
                    }
                )
                .sink(
                    receiveCompletion: { [weak dispatcher] in
                        
                        guard let dispatcher = dispatcher else { return }
                        
                        //---
                        
                        switch $0
                        {
                            case .failure(let error):
                                
                                dispatcher
                                    ._bindingsStatusLog
                                    .send(
                                        .failed(self, error)
                                    )
                                
                            default:
                                break
                        }
                    },
                    receiveValue: { [weak dispatcher] in
                        
                        guard let dispatcher = dispatcher else { return }
                        
                        //---
                        
                        dispatcher
                            ._bindingsStatusLog
                            .send(
                                .executed(self)
                            )
                    }
                )
        }
    }
    
    enum AccessReportBindingStatus
    {
        case activated(SomeAccessEventBinding)
        
        /// After passing through `when` (and `given`,
        /// if present) claus(es), right before `then`.
        case triggered(SomeAccessEventBinding)
        
        /// After executing `then` clause.
        case executed(SomeAccessEventBinding)
        
        case failed(SomeAccessEventBinding, Error)
        
        case cancelled(SomeAccessEventBinding)
    }
}

// MARK: - Access data

public
extension StorageDispatcher
{
    typealias AccessHandler = (inout ByTypeStorage) throws -> Void
    
    enum AccessError: Error
    {
        case concurrentMutatingAccessDetected
    }

    /// Transaction-like isolation for mutations on the storage.
    @discardableResult
    func access(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        _ handler: AccessHandler
    ) throws -> ByTypeStorage.History {
        
        // we want to avoid partial changes to be applied in case the handler throws
        var tmpCopyStorage = storage
        let lastHistoryResetId = tmpCopyStorage.lastHistoryResetId
        
        //---
        
        let mutationsToReport: ByTypeStorage.History
        
        do
        {
            try handler(&tmpCopyStorage) // NOTE: another call to `access` can be made inside
            
            //---
            
            mutationsToReport = tmpCopyStorage.resetHistory()
            
            //---
            
            switch lastHistoryResetId == storage.lastHistoryResetId // still the same snapshot?
            {
                // no concurrent mutations have been done:
                case true where !mutationsToReport.isEmpty: // and we have mutations to save
                    
                    // apply changes to permanent storage
                    storage = tmpCopyStorage // NOTE: the history has already been cleared
                    
                // seems like another concurrent mutating access has been done:
                case false where !mutationsToReport.isEmpty: // and we have mutations here
                    
                    // the API has been misused - mutations here and in a nested transaction?
                    throw AccessError.concurrentMutatingAccessDetected
                    
                default:
                    // if concurrent mutations have been applied, but we don't have mutations
                    // here - it's totally fine to ignore, we jsut do nothing - no error, but also
                    // IMPORTANT to NOTE: we do NOT apply the temporary copy back to the storage!
                    break
            }
        }
        catch
        {
            _accessLog.send(
                .init(
                    outcome: .rejected(
                        reason: error /// NOTE: error from `handler` or `AccessError`
                        ),
                    storage: storage,
                    env: .init(
                        scope: scope,
                        context: context,
                        location: location
                    )
                )
            )
            
            //---
            
            throw error
        }
        
        //---
        
        installBindings(
            basedOn: mutationsToReport
        )
        
        //---
        
        _accessLog.send(
            .init(
                outcome: .processed(
                    mutations: mutationsToReport
                ),
                storage: storage,
                env: .init(
                    scope: scope,
                    context: context,
                    location: location
                )
            )
        )
        
        //---
        
        uninstallBindings(
            basedOn: mutationsToReport
        )
        
        //---
        
        return mutationsToReport
    }
}

// MARK: - Bindings management

private
extension StorageDispatcher
{
    /// This will install bindings for newly initialized keys.
    func installBindings(
        basedOn reports: ByTypeStorage.History
    ) {
        
        reports
            .compactMap { report -> SomeKey.Type? in
                
                switch report.outcome
                {
                    case .initialization(let key, _):
                        return key
                        
                    default:
                        return nil
                }
            }
            .map {
                
                ( key: $0, bindings: $0.bindings.map { $0.construct(with: self) } )
            }
            .forEach {
                
                self.bindings[$0.key.name] = $0.bindings
            }
    }
    
    /// This will uninstall bindings for recently deinitialized keys.
    func uninstallBindings(
        basedOn reports: ByTypeStorage.History
    ) {
        
        reports
            .compactMap { report -> SomeKey.Type? in
                
                switch report.outcome
                {
                    case .deinitialization(let key, _):
                        return key
                        
                    default:
                        return nil
                }
            }
            .forEach {
                
                self.bindings.removeValue(forKey: $0.name)
            }
    }
}
