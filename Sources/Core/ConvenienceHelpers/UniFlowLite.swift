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
protocol SomeFeature: SomeSelfKey {}

public
extension SomeFeature
{
    typealias Itself = Self
}

//---

public
protocol SomeState: SomeStorableByKey {}

//---

public
protocol SomeSelfContainedFeature: SomeSelfKey, SomeStorableByKey {}

//---

@MainActor
open
class FeatureShell
{
    public
    let storage: StorageDispatcher
    
    public
    init(
        with storageDispatcher: StorageDispatcher
    ) {
        
        self.storage = storageDispatcher
    }
    
    /// Group several read/write operations in one access report.
    public
    func access(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        _ handler: StorageDispatcher.AccessHandler
    ) throws {
        
        // in uni-directionl data flow context we do not want to return anything directly
        // but we want to propagate thrown errors
        _ = try storage.access(
            scope: scope,
            context: context,
            location: location,
            handler
        )
    }
    
    /// Wrap throwing piece of code and crash with `fatalError` if an error is thrown.
    public
    func must(
        _ handler: () throws -> Void
    ) {
        do
        {
            try handler()
        }
        catch
        {
            fatalError(error.localizedDescription)
        }
    }
    
    /// Wrap throwing piece of code and fail softly by ignoring thrown error.
    @discardableResult
    public
    func should(
        _ handler: () throws -> Void
    ) -> Bool {
        
        do
        {
            try handler()
            
            //---
            
            return true
        }
        catch
        {
            return false
        }
    }
}
