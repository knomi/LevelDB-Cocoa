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

    func testInfinity() {
        XCTAssertEqual(NSData(),      NSData())
        XCTAssertLessThan(NSData(),   "a".UTF8)
        XCTAssertLessThan(NSData(),   NSData.infinity)
        XCTAssertLessThan("a".UTF8,   "zzz".UTF8)
        XCTAssertLessThan("a".UTF8,   NSData.infinity)
        XCTAssertLessThan("zzz".UTF8, NSData.infinity)
        XCTAssertEqual(NSData.infinity, NSData.infinity)
    }
    
    func testLexicographicalNextSibling() {
        let bytes = {(var array: [UInt8]) -> NSData in
            NSData(bytes: &array, length: array.count)
        }
        
        XCTAssertEqual(NSData().lexicographicNextSibling(),        NSData.infinity)
        XCTAssertEqual(NSData.infinity.lexicographicNextSibling(), NSData.infinity)

        XCTAssertEqual("A".UTF8.lexicographicNextSibling(), "B".UTF8)
        XCTAssertEqual("Ab".UTF8.lexicographicNextSibling(), "Ac".UTF8)
        XCTAssertEqual("x 8".UTF8.lexicographicNextSibling(), "x 9".UTF8)

        let m = UInt8.max
        XCTAssertEqual(bytes([m]).lexicographicNextSibling(),       NSData.infinity)
        XCTAssertEqual(bytes([m, m]).lexicographicNextSibling(),    NSData.infinity)
        XCTAssertEqual(bytes([m, m, m]).lexicographicNextSibling(), NSData.infinity)
        XCTAssertEqual(bytes([m, m, 9]).lexicographicNextSibling(), bytes([m, m, 10]))
        XCTAssertEqual(bytes([m, 0, m]).lexicographicNextSibling(), bytes([m, 1, 0]))
        XCTAssertEqual(bytes([m, 1, m]).lexicographicNextSibling(), bytes([m, 2, 0]))
        XCTAssertEqual(bytes([5, m, m]).lexicographicNextSibling(), bytes([6, 0, 0]))
    }
    
    func testLexicographicalNextChild() {
        let bytes = {(var array: [UInt8]) -> NSData in
            NSData(bytes: &array, length: array.count)
        }
        
        XCTAssertEqual(NSData().lexicographicFirstChild(),        bytes([0]))
        XCTAssertEqual(NSData.infinity.lexicographicFirstChild(), NSData.infinity)

        XCTAssertEqual(bytes([0]).lexicographicFirstChild(), bytes([0, 0]))
        XCTAssertEqual(bytes([10]).lexicographicFirstChild(), bytes([10, 0]))
        XCTAssertEqual(bytes([10, 20]).lexicographicFirstChild(), bytes([10, 20, 0]))

        let m = UInt8.max
        XCTAssertEqual(bytes([m]).lexicographicFirstChild(),       bytes([m, 0]))
        XCTAssertEqual(bytes([m, m]).lexicographicFirstChild(),    bytes([m, m, 0]))
        XCTAssertEqual(bytes([m, m, m]).lexicographicFirstChild(), bytes([m, m, m, 0]))
        XCTAssertEqual(bytes([m, m, 9]).lexicographicFirstChild(), bytes([m, m, 9, 0]))
    }

}
