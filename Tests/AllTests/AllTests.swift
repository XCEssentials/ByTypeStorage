import XCTest

@testable
import XCEByTypeStorage

//---

struct One: Storable { }

struct Two: Storable
{
    static
    var key: ByTypeStorage.Key
    {
        return "123"
    }
}

struct Three: Storable
{
    static
    var key: ByTypeStorage.Key
    {
        return "123"
    }
}

struct Four: Storable
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
