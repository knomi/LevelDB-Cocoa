//
//  WriteBatch.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
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
    
    public func enumerate(block: (K, V?) -> ()) {
        ext_leveldb_writebatch_iterate(handle.pointer) {(k: NSData!, v: NSData?) in
            if let key = K.fromSerializedBytes(k!) {
                if let data = v {
                    if let value = V.fromSerializedBytes(data) {
                        block(key, value)
                    } else {
                        NSLog("[WARN] batch contains value that can't be deserialized -- LevelDB.WriteBatch.enumerate")
                    }
                } else {
                    block(key, nil)
                }
            } else {
                NSLog("[WARN] batch contains key that can't be deserialized -- LevelDB.WriteBatch.enumerate")
            }
        }
    }
    
}
