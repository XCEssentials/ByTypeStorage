import XCTest

@testable
import XCEByTypeStorage

//---

protocol CustomKeyed: Storable
{
    associatedtype TheKey
}

extension CustomKeyed
{
    static
    var key: Any.Type
    {
        return TheKey.self
    }
}

//---

struct One: Storable { }

struct Two: CustomKeyed
{
    typealias TheKey = Int
}

struct Three: CustomKeyed
{
    typealias TheKey = Int
}

struct Four: CustomKeyed
{
    typealias TheKey = Float
}

struct Five
{ }

//---

class Main: XCTestCase
{
    func testKeyConversion()
    {
        XCTAssert(
            ByTypeStorage.Key.derived(from: One.self).contains("One")
        )
        
        XCTAssert(
            ByTypeStorage.Key.derived(from: Two.self).contains("Int")
        )
        
        XCTAssert(
            ByTypeStorage.Key.derived(from: Three.self).contains("Int")
        )
        
        XCTAssert(
            ByTypeStorage.Key.derived(from: Four.self).contains("Float")
        )
        
        XCTAssert(
            ByTypeStorage.Key.derived(from: Five.self).contains("Five")
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
