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

    typealias C = ComparisonResult
    let everything = LDBInterval.everything()
    let a = LDBInterval(start: Data(),             end: Data(bytes: 1,2,3))
    let b = LDBInterval(start: Data(bytes: 1,2,3), end: Data(bytes: 2,1))
    let c = LDBInterval(start: Data(bytes: 2,1),   end: nil)
    
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
        XCTAssertEqual(everything.compare(toKey: Data()), C.orderedSame)
        XCTAssertEqual(everything.compare(toKey: Data(bytes: 1,2,3)), C.orderedSame)
        XCTAssertEqual(everything.compare(toKey: nil), C.orderedAscending)
        
        XCTAssertEqual(a.compare(toKey: Data()),             C.orderedSame)
        XCTAssertEqual(a.compare(toKey: Data(bytes: 1,2,2)), C.orderedSame)
        XCTAssertEqual(a.compare(toKey: Data(bytes: 1,2,3)), C.orderedAscending)
        XCTAssertEqual(a.compare(toKey: Data(bytes: 2)),     C.orderedAscending)
        XCTAssertEqual(a.compare(toKey: Data(bytes: 2,1)),   C.orderedAscending)
        XCTAssertEqual(a.compare(toKey: nil),                  C.orderedAscending)

        XCTAssertEqual(b.compare(toKey: Data()),             C.orderedDescending)
        XCTAssertEqual(b.compare(toKey: Data(bytes: 1,2,2)), C.orderedDescending)
        XCTAssertEqual(b.compare(toKey: Data(bytes: 1,2,3)), C.orderedSame)
        XCTAssertEqual(b.compare(toKey: Data(bytes: 2)),     C.orderedSame)
        XCTAssertEqual(b.compare(toKey: Data(bytes: 2,0,1)), C.orderedSame)
        XCTAssertEqual(b.compare(toKey: Data(bytes: 2,1)),   C.orderedAscending)
        XCTAssertEqual(b.compare(toKey: nil),                  C.orderedAscending)
        
        XCTAssertEqual(c.compare(toKey: Data()),             C.orderedDescending)
        XCTAssertEqual(c.compare(toKey: Data(bytes: 1,2,2)), C.orderedDescending)
        XCTAssertEqual(c.compare(toKey: Data(bytes: 2,0,1)), C.orderedDescending)
        XCTAssertEqual(c.compare(toKey: Data(bytes: 2,1)),   C.orderedSame)
        XCTAssertEqual(c.compare(toKey: Data(bytes: 10)),    C.orderedSame)
        XCTAssertEqual(c.compare(toKey: nil),                  C.orderedAscending)
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
        XCTAssertEqual(b.clamp(LDBInterval(start: Data(bytes: 1), end: Data(bytes: 2))),
                       LDBInterval(start: b.start, end: Data(bytes: 2)))
        XCTAssertEqual(b.clamp(LDBInterval(start: Data(bytes: 2), end: Data(bytes: 5))),
                       LDBInterval(start: Data(bytes: 2), end: b.end))
        XCTAssertEqual(a.clamp(c), LDBInterval(start: c.start, end: c.start))
        XCTAssertEqual(c.clamp(a), LDBInterval(start: a.end, end: a.end))
    }
    
    func testContains() {
        XCTAssert(a.contains(Data()))
        XCTAssert(a.contains(Data(bytes: 0)))
        XCTAssert(a.contains(Data(bytes: 1,2,2)))
        XCTAssert(a.contains(Data(bytes: 1,2,2,255,255,255)))
        XCTAssertFalse(a.contains(Data(bytes: 1,2,3)))
        XCTAssertFalse(a.contains(nil))
        
        XCTAssertFalse(b.contains(Data()))
        XCTAssertFalse(b.contains(Data(bytes: 1,2,2,255,255,255)))
        XCTAssert(b.contains(Data(bytes: 1,2,3)))
        XCTAssert(b.contains(Data(bytes: 1,2,3,255,255,255)))
        XCTAssert(b.contains(Data(bytes: 2,0)))
        XCTAssertFalse(b.contains(Data(bytes: 2,1)))
        XCTAssertFalse(b.contains(nil))

        XCTAssert(everything.contains(Data()))
        XCTAssert(everything.contains(Data(bytes: 0)))
        XCTAssert(everything.contains(Data(bytes: 255,255,255,255, 255,255,255,255)))
        XCTAssertFalse(everything.contains(nil))
    }

    func testContainsBefore() {
        XCTAssertFalse(a.contains(before: Data()))
        XCTAssert(a.contains(before: Data(bytes: 0)))
        XCTAssert(a.contains(before: Data(bytes: 1,2,2)))
        XCTAssert(a.contains(before: Data(bytes: 1,2,2,255,255,255)))
        XCTAssert(a.contains(before: Data(bytes: 1,2,3)))
        XCTAssertFalse(a.contains(before: Data(bytes: 1,2,3,0)))
        XCTAssertFalse(a.contains(before: nil))
        
        XCTAssertFalse(b.contains(before: Data()))
        XCTAssertFalse(b.contains(before: Data(bytes: 1,2,2,255,255,255)))
        XCTAssertFalse(b.contains(before: Data(bytes: 1,2,3)))
        XCTAssert(b.contains(before: Data(bytes: 1,2,3,0)))
        XCTAssert(b.contains(before: Data(bytes: 1,2,3,255,255,255)))
        XCTAssert(b.contains(before: Data(bytes: 2,0)))
        XCTAssert(b.contains(before: Data(bytes: 2,1)))
        XCTAssertFalse(b.contains(before: Data(bytes: 2,1,0)))
        XCTAssertFalse(b.contains(before: nil))

        XCTAssertFalse(everything.contains(before: Data()))
        XCTAssert(everything.contains(before: Data(bytes: 0)))
        XCTAssert(everything.contains(before: Data(bytes: 255,255,255,255, 255,255,255,255)))
        XCTAssert(everything.contains(before: nil))
    }
    
}
