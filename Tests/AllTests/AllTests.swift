import XCTest

@testable
import XCEByTypeStorage

//---

struct One: SomeStorableByKey, SomeSelfKey, NoBindings
{
    var val: Int
}

enum TheKey: SomeKey
{
    @MainActor
    static
    var bindings: [StorageDispatcher.AccessEventBinding] {
        
        [
            .init(
                "Print any initialized key",
                when: {
                    
                    $0
                },
                then: { _, input in
                    
                    print("INITIALIZED: \(input)")
                })
        ]
    }
}

struct Two: SomeStorableByKey
{
    typealias Key = TheKey
}

struct Three: SomeStorableByKey
{
    typealias Key = TheKey
}

//---

class AllTests: XCTestCase
{
    var storage: ByTypeStorage!
}

//---

extension AllTests
{
    override
    func setUp()
    {
        super.setUp()
        
        //---
        
        storage = ByTypeStorage()
    }
    
    override
    func tearDown()
    {
        storage = nil
        
        //---
        
        super.tearDown()
    }
}

//---

extension AllTests
{
    func test_keyConversion()
    {
        XCTAssert(
            One.Key.name.contains("One")
        )
        
        XCTAssert(
            Two.Key.name.contains("TheKey")
        )
        
        XCTAssert(
            Three.Key.name.contains("TheKey")
        )
    }
    
    func test_storingValue()
    {
        let value = One(val: 5)
        storage.store(value)
        
        XCTAssertEqual(
            storage[One.self]?.val,
            .some(5)
        )
    }
}
