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
    private
    var data: [String: SomeStorable] = [:]
    
    public private(set)
    var history: History = []
    
    public private(set)
    var lastHistoryResetId: String = UUID().uuidString
    
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
    
    enum InitializationError: Error
    {
        case keyFoundWithSameValueType(
            key: SomeKey.Type,
            sameTypeValue: SomeStorable
        )
        
        case keyFoundWithAnotherValueType(
            key: SomeKey.Type,
            anotherTypeValue: SomeStorable
        )
    }
    
    enum ActualizationError: Error
    {
        case keyNotFound(
            SomeKey.Type
        )
        
        case keyFoundWithAnotherValueType(
            key: SomeKey.Type,
            anotherTypeValue: SomeStorable
        )
    }
    
    enum TransitionError: Error
    {
        case keyNotFound(
            SomeKey.Type
        )
        
        case keyFoundWithSameValueType(
            key: SomeKey.Type,
            sameTypeValue: SomeStorable
        )
        
        case unexpectedExistingValue(
            key: SomeKey.Type,
            existingValue: SomeStorable
        )
    }
    
    enum DeinitializationError: Error
    {
        case keyNotFound(
            SomeKey.Type
        )
    }
}

// MARK: - GET data

public
extension ByTypeStorage
{
    func fetch(valueForKey keyType: SomeKey.Type) throws -> SomeStorable
    {
        if
            let result = data[keyType.name]
        {
            return result
        }
        else
        {
            throw ReadDataError.keyNotFound(keyType)
        }
    }
    
    func fetch<V: SomeStorableByKey>(valueOfType _: V.Type = V.self) throws -> V
    {
        let someResult = try fetch(valueForKey: V.Key.self)
        
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
}

// MARK: - SET data - SEMANTIC helpers

public
extension ByTypeStorage
{
    mutating
    func initialize<V: SomeStorableByKey>(with newValue: V) throws
    {
        switch data[V.Key.name]
        {
            case .none:
                
                data[V.Key.name] = newValue
                
                //---
                
                logHistoryEvent(
                    outcome: .initialization(
                        key: V.Key.self,
                        newValue: newValue
                    )
                )
                
            //---
                    
            case .some(let existingValue) where type(of: existingValue) == type(of: newValue):
                
                throw InitializationError.keyFoundWithSameValueType(
                    key: V.Key.self,
                    sameTypeValue: existingValue
                )
                
            //---
                
            case .some(let someExistingValue):
                
                throw InitializationError.keyFoundWithAnotherValueType(
                    key: V.Key.self,
                    anotherTypeValue: someExistingValue
                )
        }
    }
    
    mutating
    func actualize<V: SomeStorableByKey>(
        _ valueOfType: V.Type = V.self,
        via mutationHandler: (inout V) throws -> Void
    ) throws {
        
        var state: V = try fetch()
        
        //---
        
        try mutationHandler(&state)
        
        //---
        
        try actualize(with: state)
    }
    
    mutating
    func actualize<V: SomeStorableByKey>(with newValue: V) throws
    {
        switch data[V.Key.name]
        {
            case .some(let oldValue) where type(of: oldValue) == type(of: newValue):
                
                data[V.Key.name] = newValue
                
                logHistoryEvent(
                    outcome: .actualization(
                        key: V.Key.self,
                        oldValue: oldValue,
                        newValue: newValue
                    )
                )
                
            //---
                
            case .some(let someExistingValue): // type(of: someExistingValue) != type(of: newValue)
                
                throw ActualizationError.keyFoundWithAnotherValueType(
                    key: V.Key.self,
                    anotherTypeValue: someExistingValue
                )
                
            //---
             
            case .none:
                
                throw ActualizationError.keyNotFound(
                    V.Key.self
                )
        }
    }
    
    mutating
    func transition<O: SomeStorableByKey, N: SomeStorableByKey>(
        from oldValueInstance: O,
        into newValue: N
    ) throws where O.Key == N.Key {
        
        try transition(from: O.self, into: newValue)
    }
    
