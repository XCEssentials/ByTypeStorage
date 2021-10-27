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
    let _outcomes = PassthroughSubject<AccessRequestOutcome, Never>()
    
    public
    lazy
    var outcomes: AnyPublisher<AccessRequestOutcome, Never> = _outcomes.eraseToAnyPublisher()
    
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
    
    enum AccessRequestOutcome
    {
        /// Mutation has been succesfully processed and already applied to the `storage`.
        ///
        /// Includes most recent snapshot of the `storage` and list of recent changes.
        case processed(
            storage: ByTypeStorage,
            mutations: ByTypeStorage.History,
            env: EnvironmentInfo
        )
        
        /// Mutation has been rejected due to an error thrown from mutation handler.
        ///
        /// NO changes have been applied to the `storage`.
        case rejected(
            reason: Error,
            env: EnvironmentInfo
        )
        
        public
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
            _outcomes.send(
                .rejected(
                    reason: error,
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
        
        _outcomes.send(
            .processed(
                storage: storage,
                mutations: mutationsToReport,
                env: .init(
                    scope: scope,
                    context: context,
                    location: location
                )
            )
        )
        
        //---
        
        return mutationsToReport
    }
}
