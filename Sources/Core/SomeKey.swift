/// Marker type for type that can be used as key in the storage.
public
protocol SomeKey
{
    @MainActor
    static
    var bindings: [StorageDispatcher.AccessEventBinding] { get }
}

public
extension SomeKey
{
    /// `ByTypeStorage` will use this as actual key.
    static
    var name: String
    {
        .init(reflecting: Self.self)
    }
    
    @MainActor
    static
    func scenario(
        _ description: String = ""
    ) -> StorageDispatcher.AccessEventBinding.WhenContext {
        
        .init(source: .keyType(self), description: description)
    }
}

//---

public
protocol NoBindings {}

public
extension NoBindings
{
    @MainActor
    static
    var bindings: [StorageDispatcher.AccessEventBinding] { [] }
}