    mutating
    func transition<O: SomeStorableByKey, N: SomeStorableByKey>(
        from oldValueType: O.Type,
        into newValue: N
    ) throws where O.Key == N.Key {
        
        switch data[N.Key.name]
        {
            case .some(let oldValue) where oldValue is O:
                
                data[N.Key.name] = newValue
                
                logHistoryEvent(
                    outcome: .transition(
                        key: N.Key.self,
                        oldValue: oldValue,
                        newValue: newValue
                    )
                )
                
            //---
                
            case .some(let existingValue): //type(of: existingValue) != O
                
                throw TransitionError.unexpectedExistingValue(
                    key: N.Key.self,
                    existingValue: existingValue
                )
                
            //---
             
            case .none:
                
                throw TransitionError.keyNotFound(
                    N.Key.self
                )
        }
    }
    
    mutating
    func transition<V: SomeStorableByKey>(
        overrideSame: Bool = false,
        into newValue: V
    ) throws {
        
        switch data[V.Key.name]
        {
            case .some(let oldValue) where (type(of: oldValue) != V.self) || overrideSame:
                
                data[V.Key.name] = newValue
                
                logHistoryEvent(
                    outcome: .transition(
                        key: V.Key.self,
                        oldValue: oldValue,
                        newValue: newValue
                    )
                )
                
            //---
                
            case .some(let existingValue): //type(of: existingValue) == type(of: newValue) && !overrideSame
                
                throw TransitionError.keyFoundWithSameValueType(
                    key: V.Key.self,
                    sameTypeValue: existingValue
                )
                
            //---
             
            case .none:
                
                throw TransitionError.keyNotFound(
                    V.Key.self
                )
        }
    }
    
    mutating
    func deinitialize<K: SomeKey>(_: K.Type) throws
    {
        switch data[K.name]
        {
            case .some(let oldValue):
                
                data.removeValue(forKey: K.name) // NOTE: this is SDK method on Dictionary!
                
                //---
                
                logHistoryEvent(
                    outcome: .deinitialization(
                        key: K.self,
                        oldValue: oldValue
                    )
                )
                
            //---
                    
            case .none:
                
                throw DeinitializationError.keyNotFound(
                    K.self
                )
        }
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
        
        switch (data[V.Key.name], value)
        {
            case (.none, .some(let newValue)):
                
                data[V.Key.name] = newValue
                
                //---
                
                outcome = .initialization(key: V.Key.self, newValue: newValue)
                
            //---
                
            case (.some(let oldValue), .some(let newValue)):
                
                data[V.Key.name] = newValue
                
                //---
                
                if
                    type(of: oldValue) == type(of: newValue)
                {
                    outcome = .actualization(key: V.Key.self, oldValue: oldValue, newValue: newValue)
                }
                else
                {
                    outcome = .transition(key: V.Key.self, oldValue: oldValue, newValue: newValue)
                }
                
            //---
               
            case (.some(let oldValue), .none):
                
                data.removeValue(forKey: V.Key.name) // NOTE: this is SDK method on Dictionary!
                
                //---
                
                outcome = .deinitialization(key: V.Key.self, oldValue: oldValue)
                
            case (.none, .none):
                
                outcome = .nothingToRemove(key: V.Key.self)
        }
        
        //---
              
        logHistoryEvent(
            outcome: outcome
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
        
        switch data[K.name]
        {
            case .some(let oldValue):
                
                data.removeValue(forKey: K.name)
                
                //---
                
                outcome = .deinitialization(key: K.self, oldValue: oldValue)
                
            case .none:
                
                outcome = .nothingToRemove(key: K.self)
        }
        
        //---
              
        logHistoryEvent(
            outcome: outcome
        )
        
        //---
        
        return outcome
    }
}

// MARK: - History management

//internal
extension ByTypeStorage
{
    mutating
    func logHistoryEvent(
        outcome: MutationAttemptOutcome
    ) {
        
        history.append(
            .init(outcome: outcome)
        )
    }
    
    /// Clear the history and return it's copy as result.
    mutating
    func resetHistory() -> History
    {
        let result = history
        history.removeAll()
        lastHistoryResetId = UUID().uuidString
        
        //---
        
        return result
    }
}
