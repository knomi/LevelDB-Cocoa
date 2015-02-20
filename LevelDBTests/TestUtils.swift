//
//  TestUtils.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 11.02.2015.
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

//extension WriteBatch {
//    
//    var diff: [(Key, Value?)] {
//        var diffs: [(Key, Value?)] = []
//        enumerate {key, value in
//            let (lower, upper) = forkEqualRange(indices(diffs)) {i in
//                return diffs[i].0 <=> key
//            }
//            if lower.startIndex != upper.endIndex {
//                diffs[lower.endIndex] = (key, value)
//            } else {
//                diffs.insert((key, value), atIndex: lower.endIndex)
//            }
//        }
//        return diffs
//    }
//    
//}

extension NSData {
    var UTF8String: String {
        return NSString(data: self, encoding: NSUTF8StringEncoding)! as String
    }
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
