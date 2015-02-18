//
//  SnapshotType.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

/// TODO
public typealias KeyType = protocol<ByteSerializable, Comparable>

/// TODO
public typealias ValueType = ByteSerializable

/// TODO
public protocol SnapshotType : SequenceType {
    
    /// TODO
    typealias Key : KeyType

    /// TODO
    typealias Value : ValueType

    /// TODO
    typealias Element = (key: Key, value: Value)
    
//    /// TODO
//    var dataInterval: HalfOpenInterval<NSData> { get }

    /// TODO
    func clamp(#from: Key?, to: Key?) -> Self

    /// TODO
    func clamp(#from: Key?, through: Key?) -> Self
    
    /// TODO
    func after(key: Key) -> Self

    /// TODO
    func prefix(key: Key) -> Self

    /// TODO
    subscript(key: Key) -> Value? { get }
    
    /// TODO
    subscript(interval: HalfOpenInterval<Key>) -> Self { get }
    
    /// TODO
    subscript(interval: ClosedInterval<Key>) -> Self { get }
}
