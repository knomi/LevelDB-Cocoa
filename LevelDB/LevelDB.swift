//
//  LevelDB.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation.NSError
import Foundation.NSData
import LevelDB

public extension LDBDatabase {

    /// TODO
    public typealias Element = (key: NSData, value: NSData)
    
    /// TODO
    public convenience init?(_ path: String) {
        self.init(path: path)
    }
    
    /// TODO
    public convenience init?(path:                 String,
                             inout error:          NSError?,
                             createIfMissing:      Bool?           = nil,
                             errorIfExists:        Bool?           = nil,
                             paranoidChecks:       Bool?           = nil,
                             infoLog:              (String -> ())? = nil,
                             writeBufferSize:      Int?            = nil,
                             maxOpenFiles:         Int?            = nil,
                             cacheCapacity:        Int?            = nil,
                             blockSize:            Int?            = nil,
                             blockRestartInterval: Int?            = nil,
                             compression:          LDBCompression? = nil,
                             bloomFilterBits:      Int?            = nil)
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
        self.init(path: path, options: opts, error: &error)
    }
    
    /// TODO
    public func get<K : DataSerializable,
                    V : DataSerializable>(key: K) -> V?
    {
        if let data = self[key.serializedData] {
            return V(serializedData: data)
        } else {
            return nil
        }
    }
    
    /// TODO
    public func put<K : DataSerializable,
                    V : DataSerializable>(key: K, _ value: V)
    {
        self[key.serializedData] = value.serializedData
    }
    
    /// TODO
    public func delete<K : DataSerializable>(key: K) {
        self[key.serializedData] = nil
    }
    
}

//public final class Database<K : protocol<DataSerializable, Comparable>,
//                            V : DataSerializable>
//{
//    
//}

extension LDBEnumerator : GeneratorType {

    public typealias Element = (NSData, NSData)
    
    public func next() -> Element? {
        if let k = key {
            if let v = value {
                self.step()
                return (k, v)
            }
        }
        return nil
    }

}

extension LDBSnapshot : SequenceType {
    
    public typealias Generator = LDBEnumerator
    
    public func generate() -> Generator {
        return enumerator()
    }
}

extension LDBSnapshot {
    
    public var keys: LazySequence<MapSequenceView<LDBSnapshot, NSData>> {
        return lazy(self).map {k, _ in k}
    }

    public var values: LazySequence<MapSequenceView<LDBSnapshot, NSData>> {
        return lazy(self).map {_, v in v}
    }
    
    public func clamp<K : DataSerializable>(#from: K, to: K) -> LDBSnapshot {
        return clampStart(from.serializedData, end: to.serializedData)
    }
    
    public func clamp<K : DataSerializable>(#from: K, through: K) -> LDBSnapshot {
        let end: NSData? = through.serializedData.ldb_lexicographicalFirstChild()
        return clampStart(from.serializedData, end: end)
    }
    
}

extension LDBWriteBatch {

    /// TODO
    public func put<K : DataSerializable,
                    V : DataSerializable>(key: K, _ value: V)
    {
        self[key.serializedData] = value.serializedData
    }
    
    /// TODO
    public func delete<K : DataSerializable>(key: K) {
        self[key.serializedData] = nil
    }

    public func enumerate<K : DataSerializable,
                          V : DataSerializable>(block: (K, V?) -> ()) {
        enumerate {k, v in
            if let key = K(serializedData: k) {
                if let data = v {
                    if let value = V(serializedData: data) {
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
