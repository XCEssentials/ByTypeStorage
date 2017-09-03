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

/**
 Data container that allows to store exactly one instance of any given type.
 
 It's Dictionary-like (and Dictionary-based) key-value storage where full name of the type (including module name, including all parent types for nested types) converted to a string is used as key for storing instance of this type. This feature allows to avoid the need of hard-coded string-based keys, improves type-safety, simplifies usage. Obviously, this data container is supposed to be used with custom data types that have some domain-specific semantics in their names.
 */
public
final
class ByTypeStorage
{
    public
    init() {}
    
    fileprivate
    var data = [Key: Storable]()
    
    /**
     Id helps to avoid dublicates. Only one subscription is allowed per observer.
     */
    fileprivate
    var subscriptions: [Subscription.Identifier: Subscription] = [:]
}

// MARK: - Protocols

public
protocol Storable { }

//===

public
protocol StorageObserver: class
{
    func update(with change: ByTypeStorage.Change, in storage: ByTypeStorage)
}

//===

public
protocol StorageInitializable
{
    init(with storage: ByTypeStorage)
}

//===

public
protocol StorageBindable
{
    func bind(with storage: ByTypeStorage) -> Self
}

// MARK: - Subscription

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
        fileprivate
        init(for observer: StorageObserver)
        {
            self.identifier = Identifier(observer)
            self.observer = observer
        }
        
        fileprivate
        typealias Identifier = ObjectIdentifier
        
        fileprivate
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
        fileprivate
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

    fileprivate
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

// MARK: - Key generation

public
extension ByTypeStorage
{
    typealias Key = String
    
    fileprivate
    static
    func key(for type: Storable.Type) -> Key
    {
        return Key(reflecting: type)
    }
}

// MARK: - GET data

public
extension ByTypeStorage
{
    func extract<T: Storable>(_: T.Type) -> T?
    {
        return data[ByTypeStorage.key(for: T.self)] as? T
    }
    
    //===

    func has<T: Storable>(_: T.Type) -> Bool
    {
        return data[ByTypeStorage.key(for: T.self)] != nil
    }
}

//===

public
extension Storable
{
    static
    func from(_ storage: ByTypeStorage) -> Self?
    {
        return storage.extract(self)
    }
    
    //===

    static
    func presented(in storage: ByTypeStorage) -> Bool
    {
        return storage.has(self)
    }
}

// MARK: - SET data

public
extension ByTypeStorage
{
    func merge<T: Storable>(_ value: T?)
    {
        let change: Change = has(T.self) ? .update(ofType: T.self) : .addition(ofType: T.self)
        data[ByTypeStorage.key(for: T.self)] = value
        notifyObservers(with: change)
    }
}

//===

public
extension Storable
{
    @discardableResult
    func store(in storage: ByTypeStorage) -> Self
    {
        storage.merge(self)
        
        //---

        return self
    }
}

// MARK: - REMOVE data

public
extension ByTypeStorage
{
    func remove<T: Storable>(_: T.Type)
    {
        let change = has(T.self) ? Change.removal(ofType: T.self) : nil
        data[ByTypeStorage.key(for: T.self)] = nil
        change.map(notifyObservers)
    }
}

//===

public
extension Storable
{
    static
    func remove(from storage: ByTypeStorage)
    {
        return storage.remove(self)
    }
}

// MARK: - Custom operators

infix operator /<

// MARK: - GET operators

public
func << <T: Storable>(_: T.Type, storage: ByTypeStorage) -> T?
{
    return storage.extract(T.self)
}

//===

public
func << <T: Storable>(target: inout T?, pair: (T.Type, ByTypeStorage))
{
    target = pair.1.extract(T.self)
}

//===

public
func >> <T: Storable>(storage: ByTypeStorage, _: T.Type) -> T?
{
    return storage.extract(T.self)
}

// MARK: - SET operators

public
func << <T: Storable>(storage: ByTypeStorage, value: T?)
{
    storage.merge(value)
}

// MARK: - REMOVE operators

public
func /< <T: Storable>(storage: ByTypeStorage, _: T.Type)
{
    storage.remove(T.self)
}
