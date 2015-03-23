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
    var UTF8: NSData {
        return dataUsingEncoding(NSUTF8StringEncoding)!
    }
}

internal func midIndex<Ix : RandomAccessIndexType>(start: Ix, end: Ix) -> Ix {
    return start.advancedBy(start.distanceTo(end) / 2)
}

internal func forkEqualRange<Ix : RandomAccessIndexType>
    (range: Range<Ix>, ord: Ix -> NSComparisonResult) -> (lower: Range<Ix>,
                                                          upper: Range<Ix>)
{
    var (lo, hi) = (range.startIndex, range.endIndex)
    while lo < hi {
        let m = midIndex(lo, hi)
        switch ord(m) {
        case .OrderedAscending:  lo = m.successor()
        case .OrderedSame:       return (lo ..< m, m ..< hi)
        case .OrderedDescending: hi = m
        }
    }
    return (lo ..< lo, lo ..< lo)
}

extension WriteBatch {
    
    var diff: [(key: Key, value: Value?)] {
        var diffs: [(key: Key, value: Value?)] = []
        enumerate {key, value in
            let (lower, upper) = forkEqualRange(indices(diffs)) {i in
                return diffs[i].0 < key  ? .OrderedAscending
                     : diffs[i].0 == key ? .OrderedSame
                                         : .OrderedDescending
            }
            if lower.startIndex != upper.endIndex {
                diffs[lower.endIndex] = (key, value)
            } else {
                diffs.insert((key, value), atIndex: lower.endIndex)
            }
        }
        return diffs
    }
    
}

extension NSData {
    convenience init(bytes: [UInt8]) {
        let (address, length) = bytes.withUnsafeBufferPointer {buffer in
            (buffer.baseAddress, buffer.count)
        }
        self.init(bytes: address, length: length)
    }
    convenience init(bytes: UInt8...) {
        self.init(bytes: bytes)
    }

    var UTF8String: String {
        return NSString(data: self, encoding: NSUTF8StringEncoding)! as String
    }
}

extension NSData : Comparable {}

public func == (a: NSData, b: NSData) -> Bool { return a.isEqualToData(b) }
public func < (a: NSData, b: NSData) -> Bool { return NSData.ldb_compareLeft(a, right: b).rawValue < 0 }

func tempDbPath() -> String {
    let unique = NSProcessInfo.processInfo().globallyUniqueString
    return NSTemporaryDirectory().stringByAppendingPathComponent(unique)
}

func destroyTempDb(path: String) {
    LDBDatabase.destroyDatabaseAtPath(path, error: nil)
    assert(!NSFileManager.defaultManager().fileExistsAtPath(path))
}

func XCTAssertEqual<A : Equatable>(x: A?, y: A?, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssert(x == y, "\(x) is not equal to \(y) -- \(message)", file: file, line: line)
}

func XCTAssertEqual<A : Equatable>(x: A, y: A?, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssert(x == y, "\(x) is not equal to \(y) -- \(message)", file: file, line: line)
}

func XCTAssertEqual<A : Equatable>(x: A?, y: A, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssert(x == y, "\(x) is not equal to \(y) -- \(message)", file: file, line: line)
}

func XCTAssertEqual<A : Equatable, B : Equatable>(xs: [(A, B)], ys: [(A, B)], _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertEqual(xs.count, ys.count, message, file: file, line: line)
    for (x, y) in Zip2(xs, ys) {
        XCTAssertEqual(x.0, y.0, message, file: file, line: line)
        XCTAssertEqual(x.1, y.1, message, file: file, line: line)
    }
}

func XCTAssertEqual<A : Equatable, B : Equatable>(xs: [(A, B?)], ys: [(A, B?)], _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertEqual(xs.count, ys.count, message, file: file, line: line)
    for (x, y) in Zip2(xs, ys) {
        XCTAssertEqual(x.0, y.0, message, file: file, line: line)
        XCTAssertEqual(x.1, y.1, message, file: file, line: line)
    }
}

func XCTAssertEqual<A : Equatable, B : Equatable>(xs: [(key: A, value: B?)], ys: [(key: A, value: B?)], _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertEqual(xs.count, ys.count, message, file: file, line: line)
    for (x, y) in Zip2(xs, ys) {
        XCTAssertEqual(x.0, y.0, message, file: file, line: line)
        XCTAssertEqual(x.1, y.1, message, file: file, line: line)
    }
}
