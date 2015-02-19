//
//  WriteBatch.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation
import LevelDB
import protocol Allsorts.Orderable

/// TODO
public struct WriteBatch<K : protocol<ByteSerializable, Orderable>,
                         V : ByteSerializable>
{
    public typealias Key = K
    public typealias Value = V
    
    public let batch: LDBWriteBatch
    
    public init() {
        self.batch = LDBWriteBatch()
    }
    
    public subscript(key: Key) -> Value? {
        get {
            return nil
        }
        set {
            batch[key.serializedBytes] = newValue?.serializedBytes
        }
    }
    
    public func enumerate(block: (K, V?) -> ()) {
        batch.enumerate {k, v in
            if let key = Key.fromSerializedBytes(k) {
                if let data = v {
                    if let value = Value.fromSerializedBytes(data) {
                        block(key, value)
                    } else {
                        // skipped
                    }
                } else {
                    block(key, nil)
                }
            } else {
                // skipped
            }
        }
    }
    
}
