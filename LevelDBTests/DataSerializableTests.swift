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
            -DBL_MAX,
            -1.0e10,
            -2015.0,
            -20.1,
            -2.0,
            -1.0,
            -0.5,
            -3.0 * DBL_MIN,
            -DBL_MIN,
            -DBL_MIN + DBL_TRUE_MIN,
            -DBL_TRUE_MIN,
            -0.0,
            0.0,
            DBL_TRUE_MIN,
            2.0 * DBL_TRUE_MIN,
            DBL_MIN - DBL_TRUE_MIN,
            DBL_MIN,
            0.5 * (2.0 - DBL_EPSILON),
            1.0,
            1 + DBL_EPSILON,
            2.0,
            2015.0,
            1e100 as Double,
            DBL_MAX as Double,
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
        
        XCTAssert(Double(orderPreservingValue: Double.NaN.orderPreservingValue).isNaN)
    }
    
    private func check<T : DataSerializable>(a: T, _ b: T, equal: (T, T) -> Bool, less: (T, T) -> Bool) {
        let x: NSData   = a.serializedData
        let y: NSData   = b.serializedData
        let a1: T?      = T.fromSerializedData(x)
        let b1: T?      = T.fromSerializedData(y)
        let x1: NSData? = a1?.serializedData
        let y1: NSData? = b1?.serializedData
        
        XCTAssert(a1 != nil, "\(a) failed to round trip the conversion")
        XCTAssert(b1 != nil, "\(b) failed to round trip the conversion")
        
        XCTAssert(equal(a1 ?? a, a), "\(a1 ?? a), converted from \(x), is not equal to \(a)")
        XCTAssert(equal(b1 ?? b, b), "\(b1 ?? b), converted from \(y), is not equal to \(b)")
        
        XCTAssertEqual(x, x1 ?? x, "serialized values of \(a) and \(a1) don't match")
        XCTAssertEqual(y, y1 ?? y, "serialized values of \(b) and \(b1) don't match")
        
        XCTAssertEqual(equal(a, b), x == y, "\(a) and \(b) equate differently from \(x) and \(y)")
        XCTAssertEqual(less(a, b), x < y, "\(a) and \(b) less-than compare differently from \(x) and \(y)")
        XCTAssertEqual(less(b, a), y < x, "\(b) and \(a) less-than compare differently from \(y) and \(x)")
    }
    
    private func check<T : protocol<DataSerializable, Comparable>>(a: T, _ b: T) {
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
            "E",
            "Ë",
            "EE",
            "EË",
            "ËE",
            "ËË",
        ]
        for a in values {
            for b in values {
                check(a, b)
            }
        }
    }
    
    func testNSData() {
        let objects: [NSData] = [
            NSData(),
            NSData(bytes: 0),
            NSData(bytes: 0, 0),
            NSData(bytes: 0, 0, 0),
            NSData(bytes: 0, 1),
            NSData(bytes: 1),
            NSData(bytes: 1, 0),
            NSData(bytes: 1, 1),
            NSData(bytes: 1, 2),
            NSData(bytes: 1, 2, 0),
            NSData(bytes: 1, 2, 1),
            NSData(bytes: 1, 2, 2),
            NSData(bytes: 1, 2, 3),
            NSData(bytes: 2),
            NSData(bytes: 255),
            NSData(bytes: 255, 0),
            NSData(bytes: 255, 255),
            NSData(bytes: 255, 255, 255, 255),
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
            -DBL_MAX,
            -1.0e10,
            -2015.0,
            -20.1,
            -2.0,
            -1.0,
            -0.5,
            -3.0 * DBL_MIN,
            -DBL_MIN,
            -DBL_MIN + DBL_TRUE_MIN,
            -DBL_TRUE_MIN,
            -0.0,
            0.0,
            DBL_TRUE_MIN,
            2.0 * DBL_TRUE_MIN,
            DBL_MIN - DBL_TRUE_MIN,
            DBL_MIN,
            0.5 * (2.0 - DBL_EPSILON),
            1.0,
            1 + DBL_EPSILON,
            2.0,
            2015.0,
            1e100 as Double,
            DBL_MAX as Double,
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
