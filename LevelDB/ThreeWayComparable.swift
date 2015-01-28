//
//  ThreeWayComparable.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

/// TODO
public protocol ThreeWayComparable : Comparable {
    func threeWayCompare(to: Self) -> Ordering
}

/// TODO
public enum Ordering : Int {
    case LT = -1
    case EQ = 0
    case GT = 1
    public init(rawValue: Int) {
        self = rawValue < 0 ? .LT : rawValue == 0 ? .EQ : .GT
    }
}

/// TODO
public func compare<T : Comparable>(left: T, right: T) -> Ordering {
    if left < right { return .LT }
    if right < left { return .GT }
    assert(left == right)
    return .EQ
}

/// TODO
public func compare<T : ThreeWayComparable>(left: T, right: T) -> Ordering {
    return left.threeWayCompare(right)
}

public func == <T : ThreeWayComparable>(left: T, right: T) -> Bool {
    return left.threeWayCompare(right) == .EQ
}

public func != <T : ThreeWayComparable>(left: T, right: T) -> Bool {
    return left.threeWayCompare(right) != .EQ
}

public func < <T : ThreeWayComparable>(left: T, right: T) -> Bool {
    return left.threeWayCompare(right) == .LT
}

public func > <T : ThreeWayComparable>(left: T, right: T) -> Bool {
    return left.threeWayCompare(right) == .GT
}

public func <= <T : ThreeWayComparable>(left: T, right: T) -> Bool {
    return left.threeWayCompare(right) != .GT
}

public func >= <T : ThreeWayComparable>(left: T, right: T) -> Bool {
    return left.threeWayCompare(right) != .LT
}

// MARK: Swift & Foundation extensions

public extension Ordering {
    /// TODO
    public init(_ value: NSComparisonResult) {
        self.init(rawValue: value.rawValue)
    }
}

extension String : ThreeWayComparable {
    /// TODO
    public func threeWayCompare(to: String) -> Ordering {
        return Ordering(compare(to))
    }
}

extension NSData : ThreeWayComparable {
    /// TODO
    public func threeWayCompare(to: NSData) -> Ordering {
        let c = memcmp(bytes, to.bytes, UInt(min(length, to.length)))
        if c < 0 { return .LT }
        if c > 0 { return .GT }
        return compare(length, to.length)
    }
}

//extension Array : ThreeWayComparable {
//    public func threeWayCompare(to: Array) -> Ordering {
//        return .EQ
//    }
//}
