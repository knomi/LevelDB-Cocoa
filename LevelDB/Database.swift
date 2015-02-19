//
//  Database.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation
import LevelDB
import protocol Allsorts.Orderable

/// TODO
public struct Database<K : protocol<ByteSerializable, Orderable>,
                       V : ByteSerializable>
{

    /// TODO
    public typealias Key = K

    /// TODO
    public typealias Value = V
    
    /// TODO
    public typealias Element = (key: Key, value: Value)
    
// -----------------------------------------------------------------------------
// MARK: Data

    public let database: LDBDatabase
    
// -----------------------------------------------------------------------------
// MARK: Initialization
    
    public init(database: LDBDatabase) {
        self.database = database
    }
    
    /// TODO (in-memory database)
    public init() {
        self.init(database: LDBDatabase())
    }
    
    /// TODO
    public init?(_ path: String) {
        if let database = LDBDatabase(path: path) {
            self.init(database: database)
        } else {
            return nil
        }
    }
    
    /// TODO
    public init?(path:   String,
                 inout error: NSError?,
                 createIfMissing: Bool? = nil,
                 errorIfExists:   Bool? = nil,
                 paranoidChecks:  Bool? = nil,
                 infoLog: (String -> ())? = nil,
                 writeBufferSize: Int? = nil,
                 maxOpenFiles:    Int? = nil,
                 cacheCapacity:   Int? = nil,
                 blockSize:       Int? = nil,
                 blockRestartInterval: Int? = nil,
                 compression:     LDBCompression? = nil,
                 bloomFilterBits: Int? = nil)
    {
        var opts = [String: AnyObject]()
        if let x = createIfMissing { opts[LDBOptionCreateIfMissing] = x }
        if let x = errorIfExists   { opts[LDBOptionErrorIfExists] = x }
        if let x = paranoidChecks  { opts[LDBOptionParanoidChecks] = x }
        if let f = infoLog         { opts[LDBOptionInfoLog] = LDBLogger {s in f(s)} }
        if let x = writeBufferSize { opts[LDBOptionWriteBufferSize] = x }
        if let x = maxOpenFiles    { opts[LDBOptionMaxOpenFiles] = x }
        if let x = cacheCapacity   { opts[LDBOptionCacheCapacity] = x }
        if let x = blockSize       { opts[LDBOptionBlockSize] = x }
        if let x = blockRestartInterval { opts[LDBOptionBlockRestartInterval] = x }
        if let x = compression     { opts[LDBOptionCompression] = x.rawValue }
        if let x = bloomFilterBits { opts[LDBOptionBloomFilterBits] = x }
        if let database = LDBDatabase(path: path, options: opts, error: &error) {
            self.init(database: database)
        } else {
            return nil
        }
    }
    
// -----------------------------------------------------------------------------
// MARK: Database access

    /// TODO
    public func cast<K1, V1>() -> Database<K1, V1> {
        return Database<K1, V1>(database: database)
    }

    /// TODO
    public subscript(key: Key) -> Value? {
        get {
            return Value.fromSerializedBytes(database[key.serializedBytes])
        }
        set {
            database[key.serializedBytes] = newValue?.serializedBytes
        }
    }
}

public extension Database {

    /// TODO
    public typealias WriteBatch = LevelDB.WriteBatch<Key, Value>

    /// TODO
    public func write(batch: WriteBatch, sync: Bool, inout error: NSError?) -> Bool {
        return database.write(batch.batch, sync: sync, error: &error)
    }

}

//public extension Database {
//
//    /// TODO
//    public typealias Snapshot = LevelDB.Snapshot<Key, Value>
//    
//    /// TODO
//    public func snapshot() -> Snapshot {
//        return
//    }
//    
//}
