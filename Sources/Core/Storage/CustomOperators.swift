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

public
func << <T: Storable>(_: T.Type, storage: ByTypeStorage) -> T?
{
    return storage.value(ofType: T.self)
}

//---

public
func << <T: Storable>(target: inout T?, pair: (T.Type, ByTypeStorage))
{
    target = pair.1.value(ofType: T.self)
}

//---

public
func >> <T: Storable>(storage: ByTypeStorage, _: T.Type) -> T?
{
    return storage.value(ofType: T.self)
}

// MARK: - SET operators

public
func << <T: Storable>(storage: inout ByTypeStorage, value: T?)
{
    storage.store(value)
}

public
func >> <T: Storable>(value: T?, storage: inout ByTypeStorage)
{
    storage.store(value)
}

// MARK: - REMOVE operators

public
func /< <T: Storable>(storage: inout ByTypeStorage, _: T.Type)
{
    storage.removeValue(ofType: T.self)
}
