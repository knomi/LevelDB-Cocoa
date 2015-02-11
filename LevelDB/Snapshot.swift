//
//  Snapshot.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

// -----------------------------------------------------------------------------
// MARK: - Snapshot

/// TODO
public struct Snapshot<K : KeyType, V : ValueType> {

    internal typealias Database = LevelDB.Database<K, V>
    public typealias Key = K
    public typealias Value = V

    internal let database: Database
    internal let handle: Handle
    internal let readOptions: Handle
    public let dataInterval: HalfOpenInterval<NSData>

    internal init(database: Database,
                  handle: Handle,
                  readOptions: Handle,
                  dataInterval: HalfOpenInterval<NSData>)
    {
        self.database = database
        self.handle = handle
        self.readOptions = readOptions
        self.dataInterval = dataInterval
    }

    internal init(database: Database,
                  dataInterval: HalfOpenInterval<NSData>)
    {
        let handle = Handle(leveldb_create_snapshot(database.handle.pointer)) {pointer in
            leveldb_release_snapshot(database.handle.pointer, pointer)
        }
        let readOptions = Handle(leveldb_readoptions_create(), leveldb_readoptions_destroy)
        leveldb_readoptions_set_snapshot(readOptions.pointer, handle.pointer)
        self.init(database: database,
                  handle: handle,
                  readOptions: readOptions,
                  dataInterval: dataInterval)
    }

    /// TODO
    public func cast<K1, V1>() -> Snapshot<K1, V1> {
        return Snapshot<K1, V1>(database: database.cast(),
                                handle: handle,
                                readOptions: readOptions,
                                dataInterval: dataInterval)
    }
    
    /// TODO
    public func keepingCache<T>(block: Snapshot -> T) -> T
    {
        let customOptions = Handle(leveldb_readoptions_create(), leveldb_readoptions_destroy)
        leveldb_readoptions_set_snapshot(customOptions.pointer, handle.pointer)
        leveldb_readoptions_set_fill_cache(customOptions.pointer, 0)
        return block(Snapshot(database: database,
                              handle: handle,
                              readOptions: customOptions,
                              dataInterval: dataInterval))
    }

    /// TODO
    public func verifyingChecksums<T>(block: Snapshot -> T) -> T
    {
        let customOptions = Handle(leveldb_readoptions_create(), leveldb_readoptions_destroy)
        leveldb_readoptions_set_snapshot(customOptions.pointer, handle.pointer)
        leveldb_readoptions_set_verify_checksums(customOptions.pointer, 1)
        return block(Snapshot(database: database,
                              handle: handle,
                              readOptions: customOptions,
                              dataInterval: dataInterval))
    }

    /// TODO
    public subscript(key: Key) -> Value? {
        let keyData = key.serializedBytes
        var length: UInt = 0
        return tryC {error in
            ext_leveldb_get(self.database.handle.pointer,
                            self.readOptions.pointer,
                            UnsafePointer<Int8>(keyData.bytes),
                            UInt(keyData.length),
                            error) as NSData?
        }.either({error in
            NSLog("[WARN] %@ -- LevelDB.Database.get", error)
            return nil
        }, {value in
            if let data = value {
                return Value.fromSerializedBytes(data)
            } else {
                return nil
            }
        })
    }

    /// TODO
    private func clamp(dataInterval: HalfOpenInterval<NSData>) -> Snapshot {
        let clamped = self.dataInterval.clamp(dataInterval)
        return Snapshot(database: database,
                        handle: handle,
                        readOptions: readOptions,
                        dataInterval: clamped)
    }

    /// TODO
    public func clamp(#from: Key?, to: Key?) -> Snapshot {
        let start = from?.serializedBytes ?? dataInterval.start
        let end = to?.serializedBytes ?? dataInterval.end
        return clamp(start ..< end)
    }

    /// TODO
    public func clamp(#from: Key?, through: Key?) -> Snapshot {
        let start = from?.serializedBytes ?? dataInterval.start
        let end = through?.serializedBytes.lexicographicFirstChild() ?? dataInterval.end
        return clamp(start ..< end)
    }

    /// TODO
    public func after(key: Key) -> Snapshot {
        let start = key.serializedBytes.lexicographicFirstChild()
        return clamp(start ..< dataInterval.end)
    }

    /// TODO
    public func prefix(key: Key) -> Snapshot {
        let data = key.serializedBytes
        return clamp(data ..< data.lexicographicNextSibling())
    }

    /// TODO
    public subscript(interval: HalfOpenInterval<Key>) -> Snapshot {
        return clamp(from: interval.start, to: interval.end)
    }
    
    /// TODO
    public subscript(interval: ClosedInterval<Key>) -> Snapshot {
        return clamp(from: interval.start, through: interval.end)
    }
    
}

//extension Snapshot : SnapshotType {}

public struct SnapshotGenerator<K : KeyType, V : ValueType> : GeneratorType {

    private let snapshot: Snapshot<K, V>
    private let handle: Handle
    
    internal init(snapshot: Snapshot<K, V>) {
        self.snapshot = snapshot
        let db = snapshot.database
        self.handle = Handle(
            leveldb_create_iterator(db.handle.pointer, snapshot.readOptions.pointer),
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

extension Snapshot : SequenceType {

    /// TODO
    public typealias Generator = SnapshotGenerator<Key, Value>

    /// TODO
    public func generate() -> Generator {
        return Generator(snapshot: self)
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

public struct ReverseSnapshot<K : KeyType, V : ValueType> {
    
    internal typealias Database = LevelDB.Database<K, V>
    public typealias Key = K
    public typealias Value = V
    public typealias Element = (key: Key, value: Value)
    
    /// TODO
    public let reverse: Snapshot<Key, Value>
    
    /// TODO
    public var dataInterval: HalfOpenInterval<NSData> {
        return reverse.dataInterval
    }

    /// TODO
    public func clamp(#from: Key?, to: Key?) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse.clamp(from: from, to: to))
    }

    /// TODO
    public func clamp(#from: Key?, through: Key?) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse.clamp(from: from, through: through))
    }
    
    /// TODO
    public func after(key: Key) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse.after(key))
    }
    
    /// TODO
    public func prefix(key: Key) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse.prefix(key))
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
    public subscript(interval: ClosedInterval<Key>) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse[interval])
    }
    
}

//extension ReverseSnapshot : SnapshotType {}

public extension Snapshot {

    /// TODO
    public var reverse: ReverseSnapshot<Key, Value> {
        return ReverseSnapshot(reverse: self)
    }

}

/// TODO
public struct ReverseSnapshotGenerator<K : KeyType, V : ValueType> : GeneratorType {

    private let reverse: Snapshot<K, V>
    private let handle: Handle
    
    internal init(reverse: Snapshot<K, V>) {
        self.reverse = reverse
        let db = reverse.database
        self.handle = Handle(
            leveldb_create_iterator(db.handle.pointer, reverse.readOptions.pointer),
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

extension ReverseSnapshot : SequenceType {
    
    /// TODO
    public typealias Generator = ReverseSnapshotGenerator<Key, Value>
    
    /// TODO
    public func generate() -> Generator {
        return ReverseSnapshotGenerator(reverse: reverse)
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

extension Snapshot : SnapshotType {}
