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

import Foundation
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
    let _accessLog = PassthroughSubject<AccessEventReport, Never>()
    
    public
    lazy
    var accessLog: AnyPublisher<AccessEventReport, Never> = _accessLog.eraseToAnyPublisher()
    
    private
    let _bindingsProcessingLog = PassthroughSubject<AccessEventBindingProcessingReport, Never>()
    
    public
    lazy
    var bindingsProcessingLog: AnyPublisher<AccessEventBindingProcessingReport, Never> = _bindingsProcessingLog.eraseToAnyPublisher()
    
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
    typealias AccessHandler = (inout ByTypeStorage) throws -> Void
    
    enum AccessError: Error
    {
        case concurrentMutatingAccessDetected
    }
    
    struct EnvironmentInfo
    {
        public
        let timestamp = Date()
        
        public
        let scope: String
        
        public
        let context: String
        
        public
        let location: Int
    }
    
    struct AccessEventReport
    {
        public
        let outcome: AccessRequestOutcome
        
        public
        let storage: ByTypeStorage
        
        public
        let env: EnvironmentInfo
    }
    
    struct ProcessedAccessEventReport
    {
        public
        let mutations: ByTypeStorage.History
        
        public
        let storage: ByTypeStorage
        
        public
        let env: EnvironmentInfo
    }
    
    struct RejectedAccessEventReport
    {
        public
        let reason: Error
        
        public
        let storage: ByTypeStorage
        
        public
        let env: EnvironmentInfo
    }
    
    enum AccessRequestOutcome
    {
        /// Mutation has been succesfully processed and already applied to the `storage`.
        ///
        /// Includes most recent snapshot of the `storage` and list of recent changes.
        case processed(
            mutations: ByTypeStorage.History
        )
        
        /// Mutation has been rejected due to an error thrown from mutation handler.
        ///
        /// NO changes have been applied to the `storage`.
        case rejected(
            reason: Error
        )
    }
    
    struct AccessEventBinding<W: Publisher, G>: SomeAccessEventBinding
    {
        public
        let source: AccessEventBindingSource
        
        public
        let description: String
        
        public
        let scope: String
        
        public
        let location: Int
        
        //internal
        let when: (AnyPublisher<StorageDispatcher.AccessEventReport, Never>) -> W
        
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
                            ._bindingsProcessingLog
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
                            ._bindingsProcessingLog
                            .send(
                                .activated(self)
                            )
                    },
                    receiveCancel: { [weak dispatcher] in
                        
                        guard let dispatcher = dispatcher else { return }
                        
                        //---
                        
                        dispatcher
                            ._bindingsProcessingLog
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
                                    ._bindingsProcessingLog
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
                            ._bindingsProcessingLog
                            .send(
                                .executed(self)
                            )
                    }
                )
        }
    }
    
    //---
    
    @MainActor
    struct WhenContext
    {
        public
        let source: AccessEventBindingSource
        
        public
        let description: String
        
        public
        func when<P: Publisher>(
            _ when: @escaping (AnyPublisher<StorageDispatcher.AccessEventReport, Never>) -> P
        ) -> GivenOrThenContext<P> {
            
            .init(
                source: source,
                description: description,
                when: { when($0) }
            )
        }
        
        public
        func when<M: SomeMutationDecriptor>(
            _: M.Type = M.self
        ) -> GivenOrThenContext<AnyPublisher<M, Never>> {
            
            .init(
                source: source,
                description: description,
                when: { $0.onProcessed.mutation(M.self).eraseToAnyPublisher() }
            )
        }
    }
    
    @MainActor
    struct GivenOrThenContext<W: Publisher>
    {
        public
        let source: AccessEventBindingSource
        
        public
        let description: String
        
        fileprivate
        let when: (AnyPublisher<StorageDispatcher.AccessEventReport, Never>) -> W
        
        public
        func given<G>(
            _ given: @escaping (StorageDispatcher, W.Output) throws -> G?
        ) -> ThenContext<W, G> {
            
            .init(
                source: source,
                description: description,
                when: when,
                given: given
            )
        }
        
        public
        func given<G>(
            _ dispatcherOnlyHandler: @escaping (StorageDispatcher) -> G?
        ) -> ThenContext<W, G> {
            
            given { dispatcher, _ in
                
                dispatcherOnlyHandler(dispatcher)
            }
        }
        
        public
        func given<G>(
            _ outputOnlyHandler: @escaping (W.Output) -> G?
        ) -> ThenContext<W, G> {
            
            given { _, output in
                
                outputOnlyHandler(output)
            }
        }
        
        public
        func then(
            scope: String = #file,
            location: Int = #line,
            _ then: @escaping (StorageDispatcher, W.Output) -> Void
        ) -> AccessEventBinding<W, W.Output> {
            
            .init(
                source: source,
                description: description,
                scope: scope,
                location: location,
                when: when,
                given: { $1 },
                then: then
            )
        }
        
        public
        func then(
            scope: String = #file,
            location: Int = #line,
            _ dispatcherOnlyHandler: @escaping (StorageDispatcher) -> Void
        ) -> AccessEventBinding<W, W.Output> {
            
            then(scope: scope, location: location) { dispatcher, _ in
                
                dispatcherOnlyHandler(dispatcher)
            }
        }
        
        public
        func then(
            scope: String = #file,
            location: Int = #line,
            _ outputOnlyHandler: @escaping (W.Output) -> Void
        ) -> AccessEventBinding<W, W.Output> {
            
            then(scope: scope, location: location) { _, output in
                
                outputOnlyHandler(output)
            }
        }
    }

    @MainActor
    struct ThenContext<W: Publisher, G>
    {
        public
        let source: AccessEventBindingSource
        
        public
        let description: String
        
        fileprivate
        let when: (AnyPublisher<StorageDispatcher.AccessEventReport, Never>) -> W
        
        fileprivate
        let given: (StorageDispatcher, W.Output) throws -> G?
        
        public
        func then(
            scope: String = #file,
            location: Int = #line,
            _ then: @escaping (StorageDispatcher, G) -> Void
        ) -> AccessEventBinding<W, G> {
            
            .init(
                source: source,
                description: description,
                scope: scope,
                location: location,
                when: when,
                given: given,
                then: then
            )
        }
        
        public
        func then(
            scope: String = #file,
            location: Int = #line,
            _ dispatcherOnlyHandler: @escaping (StorageDispatcher) -> Void
        ) -> AccessEventBinding<W, G> {
            
            then(scope: scope, location: location) { dispatcher, _ in
                
                dispatcherOnlyHandler(dispatcher)
            }
        }
        
        public
        func then(
            scope: String = #file,
            location: Int = #line,
            _ outputOnlyHandler: @escaping (G) -> Void
        ) -> AccessEventBinding<W, G> {
            
            then(scope: scope, location: location) { _, output in
                
                outputOnlyHandler(output)
            }
        }
    }
    
    enum AccessEventBindingProcessingReport
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

