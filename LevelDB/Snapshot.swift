//
//  Snapshot.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

// -----------------------------------------------------------------------------
// MARK: - Protocol

public protocol SnapshotType : SequenceType {
    
    /// TODO
    typealias Key : KeyType

    /// TODO
    typealias Value : ValueType

    /// TODO
    typealias Element = (key: Key, value: Value)
    
    /// TODO
    var dataInterval: DataInterval { get }

    /// TODO
    func prefix(#data: NSData) -> Self

    /// TODO
    func prefix(#key: Key) -> Self

    /// TODO
    func bound(dataInterval: DataInterval) -> Self

    /// TODO
    subscript(key: Key) -> Value? { get }

    /// TODO
    subscript(interval: HalfOpenInterval<Key>) -> Self { get }
    
}

// -----------------------------------------------------------------------------
// MARK: - Snapshot

/// TODO
public struct Snapshot<K : KeyType, V : ValueType>  {

    internal typealias Database = LevelDB.Database<K, V>
    public typealias Key = K
    public typealias Value = V

    internal let database: Database
    internal let handle: Handle
    public let dataInterval: DataInterval

    internal init(database: Database,
                  handle: Handle,
                  dataInterval: DataInterval) {
        self.database = database
        self.handle = handle
        self.dataInterval = dataInterval
    }

    internal init(database: Database, dataInterval: DataInterval) {
        self.database = database
        self.handle = Handle(leveldb_create_snapshot(database.handle.pointer)) {pointer in
            leveldb_release_snapshot(database.handle.pointer, pointer)
        }
        self.dataInterval = dataInterval
    }

    /// TODO
    public func cast<K1, V1>() -> Snapshot<K1, V1> {
        return Snapshot<K1, V1>(database: database.cast(), handle: handle, dataInterval: dataInterval)
    }

    /// TODO
    public subscript(key: Key) -> Value? {
        let keyData = key.serializedBytes
        var length: UInt = 0
        let readOptions = Handle(leveldb_readoptions_create(), leveldb_readoptions_destroy)
        leveldb_readoptions_set_snapshot(readOptions.pointer, handle.pointer)
        return tryC {error in
            ext_leveldb_get(self.database.handle.pointer,
                            readOptions.pointer,
                            UnsafePointer<Int8>(keyData.bytes),
                            UInt(keyData.length),
                            error) as NSData?
        }.either({error in
            NSLog("[WARN] %@ -- LevelDB.Database.get", error)
            return nil
        }, {value in
            value.map {data in return Value.fromSerializedBytes(data) }?
        })
    }

    /// TODO
    public func prefix(#data: NSData) -> Snapshot {
        return bound(data ..< data.lexicographicSuccessor())
    }

    /// TODO
    public func prefix(#key: Key) -> Snapshot {
        return prefix(data: key.serializedBytes)
    }

    /// TODO
    public func bound(dataInterval: DataInterval) -> Snapshot {
        let clamped = self.dataInterval.clamp(dataInterval)
        return Snapshot(database: database,
                        handle: handle,
                        dataInterval: clamped)
    }

    /// TODO
    public subscript(interval: HalfOpenInterval<Key>) -> Snapshot {
        return bound(interval.start.serializedBytes ..< interval.end.serializedBytes)
    }
    
    /// TODO
    public var keys: LazySequence<MapSequenceView<Snapshot, K>> {
        return lazy(self).map {(k, _) in k}
    }
    
    /// TODO
    public var values: LazySequence<MapSequenceView<Snapshot, V>> {
        return lazy(self).map {(_, v) in v}
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

// -----------------------------------------------------------------------------
// MARK: - Reverse

public struct ReverseSnapshot<K : KeyType, V : ValueType> {
    
    internal typealias Database = LevelDB.Database<K, V>
    public typealias Key = K
    public typealias Value = V
    public typealias Element = (key: Key, value: Value)

    /// TODO
    public let reverse: Snapshot<Key, Value>
    
    /// TODO
    public var dataInterval: DataInterval {
        return reverse.dataInterval
    }
    
    /// TODO
    public func prefix(#data: NSData) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse.prefix(data: data))
    }

    /// TODO
    public func prefix(#key: Key) -> ReverseSnapshot {
        return prefix(data: key.serializedBytes)
    }

    /// TODO
    public func bound(dataInterval: DataInterval) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse.bound(dataInterval))
    }

    /// TODO
    public subscript(key: Key) -> Value? {
        return reverse[key]
    }

    /// TODO
    public subscript(interval: HalfOpenInterval<Key>) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse[interval])
    }
    
    /// TODO
    public var keys: LazySequence<MapSequenceView<ReverseSnapshot, K>> {
        return lazy(self).map {(k, _) in k}
    }
    
    /// TODO
    public var values: LazySequence<MapSequenceView<ReverseSnapshot, V>> {
        return lazy(self).map {(_, v) in v}
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

// -----------------------------------------------------------------------------
// MARK: - Generators

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
        let start = snapshot.dataInterval.start
        if start.isInfinity {
            leveldb_iter_seek_to_last(handle.pointer)
        } else {
            leveldb_iter_seek_to_first(handle.pointer)
            leveldb_iter_seek(handle.pointer, UnsafePointer<Int8>(start.bytes), UInt(start.length))
        }
    }
    
    /// TODO
    public typealias Element = (key: K, value: V)
    
    /// TODO
    public mutating func next() -> Element? {
        while leveldb_iter_valid(handle.pointer) != 0 {
            let keyData = ext_leveldb_iter_key_unsafe(handle.pointer)
            if keyData.threeWayCompare(snapshot.dataInterval.end) != .LT {
                return nil
            }
            let valueData = ext_leveldb_iter_value_unsafe(handle.pointer)
            var element: Element?
            if let key = K.fromSerializedBytes(keyData) {
                if let value = V.fromSerializedBytes(valueData) {
                    element = (key: key, value: value)
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
        let end = reverse.dataInterval.end
        if end.isInfinity {
            leveldb_iter_seek_to_last(handle.pointer)
        } else {
            leveldb_iter_seek_to_first(handle.pointer)
            leveldb_iter_seek(handle.pointer, UnsafePointer<Int8>(end.bytes), UInt(end.length))
            leveldb_iter_prev(handle.pointer)
        }
    }
    
    /// TODO
    public typealias Element = (key: K, value: V)
    
    /// TODO
    public mutating func next() -> Element? {
        while leveldb_iter_valid(handle.pointer) != 0 {
            let keyData = ext_leveldb_iter_key_unsafe(handle.pointer)
            if keyData.threeWayCompare(reverse.dataInterval.start) == .LT {
                return nil
            }
            let valueData = ext_leveldb_iter_value_unsafe(handle.pointer)
            var element: Element?
            if let key = K.fromSerializedBytes(keyData) {
                if let value = V.fromSerializedBytes(valueData) {
                    element = (key: key, value: value)
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
