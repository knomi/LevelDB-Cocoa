//
//  SnapshotGenerator.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

// -----------------------------------------------------------------------------
// MARK: - Snapshot implements SequenceType

extension Snapshot : SequenceType {

    /// TODO
    public typealias Generator = SnapshotGenerator<Key, Value>

    /// TODO
    public func generate() -> Generator {
        return Generator(snapshot: self)
    }

}

// -----------------------------------------------------------------------------
// MARK: - SnapshotGenerator

/// TODO
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
