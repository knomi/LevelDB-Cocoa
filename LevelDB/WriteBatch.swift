//
//  WriteBatch.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 26.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

/// TODO
public final class WriteBatch<K : KeyType, V : ValueType> {
    
    public typealias Key = K
    public typealias Value = V
    
    internal let handle: Handle
    
    public init() {
        self.handle = Handle(leveldb_writebatch_create(), leveldb_writebatch_destroy)
    }
    
    public func put(key: Key, _ value: Value) {
        let keyData = key.serializedBytes
        let valueData = value.serializedBytes
        leveldb_writebatch_put(handle.pointer,
                               UnsafePointer<Int8>(keyData.bytes), UInt(keyData.length),
                               UnsafePointer<Int8>(valueData.bytes), UInt(valueData.length))
    }
    
    public func delete(key: Key) {
        let keyData = key.serializedBytes
        leveldb_writebatch_delete(handle.pointer, UnsafePointer<Int8>(keyData.bytes), UInt(keyData.length))
    }
    
    public func clear() {
        leveldb_writebatch_clear(handle.pointer)
    }
    
}
