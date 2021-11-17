import XCTest

@testable
import XCEByTypeStorage

//---

struct One: SomeStorable, SomeSelfKey, NoBindings
{
    var val: Int
}

enum TheKey: SomeKey, NoBindings {}

struct Two: SomeStorable
{
    typealias Key = TheKey
}

struct Three: SomeStorable
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
        try! storage.store(value)
        
        XCTAssertEqual(
            storage[One.self]?.val,
            .some(5)
        )
    }
}
