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
    public static func compare(left: Key, _ right: Key) -> Ordering {
        let c = memcmp(left.bytes, right.bytes, UInt(min(left.length, right.length)))
        if c < 0 { return .LT }
        if c > 0 { return .GT }
        return LevelDB.compare(left.length, right.length)
    }

}
