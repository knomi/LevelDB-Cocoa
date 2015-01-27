//
//  Box.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 27.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

public final class Box<T> {
    public let unbox: T
    public init(_ value: T) {
        self.unbox = value
    }
}
