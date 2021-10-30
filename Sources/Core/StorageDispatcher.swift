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
    
    @MainActor
    struct AccessEventBinding
    {
        public
        let description: String
        
        public
        let scope: String
        
        public
        let location: Int
        
        @MainActor
        fileprivate
        let body: (StorageDispatcher) -> AnyCancellable
        
        //---
        
        @MainActor
        public
        struct DescriptionProxy
        {
            public
            let description: String
            
            @MainActor
            public
            func when<P: Publisher>(
                _ when: @escaping (AnyPublisher<StorageDispatcher.AccessEventReport, Never>) -> P
            ) -> WhenProxy<P.Output, P.Failure> {
                
                .init(
                    description: description,
                    when: { when($0).eraseToAnyPublisher() }
                )
            }
            
            @MainActor
            public
            func when<M: SomeMutationDecriptor, P: Publisher>(
                _: M.Type = M.self,
                _ map: @escaping (AnyPublisher<M, Never>) -> P
            ) -> WhenProxy<P.Output, P.Failure> {
                
                .init(
                    description: description,
                    when: { map($0.onProcessed.mutation(M.self)).eraseToAnyPublisher() }
                )
            }
            
            @MainActor
            public
            func when<M: SomeMutationDecriptor>(
                _: M.Type = M.self
            ) -> WhenProxy<M, Never> {
                
                .init(
                    description: description,
                    when: { $0.onProcessed.mutation(M.self).eraseToAnyPublisher() }
                )
            }
        }
        
        @MainActor
        public
        struct WhenProxy<T, E: Error>
        {
            public
            let description: String
            
            fileprivate
            let when: (AnyPublisher<StorageDispatcher.AccessEventReport, Never>) -> AnyPublisher<T, E>
            
            public
            func then(
                scope: String = #file,
                location: Int = #line,
                _ then: @escaping (StorageDispatcher, T) -> Void
            ) -> AccessEventBinding {
                
                .init(
                    description: description,
                    scope: scope,
                    location: location,
                    body: { dispatcher in
                        
                        when(dispatcher.accessLog)
                            .sink(
                                receiveCompletion: { _ in },
                                receiveValue: { output in then(dispatcher, output) }
                            )
                    }
                )
            }
            
            public
            func then(
                scope: String = #file,
                location: Int = #line,
                _ dispatcherOnlyHandler: @escaping (StorageDispatcher) -> Void
            ) -> AccessEventBinding {
                
                then(scope: scope, location: location) { dispatcher, _ in
                    
                    dispatcherOnlyHandler(dispatcher)
                }
            }
            
            public
            func then(
                scope: String = #file,
                location: Int = #line,
                _ outputOnlyHandler: @escaping (T) -> Void
            ) -> AccessEventBinding {
                
                then(scope: scope, location: location) { _, output in
                    
                    outputOnlyHandler(output)
                }
            }
        }
    }
}

// MARK: - GET data - SomeKey

public
extension StorageDispatcher
{
    subscript<K: SomeKey>(_: K.Type) -> SomeStorable?
    {
        storage[K.self]
    }
    
    func fetch<K: SomeKey>(valueForKey keyType: K.Type) throws -> SomeStorable
    {
        try storage.fetch(valueForKey: K.self)
    }
    
    func hasValue<K: SomeKey>(withKey _: K.Type) -> Bool
    {
        storage.hasValue(withKey: K.self)
    }
}

// MARK: - GET data - SomeStorable

public
extension StorageDispatcher
{
    func hasValue<V: SomeStorable>(ofType _: V.Type) -> Bool
    {
        storage.hasValue(ofType: V.self)
    }
}

// MARK: - GET data - SomeStorableByKey

public
extension StorageDispatcher
{
    subscript<V: SomeStorableByKey>(_ valueType: V.Type = V.self) -> V?
    {
        storage[V.self]
    }
    
    func fetch<V: SomeStorableByKey>(valueOfType _: V.Type = V.self) throws -> V
    {
        try storage.fetch(valueOfType: V.self)
    }
    
    //---
    
    func hasValue<V: SomeStorableByKey>(ofType _: V.Type) -> Bool
    {
        storage.hasValue(ofType: V.self)
    }
}

// MARK: - SET data

public
extension StorageDispatcher
{
    @discardableResult
    func process(
        _ request: AccessRequest
    ) -> ByTypeStorage.History {

        access(
            scope: request.scope,
            context: request.context,
            location: request.location,
            request.nonThrowingBody
        )
    }
    
    @discardableResult
    func process(
        _ request: AccessRequestThrowing
    ) throws -> ByTypeStorage.History {

        try access(
            scope: request.scope,
            context: request.context,
            location: request.location,
            request.body
        )
    }
    
    @discardableResult
    func process(
        _ requests: [SomeAccessRequest]
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
    
    @discardableResult
    func access(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        _ handler: AccessHandler
    ) rethrows -> ByTypeStorage.History {
        
        // we want to avoid partial changes to be applied in case the handler throws
        var tmpCopyStorage = storage
        
        //---
        
        let mutationsToReport: ByTypeStorage.History
        
        do
        {
            try handler(&tmpCopyStorage)
        }
        catch
        {
            _accessLog.send(
                .init(
                    outcome: .rejected(
                        reason: error
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
        
        mutationsToReport = tmpCopyStorage.resetHistory()
        
        // if handler didn't throw - we apply changes to permanent storage
        storage = tmpCopyStorage // NOTE: the history has already been cleared
        
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
                
                ( key: $0, bindings: $0.bindings.map { $0.body(self) } )
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
