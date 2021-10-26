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

public
struct ActionRequest: SomeActionRequest
{
    public
    typealias NonThrowingBody = (inout ByTypeStorage) -> [ByTypeStorage.Mutation]
    
    //---
    
    public
    let scope: String
    
    public
    let context: String
    
    let nonThrowingBody: NonThrowingBody
    
    public
    var body: StorageDispatcher.ActionHandler
    {
        { nonThrowingBody(&$0) }
    }
    
    //---
    
    public
    init(
        scope: String = #file,
        context: String = #function,
        /*@MutationsBuilder*/
        manyMutations: @escaping NonThrowingBody
    ) {
        
        self.scope = scope
        self.context = context
        self.nonThrowingBody = manyMutations
    }
    
    public
    init(
        scope: String = #file,
        context: String = #function,
        /*@MutationsBuilder*/
        singleMutation: @escaping (inout ByTypeStorage) -> ByTypeStorage.Mutation
    ) {
        
        self.scope = scope
        self.context = context
        self.nonThrowingBody = { [singleMutation(&$0)] }
    }
    
    public
    init(
        scope: String = #file,
        context: String = #function,
        /*@MutationsBuilder*/
        readOnlyAccess: @escaping (ByTypeStorage) -> Void
    ) {
        
        self.scope = scope
        self.context = context
        self.nonThrowingBody = { readOnlyAccess($0); return [] }
    }
}
