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

infix operator /<

// MARK: - GET operators

/// Fetch value of type `T` from `storage`, if present.
public
func << <T: SomeStorableByKey>(_: T.Type, storage: ByTypeStorage) -> T?
{
    storage[T.self]
}

/// Fetch value of type `T` from `storage`, if present.
@MainActor
public
func << <T: SomeStorableByKey>(_: T.Type, storage: StorageDispatcher) -> T?
{
    storage[T.self]
}

//---

/// Fetch value of type `T` from `storage`, if present.
public
func >> <T: SomeStorableByKey>(storage: ByTypeStorage, _: T.Type) -> T?
{
    storage[T.self]
}

/// Fetch value of type `T` from `storage`, if present.
@MainActor
public
func >> <T: SomeStorableByKey>(storage: StorageDispatcher, _: T.Type) -> T?
{
    storage[T.self]
}

// MARK: - SET operators

/// Store `value` in `storage`.
@discardableResult
public
func << <T: SomeStorableByKey>(storage: inout ByTypeStorage, value: T?) -> ByTypeStorage.Mutation
{
    storage.store(value)
}

/// Store `value` in `storage`.
@MainActor
@discardableResult
public
func << <T: SomeStorableByKey>(storage: StorageDispatcher, value: T?) -> [ByTypeStorage.Mutation]
{
    storage.store(value)
}

/// Store `value` in `storage`.
@discardableResult
public
func >> <T: SomeStorableByKey>(value: T?, storage: inout ByTypeStorage) -> ByTypeStorage.Mutation
{
    storage.store(value)
}

/// Store `value` in `storage`.
@MainActor
@discardableResult
public
func >> <T: SomeStorableByKey>(value: T?, storage: StorageDispatcher) -> [ByTypeStorage.Mutation]
{
    storage.store(value)
}

/// Process action request in `storage`.
@MainActor
@discardableResult
public
func << (storage: StorageDispatcher, request: ActionRequest) -> [ByTypeStorage.Mutation]
{
    storage.process(request: request)
}

/// Process action request in `storage`.
@MainActor
@discardableResult
public
func << (storage: StorageDispatcher, request: ActionRequestThrowing) throws -> [ByTypeStorage.Mutation]
{
    try storage.process(request: request)
}

/// Process multiple action requests in `storage`.
@MainActor
@discardableResult
public
func << (storage: StorageDispatcher, requests: [SomeActionRequest]) throws -> [ByTypeStorage.Mutation]
{
    try storage.process(requests: requests)
}

// MARK: - REMOVE operators

/// Remove value of type `T` from `storage`.
@discardableResult
public
func /< <K: SomeKey>(storage: inout ByTypeStorage, _: K.Type) -> ByTypeStorage.Mutation
{
    storage.removeValue(forKey: K.self)
}

/// Remove value of type `T` from `storage`.
@MainActor
@discardableResult
public
func /< <K: SomeKey>(storage: StorageDispatcher, _: K.Type) -> [ByTypeStorage.Mutation]
{
    storage.removeValue(forKey: K.self)
}
