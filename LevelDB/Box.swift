//
//  Box.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

public final class Box<T> {
    public let unbox: T
    public init(_ value: T) {
        self.unbox = value
    }
}
