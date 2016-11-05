//
//  NSDataTests.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation
import XCTest
import LevelDB

class NSDataTests : XCTestCase {

    func testLexicographicalNextSibling() {
        XCTAssertEqual((Data() as NSData).ldb_lexicographicalNextSibling(),        nil)

        XCTAssertEqual(("A".UTF8 as NSData).ldb_lexicographicalNextSibling(), "B".UTF8)
        XCTAssertEqual(("Ab".UTF8 as NSData).ldb_lexicographicalNextSibling(), "Ac".UTF8)
        XCTAssertEqual(("x 8".UTF8 as NSData).ldb_lexicographicalNextSibling(), "x 9".UTF8)

        let m = UInt8.max
        XCTAssertEqual((Data(bytes: m) as NSData).ldb_lexicographicalNextSibling(),       nil)
        XCTAssertEqual((Data(bytes: m, m) as NSData).ldb_lexicographicalNextSibling(),    nil)
        XCTAssertEqual((Data(bytes: m, m, m) as NSData).ldb_lexicographicalNextSibling(), nil)
        XCTAssertEqual((Data(bytes: m, m, 9) as NSData).ldb_lexicographicalNextSibling(), Data(bytes: m, m, 10))
        XCTAssertEqual((Data(bytes: m, 0, m) as NSData).ldb_lexicographicalNextSibling(), Data(bytes: m, 1, 0))
        XCTAssertEqual((Data(bytes: m, 1, m) as NSData).ldb_lexicographicalNextSibling(), Data(bytes: m, 2, 0))
        XCTAssertEqual((Data(bytes: 5, m, m) as NSData).ldb_lexicographicalNextSibling(), Data(bytes: 6, 0, 0))
    }
    
    func testLexicographicalFirstChild() {
        XCTAssertEqual((Data() as NSData).ldb_lexicographicalFirstChild(),        Data(bytes: 0))

        XCTAssertEqual((Data(bytes: 0) as NSData).ldb_lexicographicalFirstChild(),      Data(bytes: 0, 0))
        XCTAssertEqual((Data(bytes: 10) as NSData).ldb_lexicographicalFirstChild(),     Data(bytes: 10, 0))
        XCTAssertEqual((Data(bytes: 10, 20) as NSData).ldb_lexicographicalFirstChild(), Data(bytes: 10, 20, 0))

        let m = UInt8.max
        XCTAssertEqual((Data(bytes: m) as NSData).ldb_lexicographicalFirstChild(),       Data(bytes: m, 0))
        XCTAssertEqual((Data(bytes: m, m) as NSData).ldb_lexicographicalFirstChild(),    Data(bytes: m, m, 0))
        XCTAssertEqual((Data(bytes: m, m, m) as NSData).ldb_lexicographicalFirstChild(), Data(bytes: m, m, m, 0))
        XCTAssertEqual((Data(bytes: m, m, 9) as NSData).ldb_lexicographicalFirstChild(), Data(bytes: m, m, 9, 0))
    }

}
