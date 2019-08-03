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
extension ByTypeStorage.Container
{
    func value<T: Storable>(of _: T.Type) -> T?
    {
        return storage.itself.value(ofType: T.self)
    }

    func value<T>(forKey _: T.Type) -> Storable?
    {
        return storage.itself.value(forKey: T.self)
    }

    //===

    func hasValue<T: Storable>(of _: T.Type) -> Bool
    {
        return storage.itself.hasValue(of: T.self)
    }

    func hasValue<T>(forKey _: T.Type) -> Bool
    {
        return storage.itself.hasValue(forKey: T.self)
    }
}

//===

public
extension Storable
{
    static
    func from(_ storage: ByTypeStorage.Container) -> Self?
    {
        return storage.value(of: self)
    }

    //===

    static
    func presented(in storage: ByTypeStorage.Container) -> Bool
    {
        return storage.hasValue(of: self)
    }
}

// MARK: - Mutation helpers

func << (lhs: inout ByTypeStorage.Container.Content,
         rhs: ByTypeStorage.MutationResult?)
{
    rhs.map{ lhs = ($0.storage, $0.diff) }
}

// MARK: - SET data

public
extension ByTypeStorage.Container
{
    func storeValue<T: Storable>(_ value: T?)
    {
        storage << storage.itself.store(value)
    }
}

//===

public
extension Storable
{
    @discardableResult
    func store(in storage: ByTypeStorage.Container) -> Self
    {
        storage.storeValue(self)

        //---

        return self
    }
}

// MARK: - REMOVE data

public
extension ByTypeStorage.Container
{
    func removeValue<T: Storable>(of _: T.Type)
    {
        storage << storage.itself.removeValue(ofType: T.self)
    }

    func removeValue<T>(forKey _: T.Type)
    {
        storage << storage.itself.removeValue(forKey: T.self)
    }
}

//===

public
extension Storable
{
    @discardableResult
    func remove(from storage: ByTypeStorage.Container) -> Self
    {
        storage.removeValue(of: type(of: self))

        //---

        return self
    }

    @discardableResult
    static
    func remove(from storage: ByTypeStorage.Container) -> Self.Type
    {
        storage.removeValue(of: self)

        //---

        return self
    }
}
