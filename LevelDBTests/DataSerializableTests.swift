//
//  DataSerializableTests.swift
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import LevelDB
import Foundation
import XCTest

class DataSerializableTests : XCTestCase {

    func testDoubleOrderPreserving() {
        let doubles: [Double] = [
            -Double.infinity,
            -Double.greatestFiniteMagnitude,
            -1.0e10,
            -2015.0,
            -20.1,
            -2.0,
            -1.0,
            -0.5,
            -3.0 * Double.leastNormalMagnitude,
            -Double.leastNormalMagnitude,
            -Double.leastNormalMagnitude + Double.leastNonzeroMagnitude,
            -Double.leastNonzeroMagnitude,
            -0.0,
            0.0,
            Double.leastNonzeroMagnitude,
            2.0 * Double.leastNonzeroMagnitude,
            Double.leastNormalMagnitude - Double.leastNonzeroMagnitude,
            Double.leastNormalMagnitude,
            0.5 * (2.0 - Double.ulpOfOne),
            1.0,
            1 + Double.ulpOfOne,
            2.0,
            2015.0,
            1e100 as Double,
            Double.greatestFiniteMagnitude,
            Double.infinity
        ]
        
        for double1 in doubles {
            let value1  = double1.orderPreservingValue
            let double2 = Double(orderPreservingValue: value1)
            let value2  = double2.orderPreservingValue
            XCTAssertEqual(double1, double1, "sanity check against NaN")
            XCTAssertEqual(double1, double2)
            XCTAssertEqual(value1, value2)
        }
        
        for x in doubles {
            for y in doubles {
                XCTAssertEqual(x < y, x.orderPreservingValue < y.orderPreservingValue, "x=\(x), y=\(y)")
            }
        }
        
        XCTAssert(Double(orderPreservingValue: Double.nan.orderPreservingValue).isNaN)
    }
    
    fileprivate func check<T : DataSerializable>(_ a: T, _ b: T, equal: (T, T) -> Bool, less: (T, T) -> Bool) {
        let x: Data   = a.serializedData
        let y: Data   = b.serializedData
        let a1: T?    = T.fromSerializedData(x)
        let b1: T?    = T.fromSerializedData(y)
        let x1: Data? = a1?.serializedData
        let y1: Data? = b1?.serializedData
        
        XCTAssert(a1 != nil, "\(a) failed to round trip the conversion")
        XCTAssert(b1 != nil, "\(b) failed to round trip the conversion")
        
        XCTAssert(equal(a1 ?? a, a), "\(a1 ?? a), converted from \(x), is not equal to \(a)")
        XCTAssert(equal(b1 ?? b, b), "\(b1 ?? b), converted from \(y), is not equal to \(b)")
        
        XCTAssertEqual(x, x1 ?? x, "serialized values of \(a) and \(String(describing: a1)) don't match")
        XCTAssertEqual(y, y1 ?? y, "serialized values of \(b) and \(String(describing: b1)) don't match")
        
        XCTAssertEqual(equal(a, b), x == y, "\(a) and \(b) compare differently from \(x) and \(y)")
        XCTAssertEqual(less(a, b), x < y, "\(a) and \(b) compare differently from \(x) and \(y)")
        XCTAssertEqual(less(b, a), y < x, "\(b) and \(a) compare differently from \(y) and \(x)")
    }
    
    fileprivate func check<T : DataSerializable & Comparable>(_ a: T, _ b: T) {
        check(a, b, equal: {$0 == $1}, less: {$0 < $1})
    }
    
    func testString() {
        let values: [String] = [
            "",
            " ",
            "!",
            "0",
            "A",
            "A!",
            "Aa!",
            "a",
            "askfjhsf",
            "gklja",
            "gklja a!",
            "oqiwu aslkjh asu qyw",
            "z",
            "~ ~~~",
            "~a~~~",
            "~~~~",
        ]
        for a in values {
            for b in values {
                check(a, b)
            }
        }
    }
    
    func testNSData() {
        let objects: [Data] = [
            Data(),
            Data(bytes: 0),
            Data(bytes: 0, 0),
            Data(bytes: 0, 0, 0),
            Data(bytes: 0, 1),
            Data(bytes: 1),
            Data(bytes: 1, 0),
            Data(bytes: 1, 1),
            Data(bytes: 1, 2),
            Data(bytes: 1, 2, 0),
            Data(bytes: 1, 2, 1),
            Data(bytes: 1, 2, 2),
            Data(bytes: 1, 2, 3),
            Data(bytes: 2),
            Data(bytes: 255),
            Data(bytes: 255, 0),
            Data(bytes: 255, 255),
            Data(bytes: 255, 255, 255, 255),
        ]
        for a in objects {
            for b in objects {
                check(a, b)
            }
        }
    }
    
