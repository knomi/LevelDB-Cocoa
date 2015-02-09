//
//  Either.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

public enum Either<E, A> {
    case Error(Box<E>)
    case Value(Box<A>)
    
    public static func error(e: E) -> Either {
        return .Error(Box(e))
    }

    public static func value(a: A) -> Either {
        return .Value(Box(a))
    }

    public var justError: E? {
        switch self {
        case let .Error(e): return e.unbox
        case     .Value:    return nil
        }
    }

    public var justValue: A? {
        switch self {
        case let .Value(a): return a.unbox
        case     .Error:    return nil
        }
    }
    
    public func map<T>(transform: A -> T) -> Either<E, T> {
        switch self {
        case let .Error(e): return .Error(e)
        case let .Value(a): return .Value(Box(transform(a.unbox)))
        }
    }
    
    public func flatMap<T>(transform: A -> Either<E, T>) -> Either<E, T> {
        switch self {
        case let .Error(e): return .Error(e)
        case let .Value(a): return transform(a.unbox)
        }
    }
    
    public func either<T>(error: E -> T, _ value: A -> T) -> T {
        switch self {
        case let .Error(e): return error(e.unbox)
        case let .Value(a): return value(a.unbox)
        }
    }
}
