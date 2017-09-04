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
