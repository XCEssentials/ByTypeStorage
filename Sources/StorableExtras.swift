// import ByTypeStorage
// import Require

// MARK: - Protocols

public
protocol AutoInitializable
{
    init()
}

// MARK: - Actions

public
typealias Action = (ByTypeStorage) throws -> Void

//===

public
extension ByTypeStorage
{
    func process(_ action: Action) rethrows
    {
        try action(self)
    }
}

//===

public
func << (storage: ByTypeStorage, action: Action) rethrows
{
    try storage.process(action)
}

//===

public
func << (storage: ByTypeStorage, actionGetter: () -> Action) throws
{
    try storage.process(actionGetter())
}

// MARK: - Helpers

public
extension Storable
{
    @discardableResult
    static
    func initialize(
        in storage: ByTypeStorage,
        with getter: @escaping () -> Self
        ) throws -> Self
    {
        try REQ("\(self) is NOT presented yet").isFalse(storage.has(self))
        
        //---
        
        let value = getter()
        storage << value
        
        //---
        
        return value
    }
    
    //===
    
    @discardableResult
    static
    func initialize(
        in storage: ByTypeStorage,
        with value: Self
        ) throws -> Self
    {
        try REQ("\(self) is NOT presented yet").isFalse(storage.has(self))
        
        //---
        
        storage << value
        
        //---
        
        return value
    }
    
    //===
    
    @discardableResult
    static
    func prepareForUpdate(
        in storage: ByTypeStorage
        ) throws -> Self
    {
        return try REQ("\(self) IS presented").isNotNil(storage >> self)
    }
    
    //===
    
    static
    func deinitialize(
        in storage: ByTypeStorage
        ) throws
    {
        try REQ("\(self) IS presented").isTrue(storage.has(self))
        
        //---
        
        storage /< self
    }
}

// MARK: - Helpers for AutoInitializable

public
extension Storable where Self: AutoInitializable
{
    @discardableResult
    static
    func initialize(
        in storage: ByTypeStorage
        ) throws -> Self
    {
        try REQ("\(self) is NOT presented yet").isFalse(storage.has(self))
        
        //---
        
        let value = Self.init()
        storage << value
        
        //---
        
        return value
    }
}
