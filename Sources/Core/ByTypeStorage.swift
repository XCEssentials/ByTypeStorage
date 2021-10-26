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

//---

public
struct ByTypeStorage
{
    //internal
    private
    var data: [String: SomeStorable] = [:]
    
    //internal
    var history: History = []
    
    //---
    
    public
    init() {}
}

// MARK: - Nested types

public
extension ByTypeStorage
{
    enum ReadDataError: Error
    {
        case keyNotFound(
            SomeKey.Type
        )
        
        case valueTypeMismatch(
            key: SomeKey.Type,
            expected: SomeStorable.Type,
            actual: SomeStorable
        )
    }
    
    typealias History = [(timestamp: Date, outcome: MutationAttemptOutcome)]
    
    enum MutationAttemptOutcome
    {
        case addition(key: SomeKey.Type, newValue: SomeStorable)
        case update(key: SomeKey.Type, oldValue: SomeStorable, newValue: SomeStorable)
        case removal(key: SomeKey.Type, oldValue: SomeStorable)
        
        /// No removal operation has been performed, because no such key has been found.
        case nothingToRemove(key: SomeKey.Type)
    }
}

// MARK: - GET data - SomeKey

public
extension ByTypeStorage
{
    subscript<K: SomeKey>(_ keyType: K.Type) -> SomeStorable?
    {
        try? fetch(valueForKey: K.self)
    }
    
    func fetch<K: SomeKey>(valueForKey _: K.Type) throws -> SomeStorable
    {
        if
            let result = data[K.name]
        {
            return result
        }
        else
        {
            throw ReadDataError.keyNotFound(K.self)
        }
    }
    
    func hasValue<K: SomeKey>(withKey keyType: K.Type) -> Bool
    {
        self[K.self] != nil
    }
}

// MARK: - GET data - SomeStorable

public
extension ByTypeStorage
{
    func hasValue<V: SomeStorable>(ofType _: V.Type) -> Bool
    {
        data.values.first { $0 is V } != nil
    }
}

// MARK: - GET data - SomeStorableByKey

public
extension ByTypeStorage
{
    subscript<V: SomeStorableByKey>(_ valueType: V.Type) -> V?
    {
        try? fetch(valueOfType: V.self)
    }
    
    func fetch<V: SomeStorableByKey>(valueOfType _: V.Type) throws -> V
    {
        guard
            let someResult = data[V.key]
        else
        {
            throw ReadDataError.keyNotFound(V.Key.self)
        }
        
        //---
        
        if
            let result = someResult as? V
        {
            return result
        }
        else
        {
            throw ReadDataError.valueTypeMismatch(
                key: V.Key.self,
                expected: V.self,
                actual: someResult
            )
        }
    }
    
    func hasValue<V: SomeStorableByKey>(ofType valueType: V.Type) -> Bool
    {
        self[V.self] != nil
    }
}

// MARK: - SET data

public
extension ByTypeStorage
{
    @discardableResult
    mutating
    func store<V: SomeStorableByKey>(_ value: V?) -> MutationAttemptOutcome
    {
        let outcome: MutationAttemptOutcome
        
        //---
        
        switch (self[V.Key.self], value)
        {
            case (.none, .some(let newValue)):
                
                data[V.Key.name] = newValue
                
                //---
                
                outcome = .addition(key: V.Key.self, newValue: newValue)
                
            //---
                
            case (.some(let oldValue), .some(let newValue)):
                
                data[V.Key.name] = newValue
                
                //---
                
                outcome = .update(key: V.Key.self, oldValue: oldValue, newValue: newValue)
                
            //---
               
            case (.some(let oldValue), .none):
                
                data.removeValue(forKey: V.Key.name) // NOTE: this is SDK method on Dictionary!
                
                //---
                
                outcome = .removal(key: V.Key.self, oldValue: oldValue)
                
            case (.none, .none):
                
                outcome = .nothingToRemove(key: V.Key.self)
        }
        
        //---
              
        history.append(
            (Date(), outcome)
        )
        
        //---
        
        return outcome
    }
}

// MARK: - REMOVE data

public
extension ByTypeStorage
{
    @discardableResult
    mutating
    func removeValue<K: SomeKey>(forKey keyType: K.Type) -> MutationAttemptOutcome
    {
        let outcome: MutationAttemptOutcome
        
        //---
        
        switch self[K.self]
        {
            case .some(let oldValue):
                
                data.removeValue(forKey: K.name)
                
                //---
                
                outcome = .removal(key: K.self, oldValue: oldValue)
                
            case .none:
                
                outcome = .nothingToRemove(key: K.self)
        }
        
        //---
              
        history.append(
            (Date(), outcome)
        )
        
        //---
        
        return outcome
    }
}

// MARK: - History management

//internal
extension ByTypeStorage
{
    /// Clear the history and return it's copy as result.
    mutating
    func resetHistory() -> History
    {
        let result = history
        history.removeAll()
        
        //---
        
        return result
    }
}
