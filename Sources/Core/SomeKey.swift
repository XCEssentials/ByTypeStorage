/// Marker type for type that can be used as key in the storage.
public
protocol SomeKey
{
    @MainActor
    static
    var bindings: [StorageDispatcher.AccessEventBinding] { get }
}

// MARK: - Helpers

public
protocol NoBindings {}

public
extension NoBindings
{
    @MainActor
    static
    var bindings: [StorageDispatcher.AccessEventBinding] { [] }
}

// MARK: - Internal helpers

//internal
extension SomeKey
{
    /// `ByTypeStorage` will use this as actual key.
    static
    var name: String
    {
        .init(reflecting: Self.self)
    }
}
