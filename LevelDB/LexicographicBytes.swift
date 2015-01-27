//
//  DefaultComparator.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 26.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

/// TODO
public struct LexicographicBytes : ComparatorType {

    public typealias Key = NSData
    public typealias Value = NSData

    /// TODO
    public static var name: StaticString { return "leveldb.LexicographicBytes" }

    /// TODO
    public static func compare(left: Key, _ right: Key) -> NSComparisonResult {
        let c = memcmp(left.bytes, right.bytes, UInt(min(left.length, right.length)))
        if c < 0 { return .OrderedAscending }
        if c > 0 { return .OrderedDescending }
        return compareSwift(left.length, right.length)
    }

}

private func compareSwift<T : Comparable>(a: T, b: T) -> NSComparisonResult {
    return a < b ? .OrderedAscending
         : a > b ? .OrderedDescending
         :         .OrderedSame
}
