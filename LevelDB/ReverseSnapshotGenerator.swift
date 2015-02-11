//
//  ReverseSnapshotGenerator.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

// -----------------------------------------------------------------------------
// MARK: - ReverseSnapshot implements SequenceType

extension ReverseSnapshot : SequenceType {
    
    /// TODO
    public typealias Generator = ReverseSnapshotGenerator<Key, Value>
    
    /// TODO
    public func generate() -> Generator {
        return ReverseSnapshotGenerator(reverse: reverse)
    }
    
}

// -----------------------------------------------------------------------------
// MARK: - ReverseSnapshotGenerator

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
