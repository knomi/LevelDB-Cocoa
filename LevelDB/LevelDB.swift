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
    
}

extension LDBEnumerator : GeneratorType {

    public typealias Element = LDBDatabase.Element
    
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

    public typealias Element = (key: NSData, value: NSData)
    
    public func clamp(#from: NSData) -> LDBSnapshot {
        return clampStart(from, end: nil)
    }
    
    public func clamp(#after: NSData) -> LDBSnapshot {
        return clampStart(after.ldb_lexicographicalFirstChild(), end: nil)
    }
    
    public func clamp(#to: NSData) -> LDBSnapshot {
        return clampStart(NSData(), end: to)
    }
    
    public func clamp(#through: NSData) -> LDBSnapshot {
        return clampStart(nil, end: through.ldb_lexicographicalFirstChild())
    }
    
    public func clamp(#from: NSData?, to: NSData?) -> LDBSnapshot {
        return clampStart(from, end: to)
    }

    public func clamp(#from: NSData?, through: NSData?) -> LDBSnapshot {
        return clampStart(from, end: through?.ldb_lexicographicalFirstChild())
    }
    
    public func clamp(#after: NSData?, to: NSData?) -> LDBSnapshot {
        return clampStart(after?.ldb_lexicographicalFirstChild(), end: to)
    }
    
    public func clamp(#after: NSData?, through: NSData?) -> LDBSnapshot {
        return clampStart(after?.ldb_lexicographicalFirstChild(),
                          end: through?.ldb_lexicographicalFirstChild())
    }
    
    public var keys: LazySequence<MapSequenceView<LDBSnapshot, NSData>> {
        return lazy(self).map {k, _ in k}
    }

    public var values: LazySequence<MapSequenceView<LDBSnapshot, NSData>> {
        return lazy(self).map {_, v in v}
    }
    
    public var first: Element? {
        var g = generate()
        return g.next()
    }
    
