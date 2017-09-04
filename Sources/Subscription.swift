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
extension ByTypeStorage
{
    enum Change
    {
        case addition(ofType: Storable.Type)
        case update(ofType: Storable.Type)
        case removal(ofType: Storable.Type)
    }
    
    final
    class Subscription
    {
        init(for observer: StorageObserver)
        {
            self.identifier = Identifier(observer)
            self.observer = observer
        }
        
        typealias Identifier = ObjectIdentifier
        
        let identifier: ObjectIdentifier
        
        public private(set)
        weak
        var observer: StorageObserver?
        
        public
        func cancel()
        {
            observer = nil
        }
        
        /**
         Returns value that indicates whatever this subscription should be preserved or not.
         */
        func notifyAndKeep(with change: Change, in storage: ByTypeStorage) -> Bool
        {
            if
                let observer = observer
            {
                observer.update(with: change, in: storage)
                
                return true
            }
            else
            {
                return false
            }
        }
    }
}

// MARK: - Subscriptions management

extension ByTypeStorage
{
    @discardableResult
    public
    func subscribe(_ observer: StorageObserver) -> Subscription
    {
        let result = Subscription(for: observer)
        subscriptions[result.identifier] = result
        
        return result
    }
    
    //===
    
    func notifyObservers(with change: Change)
    {
        // in one pass, notify all valid subscriptions and
        // then remove subscriptions that are no longer needed
        subscriptions
            .filter { !$0.value.notifyAndKeep(with: change, in: self) }
            .map { $0.key }
            .forEach { subscriptions[$0] = nil }
    }
}
