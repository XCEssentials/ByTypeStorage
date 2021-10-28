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
protocol SomeFeatureState: SomeStorableByKey {}

//---

public
protocol SomeSelfContainedFeature: SomeSelfKey, SomeStorableByKey {}

//---

@MainActor
open
class FeatureShell
{
    private
    let dispatcher: StorageDispatcher
    
    public
    init(
        with dispatcher: StorageDispatcher
    ) {
        
        self.dispatcher = dispatcher
    }
    
    /// NOTE: this will result with updateing storage and sending updates to observers.
    public
    func access(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        _ handler: StorageDispatcher.AccessHandler
    ) throws {
        
        // in uni-directionl data flow context we do not want to return anything directly
        // but we want to propagate thrown errors
        _ = try dispatcher.access(
            scope: scope,
            context: context,
            location: location,
            handler
        )
    }
    
    /// NOTE: this will result with updateing storage and sending updates to observers.
    public
    func must(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        _ handler: StorageDispatcher.AccessHandler
    ) {
        
        do
        {
            // in uni-directionl data flow context we do not want to return anything directly
            // but we want to propagate thrown errors
            _ = try dispatcher.access(
                scope: scope,
                context: context,
                location: location,
                handler
            )
        }
        catch
        {
            fatalError(error.localizedDescription)
        }
    }
    
    /// NOTE: this will result with updateing storage and sending updates to observers.
    @discardableResult
    public
    func should(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        _ handler: StorageDispatcher.AccessHandler
    ) -> Bool {
        
        do
        {
            // in uni-directionl data flow context we do not want to return anything directly
            // but we want to propagate thrown errors
            _ = try dispatcher.access(
                scope: scope,
                context: context,
                location: location,
                handler
            )
            
            //---
            
            return true
        }
        catch
        {
            return false
        }
    }
}
