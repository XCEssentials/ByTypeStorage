import XCTest

@testable
import XCEByTypeStorage

//---

struct One: SomeStorable { }

struct Two: SomeStorable
{
    static
    var key: ByTypeStorage.Key
    {
        return "123"
    }
}

struct Three: SomeStorable
{
    static
    var key: ByTypeStorage.Key
    {
        return "123"
    }
}

struct Four: SomeStorable
{
    static
    var key: ByTypeStorage.Key
    {
        return "456"
    }
}

//---

class AllTests: XCTestCase
{
    func testKeyConversion()
    {
        XCTAssert(
            One.key.contains("One")
        )
        
        XCTAssert(
            Two.key.contains("123")
        )
        
        XCTAssert(
            Three.key.contains("123")
        )
        
        XCTAssert(
            Four.key.contains("456")
        )
    }
    
    //---
    
    var storage: ByTypeStorage!
    
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
