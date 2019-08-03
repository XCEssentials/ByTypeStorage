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
    final
    class Container
    {
        public
        init(with storage: ByTypeStorage = ByTypeStorage())
        {
            self.storage = (storage, nil)
        }
        
        //===
        
        public
        typealias Content =
            (itself: ByTypeStorage, recentChange: ByTypeStorage.MutationDiff?)
        
        public internal(set)
        var storage: Content
        {
            didSet
            {
                storage.recentChange
                    .map{ notifyObservers(with: storage.itself, diff: $0) }
            }
        }
        
        //===
        
        /**
         Id helps to avoid dublicates. Only one subscription is allowed per observer.
         */
        var subscriptions: [Subscription.Identifier: Subscription] = [:]
    }
}

//===

public
protocol StorageInitializable: class
{
    init(with storage: ByTypeStorage.Container)
}

//===

public
protocol StorageBindable: class
{
    func bind(with storage: ByTypeStorage.Container) -> Self
}
