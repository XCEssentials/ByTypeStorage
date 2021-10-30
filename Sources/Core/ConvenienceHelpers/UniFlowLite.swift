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
        _ handler: () throws -> Void
    ) throws {
        
        // in uni-directionl data flow context we do not want to return anything directly
        // but we want to propagate thrown errors
        _ = try storage.access(
            scope: scope,
            context: context,
            location: location,
            { _ in try handler() }
        )
    }
    
    /// Wrap throwing piece of code and crash with `fatalError` if an error is thrown.
    public
    func must(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        _ handler: () throws -> Void
    ) {
        do
        {
            try storage.access(
                scope: scope,
                context: context,
                location: location,
                { _ in try handler() }
            )
        }
        catch
        {
            fatalError(error.localizedDescription)
        }
    }
    
    /// Wrap throwing piece of code and crash in DEBUG ONLY (via assertation) if an error is thrown.
    public
    func assert(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        _ handler: () throws -> Void
    ) {
        do
        {
            try storage.access(
                scope: scope,
                context: context,
                location: location,
                { _ in try handler() }
            )
        }
        catch
        {
            assertionFailure(error.localizedDescription)
        }
    }
    
    /// Wrap throwing piece of code and fail softly by ignoring thrown error.
    @discardableResult
    public
    func should(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        _ handler: () throws -> Void
    ) -> Bool {
        
        do
        {
            try storage.access(
                scope: scope,
                context: context,
                location: location,
                { _ in try handler() }
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

@MainActor
public
extension SomeKey where Self: FeatureShell
{
    @discardableResult
    func ensureCurrentState<V: SomeStorableByKey>(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        _ valueOfType: V.Type = V.self
    ) throws -> V where V.Key == Self {
        
        try storage.fetch(
            scope: scope,
            context: context,
            location: location,
            valueOfType: V.self
        )
    }
    
    func initialize<V: SomeStorableByKey>(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        with newValue: V
    ) throws where V.Key == Self {
        
        try storage.access(scope: scope, context: context, location: location) {
            
            try $0.initialize(with: newValue)
        }
    }
    
    func actualize<V: SomeStorableByKey>(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        _ valueOfType: V.Type = V.self,
        via mutationHandler: (inout V) throws -> Void
    ) throws where V.Key == Self {
        
        try storage.access(scope: scope, context: context, location: location) {
           
            try $0.actualize(V.self, via: mutationHandler)
        }
    }
    
    func actualize<V: SomeStorableByKey>(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        with newValue: V
    ) throws where V.Key == Self {
        
        try storage.access(scope: scope, context: context, location: location) {
           
            try $0.actualize(with: newValue)
        }
    }
    
    func transition<O: SomeStorableByKey, N: SomeStorableByKey>(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        from oldValueInstance: O,
        into newValue: N
    ) throws where O.Key == Self, N.Key == Self {
        
        try transition(
            scope: scope,
            context: context,
            location: location,
            from: O.self,
            into: newValue
        )
    }
    
    func transition<O: SomeStorableByKey, N: SomeStorableByKey>(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        from oldValueType: O.Type,
        into newValue: N
    ) throws where O.Key == Self, N.Key == Self {
        
        try storage.access(scope: scope, context: context, location: location) {
           
            try $0.transition(from: O.self, into: newValue)
        }
    }
    
    func transition<V: SomeStorableByKey>(
        scope: String = #file,
        context: String = #function,
        location: Int = #line,
        overrideSame: Bool = false,
        into newValue: V
    ) throws where V.Key == Self {
        
        try storage.access(scope: scope, context: context, location: location) {
           
            try $0.transition(overrideSame: overrideSame, into: newValue)
        }
    }
    
    func deinitialize(
        scope: String = #file,
        context: String = #function,
        location: Int = #line
    ) throws {
        
        try storage.access(scope: scope, context: context, location: location) {
           
            try $0.deinitialize(Self.self)
        }
    }
}
