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
public final class DatabaseBy<C : ComparatorType> {

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

    private var handle: Handle
    
// -----------------------------------------------------------------------------
// MARK: Initialization
    
    private init(handle: Handle) {
        self.handle = handle
    }
    
    /// TODO (in-memory database)
    public convenience init() {
        let defaultEnv = leveldb_create_default_env()
        let memoryEnv = ext_leveldb_create_in_memory_env(defaultEnv)
        let options = Handle(leveldb_options_create(), leveldb_options_destroy)
        leveldb_options_set_create_if_missing(options.pointer, 1)
        leveldb_options_set_env(options.pointer, memoryEnv)
        let name = "in-memory-\(OSAtomicIncrement32(&inMemoryCounter))"
        switch tryC({error in leveldb_open(options.pointer, name, error)}) {
        case let .Error(e):
            fatalError(e.unbox)
        case let .Value(x):
            let ptr = x.unbox
            self.init(handle: Handle(ptr) {db in
                leveldb_close(db)
                leveldb_env_destroy(memoryEnv)
                leveldb_env_destroy(defaultEnv)
            })
        }
    }
    
    /// TODO
    public convenience init?(_ directoryPath: String) {
        switch DatabaseBy.openHandle(directoryPath) {
        case let .Error(e):
            // TODO: Log the error?
            self.init(handle: Handle())
            return nil
        case let .Value(handle):
            self.init(handle: handle.unbox)
        }
    }
    
    private class func openHandle(directoryPath: String) -> Either<String, Handle> {
        let options = Handle(leveldb_options_create(), leveldb_options_destroy)
        leveldb_options_set_create_if_missing(options.pointer, 1)
        let name = (directoryPath as NSString).UTF8String
        return tryC({error in
            leveldb_open(options.pointer, name, error)
        }).map {pointer in
            Handle(pointer, leveldb_close)
        }
    }
    
    /// TODO
    public class func open(directoryPath: String) -> Either<String, DatabaseBy> {
        return openHandle(directoryPath).map {handle in
            DatabaseBy(handle: handle)
        }
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
