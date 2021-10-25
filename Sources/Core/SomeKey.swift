/// Marker type for type that can be used as key in the storage.
public
protocol SomeKey {}

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
