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
    public private(set)
    var storage: ByTypeStorage
    
    private
    let _mutations = PassthroughSubject<MutationNotice, Never>()
    
    public
    lazy
    var mutations: AnyPublisher<MutationNotice, Never> = _mutations.eraseToAnyPublisher()
    
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
    enum MutationNotice
    {
        /// Mutation has been succesfully processed and already applied to the `storage`.
        ///
        /// Includes most recent snapshot of the `storage` and list of recent changes.
        case processed(
            storage: ByTypeStorage,
            mutations: [ByTypeStorage.Mutation],
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
        }
    }
}

// MARK: - Mutations

public
extension StorageDispatcher
{
    @discardableResult
    func mutate(
        scope: String = #file,
        context: String = #function,
        via handler: (inout ByTypeStorage) throws -> ByTypeStorage.Mutation
    ) rethrows -> [ByTypeStorage.Mutation] {

        try mutate(scope: scope, context: context) { try [handler(&$0)] }
    }
    
    @discardableResult
    func mutate(
        scope: String = #file,
        context: String = #function,
        via handler: (inout ByTypeStorage) throws -> [ByTypeStorage.Mutation]
    ) rethrows -> [ByTypeStorage.Mutation] {
        
        // we want to avoid partial changes to be applied in case the handler throws
        var tmpCopyStorage = storage
        
        //---
        
        let mutationsToReport: [ByTypeStorage.Mutation]
        
        do
        {
            mutationsToReport = try handler(&tmpCopyStorage)
        }
        catch
        {
            _mutations.send(
                .rejected(
                    reason: error,
                    env: .init(
                        scope: scope,
                        context: context
                    )
                )
            )
            
            //---
            
            throw error
        }
        
        //---
        
        // if handler didn't throw - we apply changes to permanent storage
        storage = tmpCopyStorage
        
        //---
        
        _mutations.send(
            .processed(
                storage: storage,
                mutations: mutationsToReport,
                env: .init(
                    scope: scope,
                    context: context
                )
            )
        )
        
        //---
        
        return mutationsToReport
    }
}