    public var last: Element? {
        let r = reversed
        var g = r.generate()
        return g.next()
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
            if let key = K.fromSerializedData(k) {
                if let data = v {
                    if let value = V.fromSerializedData(data) {
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

public final class Database<K : protocol<DataSerializable, Comparable>,
                            V : DataSerializable>
{
    public typealias Key = K
    public typealias Value = V
    public typealias Element = (key: Key, value: Value)
    
    private let _raw: LDBDatabase?
    public var raw: LDBDatabase {
        return _raw!
    }
    
    public init() {
        _raw = LDBDatabase()
    }
    
    public init?(_ path: String) {
        _raw = LDBDatabase(path)
        if _raw == nil {
            return nil
        }
    }
    
    public init(_ database: LDBDatabase) {
        _raw = database
    }
    
    public subscript(key: Key) -> Value? {
        get {
            if let data = raw[key.serializedData] {
                return Value.fromSerializedData(data)
            } else {
                return nil
            }
        }
        set {
            raw[key.serializedData] = newValue?.serializedData
        }
    }
    
    public func snapshot() -> Snapshot<Key, Value> {
        return Snapshot(raw.snapshot())
    }
    
    public func write(batch: WriteBatch<Key, Value>,
                      sync: Bool,
                      error: NSErrorPointer) -> Bool
    {
        return raw.write(batch.raw, sync: sync, error: error)
    }
    
    public func approximateSizes(intervals: [(Key?, Key?)]) -> [UInt64] {
        let dataIntervals = intervals.map {start, end in
            LDBInterval(start: start?.serializedData,
                        end: end?.serializedData)
        }
        return raw.approximateSizesForIntervals(dataIntervals).map {n in
            // FIXME: Swift 1.1 compatible cast. Replace with `as!` once in 1.2.
            (n as? NSNumber)!.unsignedLongLongValue
        }
    }

    public func approximateSize(start: Key?, _ end: Key?) -> UInt64 {
        return approximateSizes([(start, end)])[0]
    }

    public func compactInterval(start: Key?, _ end: Key?) {
        raw.compactInterval(LDBInterval(start: start?.serializedData,
                                        end:   end?.serializedData))
    }
}

public struct Snapshot<K : protocol<DataSerializable, Comparable>,
                       V : DataSerializable>
{
    public typealias Key = K
    public typealias Value = V
    public typealias Element = (key: Key, value: Value)
    
    public let raw: LDBSnapshot
    
    public init(_ snapshot: LDBSnapshot) {
        self.raw = snapshot
    }
    
    public var noncaching:  Snapshot { return Snapshot(raw.noncaching) }
    public var checksummed: Snapshot { return Snapshot(raw.checksummed) }
    public var reversed:    Snapshot { return Snapshot(raw.reversed) }
    
    public var isNoncaching:  Bool { return raw.isNoncaching }
    public var isChecksummed: Bool { return raw.isChecksummed }
    public var isReversed:    Bool { return raw.isReversed }
    
    public func prefixed(prefix: Key) -> Snapshot {
        return Snapshot(raw.prefixed(prefix.serializedData))
    }
    
    public func clamp(#from: Key) -> Snapshot {
        return Snapshot(raw.clamp(from: from.serializedData))
    }
    
    public func clamp(#after: Key) -> Snapshot {
        return Snapshot(raw.clamp(after: after.serializedData))
    }
    
    public func clamp(#to: Key) -> Snapshot {
        return Snapshot(raw.clamp(to: to.serializedData))
    }
    
    public func clamp(#through: Key) -> Snapshot {
        return Snapshot(raw.clamp(through: through.serializedData))
    }

    public func clamp(#from: Key?, to: Key?) -> Snapshot {
        return Snapshot(raw.clamp(from: from?.serializedData,
                                  to:   to?.serializedData))
    }
    
    public func clamp(#from: Key?, through: Key?) -> Snapshot {
        return Snapshot(raw.clamp(from:    from?.serializedData,
                                  through: through?.serializedData))
    }
    
    public func clamp(#after: Key?, to: Key?) -> Snapshot {
        return Snapshot(raw.clamp(after: after?.serializedData,
                                  to:    to?.serializedData))
    }
    
    public func clamp(#after: Key?, through: Key?) -> Snapshot {
        return Snapshot(raw.clamp(after:   after?.serializedData,
                                  through: through?.serializedData))
    }
    
    public subscript(key: Key) -> Value? {
        if let data = raw[key.serializedData] {
            return Value.fromSerializedData(data)
        } else {
            return nil
        }
    }
    
    public subscript(interval: HalfOpenInterval<Key>) -> Snapshot {
        return clamp(from: interval.start, to: interval.end)
    }
    
    public subscript(interval: ClosedInterval<Key>) -> Snapshot {
        return clamp(from: interval.start, through: interval.end)
    }
    
}

public struct SnapshotGenerator<K : protocol<DataSerializable, Comparable>,
                                V : DataSerializable> : GeneratorType
{
    public typealias Key = K
    public typealias Value = V
    public typealias Element = (key: Key, value: Value)

    private let enumerator: LDBEnumerator
    
    internal init(snapshot: Snapshot<K, V>) {
        self.enumerator = snapshot.raw.enumerator()
    }
    
    public func next() -> Element? {
        while let (k, v) = enumerator.next() {
            if let key = Key.fromSerializedData(k) {
                if let value = Value.fromSerializedData(v) {
                    return (key: key, value: value)
                }
            }
        }
        return nil
    }
}

extension Snapshot : SequenceType {

    public typealias Generator = SnapshotGenerator<K, V>

    public func generate() -> Generator {
        return Generator(snapshot: self)
    }
}

extension Snapshot {
    
    public var keys: LazySequence<MapSequenceView<Snapshot, Key>> {
        return lazy(self).map {k, _ in k}
    }

    public var values: LazySequence<MapSequenceView<Snapshot, Value>> {
        return lazy(self).map {_, v in v}
    }
    
    public var first: Element? {
        var g = generate()
        return g.next()
    }
    
    public var last: Element? {
        let r = reversed
        var g = r.generate()
        return g.next()
    }
    
}

public final class WriteBatch<K : protocol<DataSerializable, Comparable>,
                              V : DataSerializable>
{
    public typealias Key = K
    public typealias Value = V
    public typealias Element = (key: Key, value: Value)

    public let raw: LDBWriteBatch
    
    public init() {
        self.raw = LDBWriteBatch()
    }
    
    public init(prefix: K) {
        self.raw = LDBWriteBatch(prefix: prefix.serializedData)
    }
    
    public init(_ batch: LDBWriteBatch) {
        self.raw = batch
    }
    
    public func prefixed(prefix: K) -> WriteBatch {
        return WriteBatch(raw.prefixed(prefix.serializedData))
    }
    
    public subscript(key: Key) -> Value? {
        get { return nil }
        set {
            raw[key.serializedData] = newValue?.serializedData
        }
    }
    
    public func enumerate(block: (Key, Value?) -> ()) {
        raw.enumerate {k, v in
            if let key = Key.fromSerializedData(k) {
                if let data = v {
                    if let value = Value.fromSerializedData(data) {
                        block(key, value)
                    }
                } else {
                    block(key, nil)
                }
            }
        }
    }
}
