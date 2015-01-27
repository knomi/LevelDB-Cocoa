//
//  Either.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 27.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
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
}

internal func tryCall<R, A>(f: (A, UnsafeMutablePointer<UnsafeMutablePointer<Int8>>) -> R, a: A) -> Either<String, R> {
    var error = UnsafeMutablePointer<Int8>.null()
    let r = f(a, &error)
    if error != nil {
        let string = String.fromCString(error)!
        leveldb_free(error)
        return .error(string)
    } else {
        return .value(r)
    }
}

internal func tryCall<R, A, B>(f: (A, B, UnsafeMutablePointer<UnsafeMutablePointer<Int8>>) -> R, a: A, b: B) -> Either<String, R> {
    var error = UnsafeMutablePointer<Int8>.null()
    let r = f(a, b, &error)
    if error != nil {
        let string = String.fromCString(error)!
        leveldb_free(error)
        return .error(string)
    } else {
        return .value(r)
    }
}

internal func tryCall<R, A, B, C>(f: (A, B, C, UnsafeMutablePointer<UnsafeMutablePointer<Int8>>) -> R, a: A, b: B, c: C) -> Either<String, R> {
    var error = UnsafeMutablePointer<Int8>.null()
    let r = f(a, b, c, &error)
    if error != nil {
        let string = String.fromCString(error)!
        leveldb_free(error)
        return .error(string)
    } else {
        return .value(r)
    }
}
