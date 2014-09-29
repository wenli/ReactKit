//
//  KVOTests.swift
//  ReactKitTests
//
//  Created by Yasuhiro Inami on 2014/09/11.
//  Copyright (c) 2014年 Yasuhiro Inami. All rights reserved.
//

import ReactKit
import XCTest

class KVOTests: _TestCase
{
    func testKVO()
    {
        let expect = self.expectationWithDescription(__FUNCTION__)
        
        let obj1 = MyObject()
        let obj2 = MyObject()
        
        let signal = KVO.signal(obj1, "value")   // = obj1.signal(keyPath: "value")
        weak var weakSignal = signal
        
        // REACT: obj1.value ~> obj2.value
        (obj2, "value") <~ signal
        
        // REACT: obj1.value ~> println
        ^{ println("[REACT] new value = \($0)") } <~ signal
        
        println("*** Start ***")
        
        XCTAssertEqual(obj1.value, "initial")
        XCTAssertEqual(obj2.value, "initial")
        
        self.perform {
            
            XCTAssertNotNil(weakSignal)
            
            obj1.value = "hoge"
            
            XCTAssertEqual(obj1.value, "hoge")
            XCTAssertEqual(obj2.value, "hoge")
            
            weakSignal?.cancel()
            
            obj1.value = "fuga"
            
            XCTAssertEqual(obj1.value, "fuga")
            XCTAssertEqual(obj2.value, "hoge", "obj2.value should not be updated because signal is already cancelled.")
            
            expect.fulfill()
            
        }
        
        self.wait()
    }
    
    /// e.g. (obj2, "value") <~ (obj1, "value")
    func testKVO_shortLivingSyntax()
    {
        let expect = self.expectationWithDescription(__FUNCTION__)
        
        let obj1 = MyObject()
        let obj2 = MyObject()
        
        // REACT: obj1.value ~> obj2.value, until the end of runloop (short-living syntax)
        (obj2, "value") <~ (obj1, "value")
        
        println("*** Start ***")
        
        XCTAssertEqual(obj1.value, "initial")
        XCTAssertEqual(obj2.value, "initial")
        
        self.perform {
            
            // comment-out: no weakSignal in this test
            // XCTAssertNotNil(weakSignal)
            
            obj1.value = "hoge"
            
            XCTAssertEqual(obj1.value, "hoge")
            
            if self.isAsync {
                XCTAssertEqual(obj2.value, "initial", "obj2.value should not be updated because signal is already deinited.")
            }
            else {
                XCTAssertEqual(obj2.value, "hoge", "obj2.value should be updated.")
            }
            
            expect.fulfill()
            
        }
        
        // NOTE: (obj1, "value") signal is still retained at this point, thanks to dispatch_queue
        
        self.wait()
    }
    
    func testKVO_filter()
    {
        let expect = self.expectationWithDescription(__FUNCTION__)
        
        let obj1 = MyObject()
        let obj2 = MyObject()
        
        let signal = KVO.signal(obj1, "value").filter { (value: AnyObject?) -> Bool in
            return value as String == "fuga"
        }
        
        // REACT
        (obj2, "value") <~ signal
        
        // REACT
        ^{ println("[REACT] new value = \($0)") } <~ signal
        
        println("*** Start ***")
        
        XCTAssertEqual(obj1.value, "initial")
        XCTAssertEqual(obj2.value, "initial")
        
        self.perform {
            
            obj1.value = "hoge"
            
            XCTAssertEqual(obj1.value, "hoge")
            XCTAssertEqual(obj2.value, "initial", "obj2.value should not be updated because signal is not sent via filter().")
            
            obj1.value = "fuga"
            
            XCTAssertEqual(obj1.value, "fuga")
            XCTAssertEqual(obj2.value, "fuga")
            
            expect.fulfill()
            
        }
        
        self.wait()
    }
    
    func testKVO_map()
    {
        let expect = self.expectationWithDescription(__FUNCTION__)
        
        let obj1 = MyObject()
        let obj2 = MyObject()
        
        let signal = KVO.signal(obj1, "value").map { (value: AnyObject?) -> NSString? in
            return (value as String).uppercaseString
        }
        
        // REACT
        (obj2, "value") <~ signal
        
        // REACT
        ^{ println("[REACT] new value = \($0)") } <~ signal
        
        println("*** Start ***")
        
        XCTAssertEqual(obj1.value, "initial")
        XCTAssertEqual(obj2.value, "initial")
        
        self.perform {
            
            obj1.value = "hoge"
            
            XCTAssertEqual(obj1.value, "hoge")
            XCTAssertEqual(obj2.value, "HOGE")
            
            obj1.value = "fuga"
            
            XCTAssertEqual(obj1.value, "fuga")
            XCTAssertEqual(obj2.value, "FUGA")
            
            expect.fulfill()
            
        }
        
        self.wait()
    }
    
