//
//  AddBounds.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 28.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

/// TODO
public func nextAfter(data: AddBounds<NSData>) -> AddBounds<NSData> {
    switch data {
    case .MinBound:
        return .NoBound(NSData())
    case let .NoBound(x):
        let copy = x.mutableCopy() as NSMutableData
        let bytes = UnsafeMutableBufferPointer<UInt8>(start: UnsafeMutablePointer<UInt8>(copy.mutableBytes), count: copy.length)
        for i in reverse(indices(bytes)) {
            if bytes[i] < UInt8.max {
                bytes[i]++
                for j in i + 1 ..< bytes.count {
                    bytes[j] = 0
                }
                return .NoBound(copy.copy() as NSData)
            }
        }
        return .MaxBound
    case let .MaxBound:
        return .MaxBound
    }
}

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

