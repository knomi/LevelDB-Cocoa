//
//  Interval.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 27.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

public enum AddBounds<T : ThreeWayComparable> : ThreeWayComparable {
    case MinBound
    case NoBound(T)
    case MaxBound
    
    public init(_ value: T) {
        self = .NoBound(value)
    }
    
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
    
    public func map<U>(orderPreservingTransform: T -> U) -> AddBounds<U> {
        switch self {
        case     .MinBound:   return .MinBound
        case let .NoBound(x): return .NoBound(orderPreservingTransform(x))
        case     .MaxBound:   return .MaxBound
        }
    }
}

public struct RealInterval<T : ThreeWayComparable> : IntervalType {

    public typealias Bound = T

    public let closedStart: Bool
    public let closedEnd: Bool
    public let start: T
    public let end: T
    
    private init(_ closedStart: Bool,
                 _ closedEnd: Bool,
                 _ start: T,
                 _ end: T)
    {
        precondition(start <= end)
        self.closedStart = closedStart
        self.closedEnd   = closedEnd
        self.start       = start
        self.end         = end
    }
    
    public init(_ interval: ClosedInterval<T>) {
        self.closedStart = true
        self.closedEnd = true
        self.start = interval.start
        self.end = interval.end
    }
    
    public init(_ interval: HalfOpenInterval<T>) {
        self.closedStart = true
        self.closedEnd = false
        self.start = interval.start
        self.end = interval.end
    }
    
    public func contains(value: Bound) -> Bool {
        switch start.threeWayCompare(value) {
        case .GT: return false
        case .EQ: if !closedStart { return false }
        case .LT: break
        }
        switch value.threeWayCompare(end) {
        case .LT: return true
        case .EQ: return closedEnd
        case .GT: return false
        }
    }
    
    public func clamp(intervalToClamp: RealInterval) -> RealInterval {
        var a = intervalToClamp.start
        var b = intervalToClamp.end
        var ca = intervalToClamp.closedStart
        var cb = intervalToClamp.closedEnd
        switch start.threeWayCompare(a) {
        case .LT: break
        case .EQ: ca = closedStart && ca
        case .GT: (a, ca) = (start, closedStart)
        }
        switch b.threeWayCompare(end) {
        case .LT: break
        case .EQ: cb = closedEnd && cb
        case .GT: (b, cb) = (end, closedEnd)
        }
        switch a.threeWayCompare(b) {
        case .GT: return RealInterval(false, false, start, start)
        default:  return RealInterval(ca, cb, a, b)
        }
    }
    
    public var isEmpty: Bool {
        let hasInterior = start < end || closedStart && closedEnd
        return !hasInterior
    }
    
    public func map<U>(orderPreservingTransform: T -> U) -> RealInterval<U> {
        return RealInterval<U>(closedStart,
                               closedEnd,
                               orderPreservingTransform(start),
                               orderPreservingTransform(end))
    }
}
