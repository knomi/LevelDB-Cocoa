//
//  TwoWayComparable.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 27.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

/// TODO
public protocol TwoWayComparable : Comparable {
    func twoWayCompare(to: Self) -> Ordering
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
public func compare<T : TwoWayComparable>(left: T, right: T) -> Ordering {
    return left.twoWayCompare(right)
}

public func == <T : TwoWayComparable>(left: T, right: T) -> Bool {
    return compare(left, right) == .EQ
}

public func < <T : TwoWayComparable>(left: T, right: T) -> Bool {
    return compare(left, right) == .LT
}

public func <= <T : TwoWayComparable>(left: T, right: T) -> Bool {
    return compare(left, right) != .GT
}

// MARK: Swift & Foundation extensions

public extension Ordering {
    /// TODO
    public init(_ value: NSComparisonResult) {
        self.init(rawValue: value.rawValue)
    }
}

extension String : TwoWayComparable {
    /// TODO
    public func twoWayCompare(to: String) -> Ordering {
        return Ordering(compare(to))
    }
}

//extension Array : TwoWayComparable {
//    public func twoWayCompare(to: Array) -> Ordering {
//        return .EQ
//    }
//}
