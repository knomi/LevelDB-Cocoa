//
//  Database.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

private var inMemoryCounter: Int32 = 0

/// TODO
public final class Database<K : KeyType, V : ValueType> {

// -----------------------------------------------------------------------------
// MARK: Types

    /// TODO
    public typealias Key = K

    /// TODO
    public typealias Value = V

// -----------------------------------------------------------------------------
// MARK: Data

    internal let handle: Handle
    internal let readOptions = Handle(leveldb_readoptions_create(), leveldb_readoptions_destroy)
    internal let writeOptions = Handle(leveldb_writeoptions_create(), leveldb_writeoptions_destroy)
    
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
        switch Database.openHandle(directoryPath) {
        case let .Error(e):
            // TODO: Log the error?
            self.init(handle: Handle())
            return nil
        case let .Value(handle):
            self.init(handle: handle.unbox)
        }
    }
    
    /// TODO
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
    public class func open(directoryPath: String) -> Either<String, Database> {
        return openHandle(directoryPath).map {handle in
            Database(handle: handle)
        }
    }
    
// -----------------------------------------------------------------------------
// MARK: Database access

    /// TODO
    public func cast<K1, V1>() -> Database<K1, V1> {
        return Database<K1, V1>(handle: handle)
    }

    /// TODO
    public func snapshot() -> Snapshot<K, V> {
        return Snapshot(database: self, dataInterval: NSData() ..< NSData.infinity)
    }
    
    /// TODO
    public func write(batch: WriteBatch<K, V>) -> Either<String, ()> {
        return tryC {error in
            leveldb_write(self.handle.pointer,
                          self.writeOptions.pointer,
                          batch.handle.pointer,
                          error)
        }
    }
    
    /// TODO
    public subscript(key: Key) -> Value? {
        get {
            return get(key).either({error in
                NSLog("[WARN] %@ -- LevelDB.Database.get", error)
                return nil
            }, {value in
                value
            })
        }
        set {
            if let value = newValue {
                return put(key, value).either({error in
                    NSLog("[WARN] %@ -- LevelDB.Database.put", error)
                }, {_ in
                    ()
                })
            } else { // delete
                return delete(key).either({error in
                    NSLog("[WARN] %@ -- LevelDB.Database.delete", error)
                }, {_ in
                    ()
                })
            }
        }
    }
    
    /// TODO
    public func get(key: Key) -> Either<String, Value?> {
        let keyData = key.serializedBytes
        var length: UInt = 0
        return tryC {error in
            ext_leveldb_get(self.handle.pointer,
                            self.readOptions.pointer,
                            UnsafePointer<Int8>(keyData.bytes),
                            UInt(keyData.length),
                            error) as NSData?
        }.map {value in
            value.map {data in return Value.fromSerializedBytes(data) }?
        }
    }
    
    /// TODO
    public func put(key: Key, _ value: Value) -> Either<String, ()> {
        let keyData = key.serializedBytes
        let valueData = value.serializedBytes
        return tryC {error in
            leveldb_put(self.handle.pointer,
                        self.writeOptions.pointer,
                        UnsafePointer<Int8>(keyData.bytes),
                        UInt(keyData.length),
                        UnsafePointer<Int8>(valueData.bytes),
                        UInt(valueData.length),
                        error)
        }
    }
    
    /// TODO
    public func delete(key: Key) -> Either<String, ()> {
        let keyData = key.serializedBytes
        return tryC {error in
            leveldb_delete(self.handle.pointer,
                           self.writeOptions.pointer,
                           UnsafePointer<Int8>(keyData.bytes),
                           UInt(keyData.length),
                           error)
        }
    }
}
