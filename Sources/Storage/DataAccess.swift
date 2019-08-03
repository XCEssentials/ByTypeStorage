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
extension ByTypeStorage
{
    func value<T: Storable>(ofType _: T.Type) -> T?
    {
        return data[Key.derived(from: T.self)] as? T
    }
    
    func value<T>(forKey _: T.Type) -> Storable?
    {
        return data[Key.derived(from: T.self)]
    }
    
    //===
    
    func hasValue<T: Storable>(of _: T.Type) -> Bool
    {
        return value(ofType: T.self) != nil
    }
    
    func hasValue<T>(forKey _: T.Type) -> Bool
    {
        return value(forKey: T.self) != nil
    }
}

//===

public
extension Storable
{
    static
    func from(_ storage: ByTypeStorage) -> Self?
    {
        return storage.value(ofType: self)
    }

    //===

    static
    func presented(in storage: ByTypeStorage) -> Bool
    {
        return storage.hasValue(of: self)
    }
}

// MARK: - Mutation metadata

public
extension ByTypeStorage
{
    typealias MutationResult = (storage: ByTypeStorage, diff: MutationDiff)
    
    enum MutationDiff
    {
        case addition(forKey: Any.Type)
        case update(forKey: Any.Type)
        case removal(forKey: Any.Type)
    }
}

// MARK: - SET data

public
extension ByTypeStorage
{
    @discardableResult
    func store<T: Storable>(_ value: T?) -> MutationResult
    {
        let diff: MutationDiff
            
        if
            hasValue(of: T.self)
        {
            diff = .update(forKey: Key.keyType(for: T.self))
        }
        else
        {
            diff = .addition(forKey: Key.keyType(for: T.self))
        }
        
        //---
        
        var storage = self
        
        storage.data[Key.derived(from: T.self)] = value
        
        //---
        
        return (storage, diff)
    }
}

//===

public
extension Storable
{
    @discardableResult
    func store(in storage: inout ByTypeStorage) -> Self
    {
        storage.store(self)
        
        //---
        
        return self
    }
}

// MARK: - REMOVE data

public
extension ByTypeStorage
{
    @discardableResult
    func removeValue<T: Storable>(ofType _: T.Type) -> MutationResult?
    {
        guard
            hasValue(of: T.self)
        else
        {
            return nil
        }
        
        //---
        
        let diff: MutationDiff = .removal(forKey: Key.keyType(for: T.self))
        
        //---
        
        var storage = self
        
        storage.data[Key.derived(from: T.self)] = nil
        
        //---
        
        return (storage, diff)
    }
    
    @discardableResult
    func removeValue<T>(forKey _: T.Type) -> MutationResult?
    {
        guard
            hasValue(forKey: T.self)
        else
        {
            return nil
        }
        
        //---
        
        let diff: MutationDiff = .removal(forKey: Key.keyType(for: T.self))
            
        //---
        
        var storage = self
        
        storage.data[Key.derived(from: T.self)] = nil
        
        //---
        
        return (storage, diff)
    }
}

//===

public
extension Storable
{
    @discardableResult
    func remove(from storage: inout ByTypeStorage) -> Self
    {
        storage.removeValue(ofType: type(of: self))
        
        //---
        
        return self
    }
    
    @discardableResult
    static
    func remove(from storage: inout ByTypeStorage) -> Self.Type
    {
        storage.removeValue(ofType: self)
        
        //---
        
        return self
    }
}
