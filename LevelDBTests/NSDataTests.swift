//
//  NSDataTests.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 11.02.2015.
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation
import XCTest
import LevelDB

extension LevelDBTests {

    func testLexicographicalNextSibling() {
        let bytes = {(var array: [UInt8]) -> NSData in
            NSData(bytes: &array, length: array.count)
        }
        
        XCTAssertEqual(NSData().ldb_lexicographicalNextSibling(),        nil)

        XCTAssertEqual("A".UTF8.ldb_lexicographicalNextSibling(), "B".UTF8)
        XCTAssertEqual("Ab".UTF8.ldb_lexicographicalNextSibling(), "Ac".UTF8)
        XCTAssertEqual("x 8".UTF8.ldb_lexicographicalNextSibling(), "x 9".UTF8)

        let m = UInt8.max
        XCTAssertEqual(bytes([m]).ldb_lexicographicalNextSibling(),       nil)
        XCTAssertEqual(bytes([m, m]).ldb_lexicographicalNextSibling(),    nil)
        XCTAssertEqual(bytes([m, m, m]).ldb_lexicographicalNextSibling(), nil)
        XCTAssertEqual(bytes([m, m, 9]).ldb_lexicographicalNextSibling(), bytes([m, m, 10]))
        XCTAssertEqual(bytes([m, 0, m]).ldb_lexicographicalNextSibling(), bytes([m, 1, 0]))
        XCTAssertEqual(bytes([m, 1, m]).ldb_lexicographicalNextSibling(), bytes([m, 2, 0]))
        XCTAssertEqual(bytes([5, m, m]).ldb_lexicographicalNextSibling(), bytes([6, 0, 0]))
    }
    
    func testLexicographicalNextChild() {
        let bytes = {(var array: [UInt8]) -> NSData in
            NSData(bytes: &array, length: array.count)
        }
        
        XCTAssertEqual(NSData().ldb_lexicographicalFirstChild(),        bytes([0]))

        XCTAssertEqual(bytes([0]).ldb_lexicographicalFirstChild(), bytes([0, 0]))
        XCTAssertEqual(bytes([10]).ldb_lexicographicalFirstChild(), bytes([10, 0]))
        XCTAssertEqual(bytes([10, 20]).ldb_lexicographicalFirstChild(), bytes([10, 20, 0]))

        let m = UInt8.max
        XCTAssertEqual(bytes([m]).ldb_lexicographicalFirstChild(),       bytes([m, 0]))
        XCTAssertEqual(bytes([m, m]).ldb_lexicographicalFirstChild(),    bytes([m, m, 0]))
        XCTAssertEqual(bytes([m, m, m]).ldb_lexicographicalFirstChild(), bytes([m, m, m, 0]))
        XCTAssertEqual(bytes([m, m, 9]).ldb_lexicographicalFirstChild(), bytes([m, m, 9, 0]))
    }

}
