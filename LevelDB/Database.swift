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
    
    /// TODO
    public typealias Element = (key: Key, value: Value)
    
    /// TODO
    public typealias Snapshot = LevelDB.Snapshot<Key, Value>
    
    /// TODO
    public typealias WriteBatch = LevelDB.WriteBatch<Key, Value>

// -----------------------------------------------------------------------------
// MARK: Data

    internal let handle: Handle
    internal let readOptions = Handle(leveldb_readoptions_create(), leveldb_readoptions_destroy)
    internal let asyncWriteOptions = Handle(leveldb_writeoptions_create(), leveldb_writeoptions_destroy)
    internal let syncWriteOptions: Handle = {() -> Handle in
        let handle = Handle(leveldb_writeoptions_create(), leveldb_writeoptions_destroy)
        leveldb_writeoptions_set_sync(handle.pointer, 1)
        return handle
    }()
    
// -----------------------------------------------------------------------------
// MARK: Initialization
    
    private init(handle: Handle) {
        self.handle = handle
    }
    
    /// TODO (in-memory database)
    public convenience init() {
        var defaultEnv = Handle(leveldb_create_default_env(), leveldb_env_destroy)
        var memoryEnv = Handle(ext_leveldb_create_in_memory_env(defaultEnv.pointer), leveldb_env_destroy)
        let options = Handle(leveldb_options_create(), leveldb_options_destroy)
        leveldb_options_set_create_if_missing(options.pointer, 1)
        leveldb_options_set_env(options.pointer, memoryEnv.pointer)
        let name = "in-memory-\(OSAtomicIncrement32(&inMemoryCounter))"
        switch tryC({error in leveldb_open(options.pointer, name, error)}) {
        case let .Error(e):
            fatalError(e.unbox)
        case let .Value(x):
            let ptr = x.unbox
            self.init(handle: Handle(ptr) {db in
                leveldb_close(db)
                memoryEnv = Handle()
                defaultEnv = Handle()
            })
        }
    }
    
    /// TODO
    public class func open(directoryPath:   String,
                           createIfMissing: Bool = false,
                           errorIfExists:   Bool = false,
                           paranoidChecks:  Bool = false,
                           maxOpenFiles:    Int  = 1000,
                           bloomFilterBits: Int  = 0,
                           cacheCapacity:   Int  = 0)
        -> Either<String, Database>
    {
        return openHandle(directoryPath,
                          createIfMissing: createIfMissing,
                          errorIfExists:   errorIfExists,
                          paranoidChecks:  paranoidChecks,
                          maxOpenFiles:    maxOpenFiles,
                          bloomFilterBits: bloomFilterBits,
                          cacheCapacity:   cacheCapacity)
        .map {handle in
            Database(handle: handle)
        }
    }
    
    /// TODO
    public convenience init?(_ directoryPath: String) {
        switch Database.open(directoryPath, createIfMissing: true, bloomFilterBits: 10) {
        case let .Error(e):
            NSLog("[WARN] %@ -- LevelDB.Database.init", e.unbox)
            self.init(handle: Handle())
            return nil
        case let .Value(db):
            self.init(handle: db.unbox.handle)
        }
    }
    
    /// TODO
    private class func openHandle(directoryPath:   String,
                                  createIfMissing: Bool,
                                  errorIfExists:   Bool,
                                  paranoidChecks:  Bool,
                                  maxOpenFiles:    Int,
                                  bloomFilterBits: Int,
                                  cacheCapacity:   Int)
        -> Either<String, Handle>
    {
        let options = Handle(leveldb_options_create(), leveldb_options_destroy)
        leveldb_options_set_create_if_missing(options.pointer, createIfMissing ? 1 : 0)
        leveldb_options_set_error_if_exists  (options.pointer, errorIfExists ? 1 : 0)
        leveldb_options_set_paranoid_checks  (options.pointer, paranoidChecks ? 1 : 0)
        leveldb_options_set_max_open_files   (options.pointer, Int32(maxOpenFiles))
        var bloomFilter = Handle()
        if bloomFilterBits > 0 {
            bloomFilter = Handle(leveldb_filterpolicy_create_bloom(Int32(bloomFilterBits)), leveldb_filterpolicy_destroy)
            leveldb_options_set_filter_policy(options.pointer, bloomFilter.pointer)
        }
        var cache = Handle()
        if cacheCapacity > 0 {
            cache = Handle(leveldb_cache_create_lru(UInt(cacheCapacity)), leveldb_cache_destroy)
            leveldb_options_set_cache(options.pointer, cache.pointer)
        }
        let name = (directoryPath as NSString).UTF8String
        return tryC({error in
            leveldb_open(options.pointer, name, error)
        }).map {pointer in
            Handle(pointer) {pointer in
                leveldb_close(pointer)
                cache = Handle()
                bloomFilter = Handle()
            }
        }
    }
    
// -----------------------------------------------------------------------------
// MARK: Database access

    /// TODO
    public func cast<K1, V1>() -> Database<K1, V1> {
        return Database<K1, V1>(handle: handle)
    }

    /// TODO
    public func snapshot() -> Snapshot {
        return Snapshot(database: self, dataInterval: NSData() ..< NSData.infinity)
    }
    
    /// TODO
    public func write(batch: WriteBatch, sync: Bool = true) -> Either<String, ()> {
        let opts = sync ? self.syncWriteOptions : self.asyncWriteOptions
        return tryC {error in
            leveldb_write(self.handle.pointer,
                          opts.pointer,
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
            if let data = value {
                return Value.fromSerializedBytes(data)
            } else {
                return nil
            }
        }
    }
    
    /// TODO
    public func put(key: Key, _ value: Value) -> Either<String, ()> {
        let keyData = key.serializedBytes
        let valueData = value.serializedBytes
        return tryC {error in
            leveldb_put(self.handle.pointer,
                        self.syncWriteOptions.pointer,
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
                           self.syncWriteOptions.pointer,
                           UnsafePointer<Int8>(keyData.bytes),
                           UInt(keyData.length),
                           error)
        }
    }
}