    func testDouble() {
        let values: [Double] = [
            -Double.infinity,
            -Double.greatestFiniteMagnitude,
            -1.0e10,
            -2015.0,
            -20.1,
            -2.0,
            -1.0,
            -0.5,
            -3.0 * Double.leastNormalMagnitude,
            -Double.leastNormalMagnitude,
            -Double.leastNormalMagnitude + Double.leastNonzeroMagnitude,
            -Double.leastNonzeroMagnitude,
            -0.0,
            0.0,
            Double.leastNonzeroMagnitude,
            2.0 * Double.leastNonzeroMagnitude,
            Double.leastNormalMagnitude - Double.leastNonzeroMagnitude,
            Double.leastNormalMagnitude,
            0.5 * (2.0 - Double.ulpOfOne),
            1.0,
            1 + Double.ulpOfOne,
            2.0,
            2015.0,
            1e100 as Double,
            Double.greatestFiniteMagnitude,
            Double.infinity
        ]
        
        for a in values {
            for b in values {
                check(a, b)
            }
        }
    }
    
    func testUInt8() {
        let vals: [UInt8] = [0, 1, 2, 10, 16, 31, 32, 33, 63, 64, 65, 127, 128, 129, 254, 255]
        for a in vals {
            for b in vals {
                check(a, b)
            }
        }
    }
    
    func testUInt16() {
        let vals: [UInt16] = [0, 1, 2, 10, 16, 31, 32, 33, 63, 64, 65, 127, 128, 129, 254, 255, 10000, UInt16.max]
        for a in vals {
            for b in vals {
                check(a, b)
            }
        }
    }
    
    func testUInt32() {
        let vals: [UInt32] = [0, 1, 2, 10, 16, 31, 32, 33, 63, 64, 65, 127, 128, 129, 254, 255, 10000, UInt32.max]
        for a in vals {
            for b in vals {
                check(a, b)
            }
        }
    }
    
    func testUInt64() {
        let vals: [UInt64] = [0, 1, 2, 10, 16, 31, 32, 33, 63, 64, 65, 127, 128, 129, 254, 255, 10000, UInt64.max]
        for a in vals {
            for b in vals {
                check(a, b)
            }
        }
    }
    
    func testUInt() {
        let vals: [UInt] = [0, 1, 2, 10, 16, 31, 32, 33, 63, 64, 65, 127, 128, 129, 254, 255, 10000, UInt.max, UInt.min]
        for a in vals {
            for b in vals {
                check(a, b)
            }
        }
    }
    
    func testInt8() {
        let vals: [Int8] = [-128, -127, 0, 1, 2, 10, 16, 31, 32, 33, 63, 64, 65, 127]
        for a in vals {
            for b in vals {
                check(a, b)
            }
        }
    }
    
    func testInt16() {
        let vals: [Int16] = [Int16.min, Int16.min + 1, -1, 0, 1, 2, 10, 16, 31, 32, 33, 63, 64, 65, 127, 128, 129, 254, 255, 10000, Int16.max]
        for a in vals {
            for b in vals {
                check(a, b)
            }
        }
    }
    
    func testInt32() {
        let vals: [Int32] = [Int32.min, Int32.min + 1, -1, 0, 1, 2, 10, 16, 31, 32, 33, 63, 64, 65, 127, 128, 129, 254, 255, 10000, Int32.max]
        for a in vals {
            for b in vals {
                check(a, b)
            }
        }
    }
    
    func testInt64() {
        let vals: [Int64] = [Int64.min, Int64.min + 1, -1, 0, 1, 2, 10, 16, 31, 32, 33, 63, 64, 65, 127, 128, 129, 254, 255, 10000, Int64.max]
        for a in vals {
            for b in vals {
                check(a, b)
            }
        }
    }
    
    func testInt() {
        let vals: [Int] = [0, 1, 2, 10, 16, 31, 32, 33, 63, 64, 65, 127, 128, 129, 254, 255, 10000, Int.max, Int.min]
        for a in vals {
            for b in vals {
                check(a, b)
            }
        }
    }
    
}
