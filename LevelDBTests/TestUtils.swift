//
//  TestUtils.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation
import XCTest
import LevelDB

extension String {
    var UTF8: Data {
        return data(using: String.Encoding.utf8)!
    }
}

internal func midIndex(_ start: Int, end: Int) -> Int {
    return start + (end - start) / 2
}

internal func forkEqualRange(_ range: CountableRange<Int>,
                             ordering ord: (Int) -> ComparisonResult)
    -> (lower: CountableRange<Int>, upper: CountableRange<Int>)
{
    var (lo, hi) = (range.lowerBound, range.upperBound)
    while lo < hi {
        let m = midIndex(lo, end: hi)
        switch ord(m) {
        case .orderedAscending:  lo = m + 1
        case .orderedSame:       return (lo ..< m, m ..< hi)
        case .orderedDescending: hi = m
        }
    }
    return (lo ..< lo, lo ..< lo)
}

extension WriteBatch {
    
    var diff: [(key: Key, value: Value?)] {
        var diffs: [(key: Key, value: Value?)] = []
        enumerate {key, value in
            let (lower, upper) = forkEqualRange(diffs.indices) {i in
                return diffs[i].0 < key  ? .orderedAscending
                     : diffs[i].0 == key ? .orderedSame
                                         : .orderedDescending
            }
            if lower.lowerBound != upper.upperBound {
                diffs[lower.upperBound] = (key, value)
            } else {
                diffs.insert((key, value), at: lower.upperBound)
            }
        }
        return diffs
    }
    
}

extension Data {
    init(bytes: UInt8...) {
        self.init(bytes: bytes)
    }

    var UTF8String: String {
        return NSString(data: self, encoding: String.Encoding.utf8.rawValue)! as String
    }
}

extension Data : Comparable {}

public func < (a: Data, b: Data) -> Bool { return NSData.ldb_compareLeft(a, right: b).rawValue < 0 }

func tempDbPath() -> String {
    let unique = ProcessInfo.processInfo.globallyUniqueString
    return NSTemporaryDirectory() + "/" + unique
}

func destroyTempDb(_ path: String) {
    do {
        try LDBDatabase.destroy(atPath: path)
    } catch _ {
    }
    assert(!FileManager.default.fileExists(atPath: path))
}

func AssertEqual<A : Equatable, B : Equatable>(_ xs: [(A, B)], _ ys: [(A, B)], _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(xs.count, ys.count, message, file: file, line: line)
    for (x, y) in zip(xs, ys) {
        XCTAssertEqual(x.0, y.0, message, file: file, line: line)
        XCTAssertEqual(x.1, y.1, message, file: file, line: line)
    }
}

func AssertEqual<A : Equatable, B : Equatable>(_ xs: [(A, B?)], _ ys: [(A, B?)], _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(xs.count, ys.count, message, file: file, line: line)
    for (x, y) in zip(xs, ys) {
        XCTAssertEqual(x.0, y.0, message, file: file, line: line)
        XCTAssertEqual(x.1, y.1, message, file: file, line: line)
    }
}

func AssertEqual<A : Equatable, B : Equatable>(_ xs: [(key: A, value: B?)], _ ys: [(key: A, value: B?)], _ message: String = "", file: StaticString = #file, line: UInt = #line) {
    XCTAssertEqual(xs.count, ys.count, message, file: file, line: line)
    for (x, y) in zip(xs, ys) {
        XCTAssertEqual(x.0, y.0, message, file: file, line: line)
        XCTAssertEqual(x.1, y.1, message, file: file, line: line)
    }
}
