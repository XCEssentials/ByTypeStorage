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

// MARK: - GET data

public
extension Storable
{
    @MainActor
    static
    func from(_ storage: StorageDispatcher) -> Self?
    {
        storage[self]
    }

    //---

    @MainActor
    static
    func isPresent(in storage: StorageDispatcher) -> Bool
    {
        storage.hasValue(self)
    }
}

// MARK: - SET data

public
extension Storable
{
    @MainActor
    @discardableResult
    func store(
        scope: String = #file,
        context: String = #function,
        in storage: StorageDispatcher
    ) -> [ByTypeStorage.Mutation] {
        
        storage.store(scope: scope, context: context, self)
    }
}

// MARK: - REMOVE data

public
extension Storable
{
    @MainActor
    @discardableResult
    func remove(
        scope: String = #file,
        context: String = #function,
        from storage: inout StorageDispatcher
    ) -> [ByTypeStorage.Mutation] {
        
        storage.removeValue(scope: scope, context: context, ofType: Self.self)
    }
    
    @MainActor
    @discardableResult
    static
    func remove(
        scope: String = #file,
        context: String = #function,
        from storage: inout StorageDispatcher
    ) -> [ByTypeStorage.Mutation] {
        
        storage.removeValue(scope: scope, context: context, ofType: self)
    }
}
