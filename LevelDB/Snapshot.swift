//
//  Snapshot.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

// -----------------------------------------------------------------------------
// MARK: - Database snapshot

extension Database {

    /// TODO
    public typealias Snapshot = LevelDB.Snapshot<Key, Value>
    
    /// TODO
    public func snapshot() -> Snapshot {
        return Snapshot(database: self, dataInterval: NSData() ..< NSData.infinity)
    }
    
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
    
    /// TODO
    public var keys: LazySequence<MapSequenceView<Snapshot, K>> {
        return lazy(self).map {(k, _) in k}
    }
    
    /// TODO
    public var values: LazySequence<MapSequenceView<Snapshot, V>> {
        return lazy(self).map {(_, v) in v}
    }
    
}

extension Snapshot : SnapshotType {}
