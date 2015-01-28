//
//  Snapshot.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 26.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

public protocol SnapshotType : SequenceType {
    
    typealias Key : KeyType
    typealias Value : ValueType
    typealias Element = (Key, Value)
    
    var interval: RealInterval<AddBounds<Key>> { get }

    subscript(key: Key) -> Value? { get }
    subscript(interval: ClosedInterval<Key>) -> Self { get }
    subscript(interval: HalfOpenInterval<Key>) -> Self { get }
    
}

/// TODO
public struct Snapshot<K : KeyType, V : ValueType>  {

    internal typealias Database = LevelDB.Database<K, V>
    public typealias Key = K
    public typealias Value = V
    public typealias Element = (Key, Value)

    internal let database: Database
    internal let handle: Handle

    /// TODO
    public let interval: RealInterval<AddBounds<Key>>
    
    internal init(database: Database,
                  handle: Handle,
                  interval: RealInterval<AddBounds<Key>>) {
        self.database = database
        self.handle = handle
        self.interval = interval
    }

    internal init(database: Database, interval: RealInterval<AddBounds<K>>) {
        self.database = database
        self.handle = Handle(leveldb_create_snapshot(database.handle.pointer)) {pointer in
            leveldb_release_snapshot(database.handle.pointer, pointer)
        }
        self.interval = interval
    }

    /// TODO
    public subscript(key: Key) -> Value? {
        let keyData = key.serializedBytes
        var length: UInt = 0
        let readOptions = Handle(leveldb_readoptions_create(), leveldb_readoptions_destroy)
        leveldb_readoptions_set_snapshot(readOptions.pointer, handle.pointer)
        return tryC {error in
            ext_leveldb_get(self.handle.pointer,
                            readOptions.pointer,
                            UnsafePointer<Int8>(keyData.bytes),
                            UInt(keyData.length),
                            error) as NSData?
        }.either({error in
            NSLog("[WARN] %@ -- LevelDB.Database.get", error)
            return nil
        }, {value in
            value.flatMap {data in return Value.fromSerializedBytes(data) }
        })
    }

    /// TODO
    public subscript(interval: ClosedInterval<Key>) -> Snapshot {
        let capped = AddBounds(interval.start) ... AddBounds(interval.end)
        let clamped = self.interval.clamp(RealInterval(capped))
        return Snapshot(database: database,
                        handle: handle,
                        interval: clamped)
    }
    
    /// TODO
    public subscript(interval: HalfOpenInterval<Key>) -> Snapshot {
        let capped = AddBounds(interval.start) ..< AddBounds(interval.end)
        let clamped = self.interval.clamp(RealInterval(capped))
        return Snapshot(database: database,
                        handle: handle,
                        interval: clamped)
    }
    
}

extension Snapshot : SequenceType {

    /// TODO
    public typealias Generator = SnapshotGenerator<Key, Value>

    /// TODO
    public func generate() -> Generator {
        return Generator(snapshot: self)
    }

}

extension Snapshot {

    /// TODO
    public var reverse: ReverseSnapshot<Key, Value> {
        return ReverseSnapshot(reverse: self)
    }

}

extension Snapshot : SnapshotType {}

public struct ReverseSnapshot<K : KeyType, V : ValueType> {
    
    internal typealias Database = LevelDB.Database<K, V>
    public typealias Key = K
    public typealias Value = V
    public typealias Element = (Key, Value)

    /// TODO
    public let reverse: Snapshot<Key, Value>
    
    /// TODO
    public var interval: RealInterval<AddBounds<Key>> {
        return reverse.interval
    }
    
    /// TODO
    public subscript(key: Key) -> Value? {
        return reverse[key]
    }

    /// TODO
    public subscript(interval: ClosedInterval<Key>) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse[interval])
    }
    
    /// TODO
    public subscript(interval: HalfOpenInterval<Key>) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse[interval])
    }
    
}

extension ReverseSnapshot : SequenceType {
    
    /// TODO
    public typealias Generator = ReverseSnapshotGenerator<Key, Value>
    
    /// TODO
    public func generate() -> Generator {
        return ReverseSnapshotGenerator(reverse: reverse)
    }
    
}

extension ReverseSnapshot : SnapshotType {}

//extension Snapshot : CollectionType {
//
//    public typealias Index = SnapshotIndex<Key, Value>
//
//    public var startIndex: Index {
//        return undefined()
//    }
//
//    public var endIndex: Index {
//        return undefined()
//    }
//
//    public subscript(index: Index) -> Element {
//        return undefined()
//    }
//    
//}

// -----------------------------------------------------------------------------
// MARK: Generator

/// TODO
public struct SnapshotGenerator<K : KeyType, V : ValueType> : GeneratorType {

    private let snapshot: Snapshot<K, V>
    private let handle: Handle
    
