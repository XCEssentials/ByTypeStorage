/// Marker type for type that can be used as key in the storage.
public
protocol SomeKey
{
    @MainActor
    static
    var bindings: [StorageDispatcher.AccessEventBinding] { get }
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

// MARK: - Public helpers

public
protocol NoBindings {}

public
extension NoBindings
{
    @MainActor
    static
    var bindings: [StorageDispatcher.AccessEventBinding] { [] }
}
