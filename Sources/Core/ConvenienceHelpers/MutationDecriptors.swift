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

// MARK: - SomeMutationDecriptor

public
protocol SomeMutationDecriptor
{
    init?(
        from mutationOutcome: ByTypeStorage.MutationAttemptOutcome
    )
}

// MARK: - Initialization

public
struct InitializationInto<New: SomeStorableByKey>: SomeMutationDecriptor
{
    public
    let newValue: New
    
    public
    init?(
        from mutationOutcome: ByTypeStorage.MutationAttemptOutcome
    ) {
        
        guard
            let newValue = mutationOutcome.asInitialization?.newValue as? New
        else
        {
            return nil
        }
        
        //---
        
        self.newValue = newValue
    }
}

// MARK: - Setting

/// Operation that results with given key being present in the storage.
public
struct SettingInto<New: SomeStorableByKey>: SomeMutationDecriptor
{
    public
    let newValue: New
    
    public
    init?(
        from mutationOutcome: ByTypeStorage.MutationAttemptOutcome
    ) {
        
        guard
            let newValue = mutationOutcome.asSetting?.newValue as? New
        else
        {
            return nil
        }
        
        //---
        
        self.newValue = newValue
    }
}

// MARK: - Actualization

/// Operation that has both old and new values.
public
struct ActualizationOf<V: SomeStorableByKey>: SomeMutationDecriptor
{
    public
    let oldValue: V
    
    public
    let newValue: V
    
    public
    init?(
        from mutationOutcome: ByTypeStorage.MutationAttemptOutcome
    ) {
        
        guard
            let oldValue = mutationOutcome.asActualization?.oldValue as? V,
            let newValue = mutationOutcome.asActualization?.newValue as? V
        else
        {
            return nil
        }
        
        //---
        
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

// MARK: - Transition

public
struct TransitionFrom<Old: SomeStorableByKey>: SomeMutationDecriptor
{
    public
    let oldValue: Old
    
    public
    let newValue: SomeStorable
    
    public
    init?(
        from mutationOutcome: ByTypeStorage.MutationAttemptOutcome
    ) {
        
        guard
            let oldValue = mutationOutcome.asTransition?.oldValue as? Old,
            let newValue = mutationOutcome.asTransition?.newValue
        else
        {
            return nil
        }
        
        //---
        
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

public
struct TransitionBetween<Old: SomeStorableByKey, New: SomeStorableByKey>: SomeMutationDecriptor
{
    public
    let oldValue: Old
    
    public
    let newValue: New
    
    public
    init?(
        from mutationOutcome: ByTypeStorage.MutationAttemptOutcome
    ) {
        
        guard
            let oldValue = mutationOutcome.asTransition?.oldValue as? Old,
            let newValue = mutationOutcome.asTransition?.newValue as? New
        else
        {
            return nil
        }
        
        //---
        
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

public
struct TransitionInto<New: SomeStorableByKey>: SomeMutationDecriptor
{
    public
    let oldValue: SomeStorable
    
    public
    let newValue: New
    
    public
    init?(
        from mutationOutcome: ByTypeStorage.MutationAttemptOutcome
    ) {
        
        guard
            let oldValue = mutationOutcome.asTransition?.oldValue,
            let newValue = mutationOutcome.asTransition?.newValue as? New
        else
        {
            return nil
        }
        
        //---
        
        self.oldValue = oldValue
        self.newValue = newValue
    }
}

// MARK: - Deinitialization

public
struct DeinitializationFrom<Old: SomeStorableByKey>
{
    public
    let oldValue: Old
    
    public
    init?(
        from mutationOutcome: ByTypeStorage.MutationAttemptOutcome
    ) {
        
        guard
            let oldValue = mutationOutcome.asDeinitialization?.oldValue as? Old
        else
        {
            return nil
        }
        
        //---
        
        self.oldValue = oldValue
    }
}