// MARK: - GET data - SomeKey

public
extension StorageDispatcher
{
    func fetch(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        valueForKey keyType: SomeKey.Type
    ) throws -> SomeStorable {
        
        var result: SomeStorable!
        
        //---
        
        try access(scope: scope, context: context, location: location) {
            
            result = try $0.fetch(valueForKey: keyType)
        }
        
        //---
        
        return result
    }
    
    func hasValue(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        withKey keyType: SomeKey.Type
    ) -> Bool {
        
        do
        {
            _ = try fetch(
                scope: scope,
                context: context,
                location: location,
                valueForKey: keyType
            )
            
            return true
        }
        catch
        {
            return false
        }
    }
}

// MARK: - GET data - SomeStorableByKey

public
extension StorageDispatcher
{
    func fetch<V: SomeStorableByKey>(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        valueOfType _: V.Type = V.self
    ) throws -> V {
        
        var result: V!
        
        //---
        
        try access(scope: scope, context: context, location: location) {
            
            result = try $0.fetch(valueOfType: V.self)
        }
        
        //---
        
        return result
    }
    
    //---
    
    func hasValue<V: SomeStorableByKey>(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        ofType _: V.Type
    ) -> Bool {
        
        do
        {
            _ = try fetch(
                scope: scope,
                context: context,
                location: location,
                valueOfType: V.self
            )
            
            return true
        }
        catch
        {
            return false
        }
    }
}

// MARK: - SET data

public
extension StorageDispatcher
{
    @discardableResult
    func process(
        _ request: AccessRequest
    ) throws -> ByTypeStorage.History {

        try process([request])
    }
    
    @discardableResult
    func process(
        _ requests: [AccessRequest]
    ) throws -> ByTypeStorage.History {

        // NOTE: do not throw errors here, subscribe for updates on dispatcher to observe outcomes
        try requests
            .flatMap {
                
                try access(
                    scope: $0.scope,
                    context: $0.context,
                    location: $0.location,
                    $0.body
                )
            }
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
