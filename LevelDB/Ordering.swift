//
//  Ordering.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

/// TODO
public enum Ordering : Int {
    case LT = -1
    case EQ = 0
    case GT = 1
    
    public init(rawValue: Int) {
        self = rawValue < 0 ? .LT : rawValue == 0 ? .EQ : .GT
    }
}

extension Ordering : Comparable {}

public func < (a: Ordering, b: Ordering) -> Bool {
    return a.rawValue < b.rawValue
}

/// TODO
public func compare<T : Comparable>(left: T, right: T) -> Ordering {
    if left < right { return .LT }
    if right < left { return .GT }
    assert(left == right)
    return .EQ
}

public extension Ordering {
    /// TODO
    public init(_ value: NSComparisonResult) {
        self.init(rawValue: value.rawValue)
    }
}
