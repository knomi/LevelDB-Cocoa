//
//  ComparatorType.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 26.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

/// TODO
public protocol ComparatorType {

    /// TODO
    typealias Key : ByteSerializable
    
    /// TODO
    typealias Value : ByteSerializable
    
    /// TODO
    typealias Reverse /* : ComparatorType */ = Reversed<Self>

    /// TODO
    class var name: StaticString { get }

    /// TODO
    class func compare(left: Key, _ right: Key) -> Ordering

}

/// TODO
public struct Reversed<C : ComparatorType> : ComparatorType {
    
    public typealias Key = C.Key
    
    public typealias Value = C.Value
    
    public typealias Reverse = C
    
    public static var name: StaticString { return "" }
    
    /// TODO
    public static func compare(left: Key, _ right: Key) -> Ordering {
        return C.compare(right, left)
    }

}