    func testKVO_take()
    {
        let expect = self.expectationWithDescription(__FUNCTION__)
        
        let obj1 = MyObject()
        let obj2 = MyObject()
        
        let signal = KVO.signal(obj1, "value").take(1)  // only take 1 event
        weak var weakSignal = signal
        
        // REACT: obj1.value ~> obj2.value
        (obj2, "value") <~ signal
        
        // REACT: obj1.value ~> println
        ^{ println("[REACT] new value = \($0)") } <~ signal
        
        println("*** Start ***")
        
        XCTAssertEqual(obj1.value, "initial")
        XCTAssertEqual(obj2.value, "initial")
        
        self.perform {
            
            XCTAssertNotNil(weakSignal)
            
            obj1.value = "hoge"
            
            XCTAssertEqual(obj1.value, "hoge")
            XCTAssertEqual(obj2.value, "hoge")
            
            obj1.value = "fuga"
            
            XCTAssertEqual(obj1.value, "fuga")
            XCTAssertEqual(obj2.value, "hoge", "obj2.value should not be updated because signal is finished via take().")
            
            expect.fulfill()
            
        }
        
        self.wait()
    }
    
    func testKVO_takeUntil()
    {
        let expect = self.expectationWithDescription(__FUNCTION__)
        
        let obj1 = MyObject()
        let obj2 = MyObject()
        let stopper = MyObject()
        
        let stoppingSignal = KVO.signal(stopper, "value")    // store stoppingSignal to live until end of runloop
        let signal = KVO.signal(obj1, "value").takeUntil(stoppingSignal)
        
        weak var weakSignal = signal
        
        // REACT
        (obj2, "value") <~ signal
        
        // REACT
        ^{ println("[REACT] new value = \($0)") } <~ signal
        
        println("*** Start ***")
        
        XCTAssertEqual(obj1.value, "initial")
        XCTAssertEqual(obj2.value, "initial")
        
        self.perform {
            
            obj1.value = "hoge"
            
            XCTAssertEqual(obj1.value, "hoge")
            XCTAssertEqual(obj2.value, "hoge")
            
            stopper.value = "DUMMY" // fire stoppingSignal
            
            obj1.value = "fuga"
            
            XCTAssertEqual(obj1.value, "fuga")
            XCTAssertEqual(obj2.value, "hoge", "obj2.value should not be updated because signal is stopped via takeUntil(stoppingSignal).")
            
            expect.fulfill()
            
        }
        
        self.wait()
    }
    
    func testKVO_any()
    {
        let expect = self.expectationWithDescription(__FUNCTION__)
        
        let obj1 = MyObject()
        let obj2 = MyObject()
        let obj3 = MyObject()
        
        let signal1 = KVO.signal(obj1, "value")
        let signal2 = KVO.signal(obj2, "number")
        
        var bundledSignal = Signal.any([signal1, signal2]).filter { values, changedValue in
            
            println("values = \(values)")
            println("changedValue = \(changedValue)")
            
            if let str = changedValue as? NSString {
                return str == "test2"
            }
            else if let number = changedValue as? NSNumber {
                return true
            }
            
            return false
            
        }.map { (values, changedValue: AnyObject?) -> NSString? in
            
            // NOTE: changedValue may be NSString or NSNumber
            if let changedValue: AnyObject = changedValue {
                return "\(changedValue)" // use if-let to unwrap optional, removing "Optional()" string
            }
            return nil
        }
        
        // REACT
        (obj3, "value") <~ bundledSignal
        
        // REACT
        ^{ println("[REACT] new value = \($0)") } <~ bundledSignal
        
        println("*** Start ***")
        
        self.perform {
            XCTAssertEqual(obj3.value, "initial")
            
            obj1.value = "test1"
            XCTAssertEqual(obj3.value, "initial", "obj3.value should not be updated because of filter (only 'test2' is allowed).")
            
            obj1.value = "test2"
            XCTAssertEqual(obj3.value, "test2", "obj3.value should be updated.")
            
            obj2.value = "test3"
            XCTAssertEqual(obj3.value, "test2", "obj3.value should not be updated because of filter (only 'test2' is allowed).")
            
            obj2.number = 123
            XCTAssertEqual(obj3.value, "123", "obj3.value should be updated because number is not filtered.")
            
            expect.fulfill()
        }
        
        self.wait()
    }
    
    func testKVO_multiple()
    {
        let expect = self.expectationWithDescription(__FUNCTION__)
        
        let obj1 = MyObject()
        let obj2 = MyObject()
        let obj3 = MyObject()
        
        let signal = KVO.signal(obj1, "value").map { (value: AnyObject?) -> [NSString?] in
            if let str = value as? NSString? {
                if let str = str {
                    return [ "\(str)-2" as NSString?, "\(str)-3" as NSString? ]
                }
            }
            return []
        }
        weak var weakSignal = signal
        
        // REACT
        [ (obj2, "value"), (obj3, "value") ] <~ signal
        
        println("*** Start ***")
        
        XCTAssertEqual(obj1.value, "initial")
        XCTAssertEqual(obj2.value, "initial")
        XCTAssertEqual(obj3.value, "initial")
        
        self.perform {
            
            XCTAssertNotNil(weakSignal)
            
            obj1.value = "hoge"
            
            XCTAssertEqual(obj1.value, "hoge")
            XCTAssertEqual(obj2.value, "hoge-2")
            XCTAssertEqual(obj3.value, "hoge-3")
            
            weakSignal?.cancel()
            
            obj1.value = "fuga"
            
            XCTAssertEqual(obj1.value, "fuga")
            XCTAssertEqual(obj2.value, "hoge-2", "obj2.value should not be updated because signal is already cancelled.")
            XCTAssertEqual(obj3.value, "hoge-3", "obj3.value should not be updated because signal is already cancelled.")
            
            expect.fulfill()
            
        }
        
        self.wait()
    }
}

class AsyncKVOTests: KVOTests
{
    override var isAsync: Bool { return true }
}