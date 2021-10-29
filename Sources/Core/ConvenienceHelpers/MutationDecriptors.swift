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
extension ByTypeStorage.MutationAttemptOutcome
{
    var key: SomeKey.Type
    {
        switch self
        {
            case .initialization(let key, _),
                    .actualization(let key, _, _),
                    .transition(let key, _, _),
                    .deinitialization(let key, _),
                    .nothingToRemove(let key):
                return key
        }
    }
}

// MARK: - Initialization helpers

public
extension ByTypeStorage.MutationAttemptOutcome
{
    struct InitializationOutcome
    {
        public
        let key: SomeKey.Type
        
        public
        let newValue: SomeStorable
    }
    
    var asInitialization: InitializationOutcome?
    {
        switch self
        {
            case let .initialization(key, newValue):
                
                return .init(
                    key: key,
                    newValue: newValue
                )
                
            default:
                return nil
        }
    }
    
    var isInitialization: Bool
    {
        asInitialization != nil
    }
}

// MARK: - Setting helpers

public
extension ByTypeStorage.MutationAttemptOutcome
{
    /// Operation that results with given key being present in the storage.
    struct SettingOutcome
    {
        public
        let key: SomeKey.Type
        
        public
        let newValue: SomeStorable
    }
    
    /// Operation that results with given key being present in the storage.
    var asSetting: SettingOutcome?
    {
        switch self
        {
            case let .initialization(key, newValue),
                    let .actualization(key, _, newValue),
                    let .transition(key, _, newValue):
                
                return .init(
                    key: key,
                    newValue: newValue
                )
                
            default:
                return nil
        }
    }
    
    /// Operation that results with given key being present in the storage.
    var isSetting: Bool
    {
        asSetting != nil
    }
}

// MARK: - Update helpers

public
extension ByTypeStorage.MutationAttemptOutcome
{
    /// Operation that has both old and new values.
    struct UpdateOutcome
    {
        public
        let key: SomeKey.Type
        
        public
        let oldValue: SomeStorable
        
        public
        let newValue: SomeStorable
    }
    
    /// Operation that has both old and new values.
    var asUpdate: UpdateOutcome?
    {
        switch self
        {
            case let .actualization(key, oldValue, newValue), let .transition(key, oldValue, newValue):
                
                return .init(
                    key: key,
                    oldValue: oldValue,
                    newValue: newValue
                )
                
            default:
                return nil
        }
    }
    
    /// Operation that has both old and new values.
    var isUpdate: Bool
    {
        asUpdate != nil
    }
}

// MARK: - Actualization helpers

public
extension ByTypeStorage.MutationAttemptOutcome
{
    struct ActualizationOutcome
    {
        public
        let key: SomeKey.Type
        
        public
        let oldValue: SomeStorable
        
        public
        let newValue: SomeStorable
    }
    
    var asActualization: ActualizationOutcome?
    {
        switch self
        {
            case let .actualization(key, oldValue, newValue):
                
                return .init(
                    key: key,
                    oldValue: oldValue,
                    newValue: newValue
                )
                
            default:
                return nil
        }
    }
    
    var isActualization: Bool
    {
        asActualization != nil
    }
}

// MARK: - Transition helpers

public
extension ByTypeStorage.MutationAttemptOutcome
{
    struct TransitionOutcome
    {
        public
        let key: SomeKey.Type
        
        public
        let oldValue: SomeStorable
        
        public
        let newValue: SomeStorable
    }
    
    var asTransition: TransitionOutcome?
    {
        switch self
        {
            case let .transition(key, oldValue, newValue):
                
                return .init(
                    key: key,
                    oldValue: oldValue,
                    newValue: newValue
                )
                
            default:
                return nil
        }
    }
    
    var isTransition: Bool
    {
        asTransition != nil
    }
}

// MARK: - Deinitialization helpers

public
extension ByTypeStorage.MutationAttemptOutcome
{
    struct DeinitializationOutcome
    {
        public
        let key: SomeKey.Type
        
        public
        let oldValue: SomeStorable
    }
    
    var asDeinitializationOutcome: DeinitializationOutcome?
    {
        switch self
        {
            case let .deinitialization(key, oldValue):
                
                return .init(
                    key: key,
                    oldValue: oldValue
                )
                
            default:
                return nil
        }
    }
    
    var isDeinitialization: Bool
    {
        asDeinitializationOutcome != nil
    }
}

// MARK: - BlankRemoval helpers

public
extension ByTypeStorage.MutationAttemptOutcome
{
    struct BlankRemovalOutcome
    {
        public
        let key: SomeKey.Type
    }
    
    var asBlankRemovalOutcome: BlankRemovalOutcome?
    {
        switch self
        {
            case let .nothingToRemove(key):
                
                return .init(
                    key: key
                )
                
            default:
                return nil
        }
    }
    
    var isBlankRemoval: Bool
    {
        asBlankRemovalOutcome != nil
    }
}
