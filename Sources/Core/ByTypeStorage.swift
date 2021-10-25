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
struct ByTypeStorage
{
    public
    init() {}
    
    //---
    
    //internal
    var data = [String: SomeStorable]()
}

// MARK: - Nested types

public
extension ByTypeStorage
{
    enum Mutation
    {
        case addition(key: SomeKey.Type, newValue: SomeStorable)
        case update(key: SomeKey.Type, oldValue: SomeStorable, newValue: SomeStorable)
        case removal(key: SomeKey.Type, oldValue: SomeStorable)
        
        /// No removal operation has been performed, because no such key has been found.
        case nothingToRemove(key: SomeKey.Type)
    }
}

// MARK: - GET data

public
extension ByTypeStorage
{
    subscript<V: SomeStorableByKey>(_ valueType: V.Type) -> V?
    {
        data[V.key] as? V
    }
    
    subscript<K: SomeKey>(_ keyType: K.Type) -> SomeStorable?
    {
        data[K.name]
    }
    
    //---
    
    func hasValue<V: SomeStorableByKey>(ofType valueType: V.Type) -> Bool
    {
        self[V.self] != nil
    }
    
    func hasValue<K: SomeKey>(withKey keyType: K.Type) -> Bool
    {
        self[K.self] != nil
    }
}

// MARK: - SET data

public
extension ByTypeStorage
{
    @discardableResult
    mutating
    func store<V: SomeStorableByKey>(_ value: V?) -> Mutation
    {
        switch (self[V.Key.self], value)
        {
            case (.none, .some(let newValue)):
                
                data[V.Key.name] = newValue
                
                //---
                
                return .addition(key: V.Key.self, newValue: newValue)
                
            //---
                
            case (.some(let oldValue), .some(let newValue)):
                
                data[V.Key.name] = newValue
                
                //---
                
                return .update(key: V.Key.self, oldValue: oldValue, newValue: newValue)
                
            //---
               
            case (.some(let oldValue), .none):
                
                data.removeValue(forKey: V.Key.name) // NOTE: this is SDK method on Dictionary!
                
                //---
                
                return .removal(key: V.Key.self, oldValue: oldValue)
                
            case (.none, .none):
                
                return .nothingToRemove(key: V.Key.self)
        }
    }
}

// MARK: - REMOVE data

public
extension ByTypeStorage
{
    @discardableResult
    mutating
    func removeValue<K: SomeKey>(forKey keyType: K.Type) -> Mutation
    {
        switch self[K.self]
        {
            case .some(let oldValue):
                
                data.removeValue(forKey: K.name)
                
                //---
                
                return .removal(key: K.self, oldValue: oldValue)
                
            case .none:
                
                return .nothingToRemove(key: K.self)
        }
    }
}
