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
    
}
