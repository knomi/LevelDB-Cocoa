//
//  AddBounds.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 28.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

/// TODO
public enum AddBounds<T : ThreeWayComparable> : ThreeWayComparable {

    /// TODO
    case MinBound

    /// TODO
    case NoBound(T)

    /// TODO
    case MaxBound
    
    public static var min: AddBounds { return .MinBound }
    public static var max: AddBounds { return .MaxBound }
    
    /// TODO
    public init(_ value: T) {
        self = .NoBound(value)
    }
    
    /// TODO
    public func threeWayCompare(to: AddBounds) -> Ordering {
        switch self {
        case .MinBound:
            switch to {
            case .MinBound: return .EQ
            default:        return .LT
            }
        case .MaxBound:
            switch to {
            case .MaxBound: return .EQ
            default:        return .GT
            }
        case let .NoBound(x):
            switch to {
            case     .MaxBound:   return .LT
            case let .NoBound(y): return x.threeWayCompare(y)
            case     .MinBound:   return .GT
            }
        }
    }
    
    /// TODO
    public func map<U>(orderPreservingTransform: T -> U) -> AddBounds<U> {
        switch self {
        case     .MinBound:   return .MinBound
        case let .NoBound(x): return .NoBound(orderPreservingTransform(x))
        case     .MaxBound:   return .MaxBound
        }
    }
}

