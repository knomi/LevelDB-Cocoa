//
//  IntervalTests.swift
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import XCTest
import Foundation
import LevelDB

class IntervalTests: XCTestCase {

    typealias C = NSComparisonResult
    let everything = LDBInterval.everything()
    let a = LDBInterval(start: NSData(),             end: NSData(bytes: 1,2,3))
    let b = LDBInterval(start: NSData(bytes: 1,2,3), end: NSData(bytes: 2,1))
    let c = LDBInterval(start: NSData(bytes: 2,1),   end: nil)
    
    func testIsEmpty() {
        XCTAssertFalse(everything.isEmpty)
        XCTAssertFalse(a.isEmpty)
        XCTAssertFalse(b.isEmpty)
        XCTAssertFalse(c.isEmpty)
        XCTAssert(LDBInterval(start: a.start, end: a.start).isEmpty)
        XCTAssert(LDBInterval(start: b.start, end: b.start).isEmpty)
        XCTAssert(LDBInterval(start: c.start, end: c.start).isEmpty)
        XCTAssert(LDBInterval(start: nil,     end: nil).isEmpty)
    }

    func testCompareToKey() {
        XCTAssertEqual(everything.compareToKey(NSData()), C.OrderedSame)
        XCTAssertEqual(everything.compareToKey(NSData(bytes: 1,2,3)), C.OrderedSame)
        XCTAssertEqual(everything.compareToKey(nil), C.OrderedAscending)
        
        XCTAssertEqual(a.compareToKey(NSData()),             C.OrderedSame)
        XCTAssertEqual(a.compareToKey(NSData(bytes: 1,2,2)), C.OrderedSame)
        XCTAssertEqual(a.compareToKey(NSData(bytes: 1,2,3)), C.OrderedAscending)
        XCTAssertEqual(a.compareToKey(NSData(bytes: 2)),     C.OrderedAscending)
        XCTAssertEqual(a.compareToKey(NSData(bytes: 2,1)),   C.OrderedAscending)
        XCTAssertEqual(a.compareToKey(nil),                  C.OrderedAscending)

        XCTAssertEqual(b.compareToKey(NSData()),             C.OrderedDescending)
        XCTAssertEqual(b.compareToKey(NSData(bytes: 1,2,2)), C.OrderedDescending)
        XCTAssertEqual(b.compareToKey(NSData(bytes: 1,2,3)), C.OrderedSame)
        XCTAssertEqual(b.compareToKey(NSData(bytes: 2)),     C.OrderedSame)
        XCTAssertEqual(b.compareToKey(NSData(bytes: 2,0,1)), C.OrderedSame)
        XCTAssertEqual(b.compareToKey(NSData(bytes: 2,1)),   C.OrderedAscending)
        XCTAssertEqual(b.compareToKey(nil),                  C.OrderedAscending)
        
        XCTAssertEqual(c.compareToKey(NSData()),             C.OrderedDescending)
        XCTAssertEqual(c.compareToKey(NSData(bytes: 1,2,2)), C.OrderedDescending)
        XCTAssertEqual(c.compareToKey(NSData(bytes: 2,0,1)), C.OrderedDescending)
        XCTAssertEqual(c.compareToKey(NSData(bytes: 2,1)),   C.OrderedSame)
        XCTAssertEqual(c.compareToKey(NSData(bytes: 10)),    C.OrderedSame)
        XCTAssertEqual(c.compareToKey(nil),                  C.OrderedAscending)
    }
    
    func testEqual() {
        XCTAssertEqual(everything, everything)
        XCTAssertEqual(a, a)
        XCTAssertEqual(b, b)
        XCTAssertEqual(c, c)
        XCTAssertNotEqual(a, everything)
        XCTAssertNotEqual(everything, c)
    }
    
    func testClamp() {
        XCTAssertEqual(b.clamp(everything), b)
        XCTAssertEqual(b.clamp(b), b)
        XCTAssertEqual(b.clamp(LDBInterval(start: NSData(bytes: 1), end: NSData(bytes: 2))),
                       LDBInterval(start: b.start, end: NSData(bytes: 2)))
        XCTAssertEqual(b.clamp(LDBInterval(start: NSData(bytes: 2), end: NSData(bytes: 5))),
                       LDBInterval(start: NSData(bytes: 2), end: b.end))
        XCTAssertEqual(a.clamp(c), LDBInterval(start: c.start, end: c.start))
        XCTAssertEqual(c.clamp(a), LDBInterval(start: a.end, end: a.end))
    }
    
    func testContains() {
        XCTAssert(a.contains(NSData()))
        XCTAssert(a.contains(NSData(bytes: 0)))
        XCTAssert(a.contains(NSData(bytes: 1,2,2)))
        XCTAssert(a.contains(NSData(bytes: 1,2,2,255,255,255)))
        XCTAssertFalse(a.contains(NSData(bytes: 1,2,3)))
        XCTAssertFalse(a.contains(nil))
        
        XCTAssertFalse(b.contains(NSData()))
        XCTAssertFalse(b.contains(NSData(bytes: 1,2,2,255,255,255)))
        XCTAssert(b.contains(NSData(bytes: 1,2,3)))
        XCTAssert(b.contains(NSData(bytes: 1,2,3,255,255,255)))
        XCTAssert(b.contains(NSData(bytes: 2,0)))
        XCTAssertFalse(b.contains(NSData(bytes: 2,1)))
        XCTAssertFalse(b.contains(nil))

        XCTAssert(everything.contains(NSData()))
        XCTAssert(everything.contains(NSData(bytes: 0)))
        XCTAssert(everything.contains(NSData(bytes: 255,255,255,255, 255,255,255,255)))
        XCTAssertFalse(everything.contains(nil))
    }

    func testContainsBefore() {
        XCTAssertFalse(a.containsBefore(NSData()))
        XCTAssert(a.containsBefore(NSData(bytes: 0)))
        XCTAssert(a.containsBefore(NSData(bytes: 1,2,2)))
        XCTAssert(a.containsBefore(NSData(bytes: 1,2,2,255,255,255)))
        XCTAssert(a.containsBefore(NSData(bytes: 1,2,3)))
        XCTAssertFalse(a.containsBefore(NSData(bytes: 1,2,3,0)))
        XCTAssertFalse(a.containsBefore(nil))
        
        XCTAssertFalse(b.containsBefore(NSData()))
        XCTAssertFalse(b.containsBefore(NSData(bytes: 1,2,2,255,255,255)))
        XCTAssertFalse(b.containsBefore(NSData(bytes: 1,2,3)))
        XCTAssert(b.containsBefore(NSData(bytes: 1,2,3,0)))
        XCTAssert(b.containsBefore(NSData(bytes: 1,2,3,255,255,255)))
        XCTAssert(b.containsBefore(NSData(bytes: 2,0)))
        XCTAssert(b.containsBefore(NSData(bytes: 2,1)))
        XCTAssertFalse(b.containsBefore(NSData(bytes: 2,1,0)))
        XCTAssertFalse(b.containsBefore(nil))

        XCTAssertFalse(everything.containsBefore(NSData()))
        XCTAssert(everything.containsBefore(NSData(bytes: 0)))
        XCTAssert(everything.containsBefore(NSData(bytes: 255,255,255,255, 255,255,255,255)))
        XCTAssert(everything.containsBefore(nil))
    }
    
}
