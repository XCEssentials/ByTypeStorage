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
    
    public
    typealias Key = String
    
    var data = [Key: Storable]()
}

// MARK: - Nested types

public
extension ByTypeStorage
{
    enum Mutation
    {
        case addition(key: Storable.Type, newValue: Any)
        case update(key: Storable.Type, oldValue: Any, newValue: Any)
        case removal(key: Storable.Type, oldValue: Any)
        
        /// No removal operation has been performed, because no such key has been found.
        case nothingToRemove(key: Storable.Type)
    }
}

// MARK: - GET data

public
extension ByTypeStorage
{
    subscript<T: Storable>(_ keyType: T.Type) -> T?
    {
        data[T.key] as? T
    }
    
    //---
    
    func hasValue<T: Storable>(_: T.Type) -> Bool
    {
        self[T.self] != nil
    }
}

// MARK: - SET data

public
extension ByTypeStorage
{
    @discardableResult
    mutating
    func store<T: Storable>(_ value: T?) -> Mutation
    {
        switch (self[T.self], value)
        {
            case (.none, .some(let newValue)):
                
                data[T.key] = newValue
                
                //---
                
                return .addition(key: T.self, newValue: newValue)
                
            //---
                
            case (.some(let oldValue), .some(let newValue)):
                
                data[T.key] = newValue
                
                //---
                
                return .update(key: T.self, oldValue: oldValue, newValue: newValue)
                
            //---
               
            case (.some(let oldValue), .none):
                
                data.removeValue(forKey: T.key)
                
                //---
                
                return .removal(key: T.self, oldValue: oldValue)
                
            case (.none, .none):
                
                return .nothingToRemove(key: T.self)
        }
    }
}

// MARK: - REMOVE data

public
extension ByTypeStorage
{
    @discardableResult
    mutating
    func removeValue<T: Storable>(ofType _: T.Type) -> Mutation
    {
        store(T?.none)
    }
}
