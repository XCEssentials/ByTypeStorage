import XCTest

@testable
import XCEByTypeStorage

//---

struct One: SomeSelfStorable, SomeKey
{
    var val: Int
}

enum TheKey: SomeSelfStorable, SomeKey {}

struct Two: SomeStorableByKey
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
            One.Key.key.contains("One")
        )
        
        XCTAssert(
            Two.Key.key.contains("TheKey")
        )
        
        XCTAssert(
            Three.Key.key.contains("TheKey")
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
