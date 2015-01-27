//
//  Database.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 26.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

private var inMemoryCounter: Int32 = 0

/// TODO
public final class DatabaseBy<C : ComparatorType where C.Reverse : ComparatorType> {

// -----------------------------------------------------------------------------
// MARK: Types

    /// TODO
    public typealias Comparator = C

    /// TODO
    public typealias Key = C.Key

    /// TODO
    public typealias Value = C.Value
    
// -----------------------------------------------------------------------------
// MARK: Data

    private let db: Handle
    
// -----------------------------------------------------------------------------
// MARK: Initialization
    
    private init(db: Handle) {
        self.db = db
    }
    
    /// TODO (in-memory database)
    public convenience init() {
        let defaultEnv = leveldb_create_default_env()
        let memoryEnv = ext_leveldb_create_in_memory_env(defaultEnv)
        let options = leveldb_options_create()
        leveldb_options_set_env(options, memoryEnv)
        let name = "in-memory-\(OSAtomicIncrement32(&inMemoryCounter))"
        switch tryCall(leveldb_open, options, name) {
        default:
//        case let .Error(e):
//            fatalError(e.unbox)
            self.init(db: Handle(nil, {_ in}))
//        case let .Value(x):
//            let db = x.unbox
//            self.init(db: Handle(db) {db in
//                leveldb_close(db)
//                leveldb_env_destroy(memoryEnv)
//                leveldb_env_destroy(defaultEnv)
//            })
        }
    }
    
    /// TODO
    public convenience init?(_ directoryPath: String) {
        fatalError("unimplemented")
    }
    
    /// TODO
    public class func open(directoryPath: String) -> Either<String, DatabaseBy> {
        return undefined()
    }
    
// -----------------------------------------------------------------------------
// MARK: Database access

    /// TODO
    public var snapshot: SnapshotBy<Comparator> {
        return undefined()
    }
    
    /// TODO
    public func write(block: WriteBatchBy<Comparator> -> ()) {
        return undefined()
    }
    
    /// TODO
    public subscript(key: Key) -> Value? {
        get {
            return undefined()
        }
        set {
            if let value = newValue {
                // put
                return undefined()
            } else {
                // delete
                return undefined()
            }
        }
    }
    
    /// TODO
    public func get(key: Key) -> Either<String, Value> {
        return undefined()
    }
    
    /// TODO
    public func put(key: Key, value: Value) -> Either<String, ()> {
        return undefined()
    }
    
    /// TODO
    public func delete(key: Key) -> Either<String, ()> {
        return undefined()
    }
}