    internal init(snapshot: Snapshot<K, V>) {
        self.snapshot = snapshot
        let db = snapshot.database
        let readOptions = Handle(leveldb_readoptions_create(), leveldb_readoptions_destroy)
        leveldb_readoptions_set_snapshot(readOptions.pointer, snapshot.handle.pointer)
        self.handle = Handle(
            leveldb_create_iterator(db.handle.pointer, readOptions.pointer),
            leveldb_iter_destroy)
        switch snapshot.interval.start {
        case .MinBound:
            leveldb_iter_seek_to_first(handle.pointer)
        case let .NoBound(start):
            let data = start.serializedBytes
            leveldb_iter_seek(handle.pointer, UnsafePointer<Int8>(data.bytes), UInt(data.length))
            if !snapshot.interval.closedStart {
                let keyData = ext_leveldb_iter_key_unsafe(handle.pointer)
                if let key = K.fromSerializedBytes(keyData) {
                    // skip over the open start of interval
                    switch start.threeWayCompare(key) {
                    case .LT: break
                    case .EQ: leveldb_iter_next(handle.pointer)
                    case .GT: assert(false, "Found key beyond the limited interval: \(keyData)")
                    }
                }
            }
        case .MaxBound:
            // just leave the iterator in its initial invalid state so the iteration will stop
            assert(leveldb_iter_valid(handle.pointer) == 0)
        }
    }
    
    /// TODO
    public typealias Element = (K, V)
    
    /// TODO
    public mutating func next() -> Element? {
        while leveldb_iter_valid(handle.pointer) != 0 {
            let keyData = ext_leveldb_iter_key_unsafe(handle.pointer)
            let valueData = ext_leveldb_iter_value_unsafe(handle.pointer)
            var element: Element?
            if let key = K.fromSerializedBytes(keyData) {
                if !snapshot.interval.contains(AddBounds(key)) {
                    return nil
                }
                if let value = V.fromSerializedBytes(valueData) {
                    element = (key, value)
                }
            }
            leveldb_iter_next(handle.pointer)
            if element != nil {
                return element
            }
        }
        return nil
    }
}

public struct ReverseSnapshotGenerator<K : KeyType, V : ValueType> : GeneratorType {

    private let reverse: Snapshot<K, V>
    private let handle: Handle
    
    internal init(reverse: Snapshot<K, V>) {
        self.reverse = reverse
        let db = reverse.database
        let readOptions = Handle(leveldb_readoptions_create(), leveldb_readoptions_destroy)
        leveldb_readoptions_set_snapshot(readOptions.pointer, reverse.handle.pointer)
        self.handle = Handle(
            leveldb_create_iterator(db.handle.pointer, readOptions.pointer),
            leveldb_iter_destroy)
        switch reverse.interval.end {
        case .MaxBound:
            leveldb_iter_seek_to_last(handle.pointer)
        case let .NoBound(end):
            let data = end.serializedBytes
            leveldb_iter_seek(handle.pointer, UnsafePointer<Int8>(data.bytes), UInt(data.length))
            if !reverse.interval.closedEnd {
                let keyData = ext_leveldb_iter_key_unsafe(handle.pointer)
                if let key = K.fromSerializedBytes(keyData) {
                    // skip over the open end of interval
                    switch end.threeWayCompare(key) {
                    case .GT: break
                    case .EQ: leveldb_iter_prev(handle.pointer)
                    case .LT: assert(false, "Found key beyond the limited interval: \(keyData)")
                    }
                }
            }
        case .MinBound:
            // just leave the iterator in its initial invalid state so the iteration will stop
            assert(leveldb_iter_valid(handle.pointer) == 0)
        }
    }
    
    /// TODO
    public typealias Element = (K, V)
    
    /// TODO
    public mutating func next() -> Element? {
        while leveldb_iter_valid(handle.pointer) != 0 {
            let keyData = ext_leveldb_iter_key_unsafe(handle.pointer)
            let valueData = ext_leveldb_iter_value_unsafe(handle.pointer)
            var element: Element?
            if let key = K.fromSerializedBytes(keyData) {
                if !reverse.interval.contains(AddBounds(key)) {
                    return nil
                }
                if let value = V.fromSerializedBytes(valueData) {
                    element = (key, value)
                }
            }
            leveldb_iter_prev(handle.pointer)
            if element != nil {
                return element
            }
        }
        return nil
    }
}

// -----------------------------------------------------------------------------
// MARK: Index

//public struct SnapshotIndex<K : KeyType, V : ValueType> {
//    
//    private var key: AddBounds<K>
//    
//    
//    
//    public func successor() -> SnapshotIndex {
//        return undefined()
//    }
//    
//    public func predecessor() -> SnapshotIndex {
//        return undefined()
//    }
//    
//}
//
//extension SnapshotIndex : ThreeWayComparable {
//    public func threeWayCompare(to: SnapshotIndex) -> Ordering {
//        return key.threeWayCompare(to.key)
//    }
//}
//
//extension SnapshotIndex : BidirectionalIndexType {}
