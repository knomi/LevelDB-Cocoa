//
//  LevelDB.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation.NSError
import Foundation.NSData

public extension LDBDatabase {

    public typealias Element = (key: NSData, value: NSData)
    
    /// Convenience constructor for setting up database options.
    public static func options(createIfMissing createIfMissing: Bool? = nil,
                               errorIfExists:        Bool?           = nil,
                               paranoidChecks:       Bool?           = nil,
                               infoLog:              (String -> ())? = nil,
                               writeBufferSize:      Int?            = nil,
                               maxOpenFiles:         Int?            = nil,
                               cacheCapacity:        Int?            = nil,
                               blockSize:            Int?            = nil,
                               blockRestartInterval: Int?            = nil,
                               compression:          LDBCompression? = nil,
                               reuseLogs:            Bool?           = nil,
                               bloomFilterBits:      Int?            = nil,
                               // Suppress trailing closure warning for infoLog.
                               _: (() -> ())? = nil) -> [String: AnyObject]
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
        if let x = reuseLogs       { opts[LDBOptionReuseLogs] = x }
        if let x = bloomFilterBits { opts[LDBOptionBloomFilterBits] = x }
        return opts
    }

    /// Convenience function to write the batch as set in `block`.
    public func write(sync sync: Bool = true,
                      block: LDBWriteBatch throws -> ()) throws
    {
        let batch = LDBWriteBatch()
        try block(batch)
        try write(batch, sync: sync)
    }
}

extension LDBInterval {
    public convenience init(from: NSData?) {
        self.init(uncheckedStart: from, end: nil)
    }

    public convenience init(after: NSData?) {
        self.init(uncheckedStart: after?.ldb_lexicographicalFirstChild(), end: nil)
    }

    public convenience init(to: NSData?) {
        self.init(uncheckedStart: NSData(), end: to)
    }

    public convenience init(through: NSData?) {
        self.init(uncheckedStart: NSData(), end: through?.ldb_lexicographicalFirstChild())
    }

    public convenience init(from: NSData?, to: NSData?) {
        if NSData.ldb_compareLeft(from, right: to).rawValue <= 0 {
            self.init(uncheckedStart: from, end: to)
        } else {
            self.init(uncheckedStart: nil, end: nil)
        }
    }

    public convenience init(from: NSData?, through: NSData?) {
        if NSData.ldb_compareLeft(from, right: through).rawValue <= 0 {
            self.init(uncheckedStart: from,
                      end: through?.ldb_lexicographicalFirstChild())
        } else {
            self.init(uncheckedStart: nil, end: nil)
        }
    }

    public convenience init(after: NSData?, to: NSData?) {
        if NSData.ldb_compareLeft(after, right: to).rawValue <= 0 {
            self.init(uncheckedStart: after?.ldb_lexicographicalFirstChild(),
                      end: to)
        } else {
            self.init(uncheckedStart: nil, end: nil)
        }
    }

    public convenience init(after: NSData?, through: NSData?) {
        if NSData.ldb_compareLeft(after, right: through).rawValue <= 0 {
            self.init(uncheckedStart: after?.ldb_lexicographicalFirstChild(),
                      end: through?.ldb_lexicographicalFirstChild())
        } else {
            self.init(uncheckedStart: nil, end: nil)
        }
    }
}

extension LDBEnumerator : GeneratorType {

    public typealias Element = LDBDatabase.Element
    
    public func next() -> Element? {
        if let k = key,
           let v = value
        {
            self.step()
            return (k, v)
        } else {
            return nil
        }
    }

}

extension LDBSnapshot : SequenceType {
    
    public typealias Generator = LDBEnumerator
    
    public func generate() -> Generator {
        return enumerator()
    }
}

extension LDBSnapshot {

    public typealias Element = LDBDatabase.Element
    
    public func clampFrom(from: NSData?) -> LDBSnapshot {
        return clampToInterval(LDBInterval(from: from))
    }
    
    public func clampAfter(after: NSData?) -> LDBSnapshot {
        return clampToInterval(LDBInterval(after: after))
    }
    
    public func clampTo(to: NSData?) -> LDBSnapshot {
        return clampToInterval(LDBInterval(to: to))
    }
    
    public func clampThrough(through: NSData?) -> LDBSnapshot {
        return clampToInterval(LDBInterval(through: through))
    }
    
    public func clampFrom(from: NSData?, to: NSData?) -> LDBSnapshot {
        return clampToInterval(LDBInterval(from: from, to: to))
    }

    public func clampFrom(from: NSData?, through: NSData?) -> LDBSnapshot {
        return clampToInterval(LDBInterval(from: from, through: through))
    }
    
    public func clampAfter(after: NSData?, to: NSData?) -> LDBSnapshot {
        return clampToInterval(LDBInterval(after: after, to: to))
    }
    
    public func clampAfter(after: NSData?, through: NSData?) -> LDBSnapshot {
        return clampToInterval(LDBInterval(after: after, through: through))
    }
    
    public var keys: LazyMapSequence<LDBSnapshot, NSData> {
        return lazy.map {k, _ in k}
    }

    public var values: LazyMapSequence<LDBSnapshot, NSData> {
        return lazy.map {_, v in v}
    }
    
    public var first: Element? {
        let g = generate()
        return g.next()
    }
    
    public var last: Element? {
        let r = reversed
        let g = r.generate()
        return g.next()
    }
    
}

public final class Database<Key : protocol<DataSerializable, Comparable>,
                            Value : DataSerializable>
{
    public typealias Element = (key: Key, value: Value)
    
    private var _raw: LDBDatabase?
    public var raw: LDBDatabase {
        return _raw!
    }
    
    public init() {
        _raw = LDBDatabase()
    }
    
    public init(path: String) throws {
        _raw = nil
        _raw = try LDBDatabase(path: path)
    }
    
    public init(_ database: LDBDatabase) {
        _raw = database
    }
    
    public subscript(key: Key) -> Value? {
        get {
            return raw[key.serializedData].flatMap(Value.fromSerializedData)
        }
        set {
            raw[key.serializedData] = newValue?.serializedData
        }
    }
    
    public func snapshot() -> Snapshot<Key, Value> {
        return Snapshot(raw.snapshot())
    }
    
    public func write(batch: WriteBatch<Key, Value>,
                      sync: Bool) throws
    {
        try raw.write(batch.raw, sync: sync)
    }
    
    /// Convenience function to write the batch as set in `block`.
    public func write(sync sync: Bool = true,
                      block: WriteBatch<Key, Value> throws -> ()) throws
    {
        let batch = WriteBatch<Key, Value>()
        try block(batch)
        try write(batch, sync: sync)
    }
    
    public func approximateSizes(intervals: [(Key?, Key?)]) -> [UInt64] {
        let dataIntervals = intervals.map {start, end in
            LDBInterval(start: start?.serializedData,
                        end: end?.serializedData)
        }
        return raw.approximateSizesForIntervals(dataIntervals).map {n in
            n.unsignedLongLongValue
        }
    }

    public func approximateSize(from start: Key?, to end: Key?) -> UInt64 {
        return approximateSizes([(start, end)])[0]
    }

    public func compactInterval(start: Key?, _ end: Key?) {
        raw.compactInterval(LDBInterval(start: start?.serializedData,
                                        end:   end?.serializedData))
    }
}

public struct Snapshot<Key : protocol<DataSerializable, Comparable>,
                       Value : DataSerializable>
{
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
    public var isClamped:     Bool { return raw.isClamped }
    
    public func prefixed(prefix: Key) -> Snapshot {
        return Snapshot(raw.prefixed(prefix.serializedData))
    }
    
    public func clampFrom(from: Key?) -> Snapshot {
        return Snapshot(raw.clampFrom(from?.serializedData))
    }
    
    public func clampAfter(after: Key?) -> Snapshot {
        return Snapshot(raw.clampAfter(after?.serializedData))
    }
    
    public func clampTo(to: Key?) -> Snapshot {
        return Snapshot(raw.clampTo(to?.serializedData))
    }
    
    public func clampThrough(through: Key?) -> Snapshot {
        return Snapshot(raw.clampThrough(through?.serializedData))
    }

    public func clampFrom(from: Key?, to: Key?) -> Snapshot {
        return Snapshot(raw.clampFrom(from?.serializedData,
                                      to: to?.serializedData))
    }
    
    public func clampFrom(from: Key?, through: Key?) -> Snapshot {
        return Snapshot(raw.clampFrom(from?.serializedData,
                                      through: through?.serializedData))
    }
    
    public func clampAfter(after: Key?, to: Key?) -> Snapshot {
        return Snapshot(raw.clampAfter(after?.serializedData,
                                       to: to?.serializedData))
    }
    
    public func clampAfter(after: Key?, through: Key?) -> Snapshot {
        return Snapshot(raw.clampAfter(after?.serializedData,
                                       through: through?.serializedData))
    }
    
    public subscript(key: Key) -> Value? {
        return raw[key.serializedData].flatMap(Value.fromSerializedData)
    }
    
    public subscript(interval: HalfOpenInterval<Key>) -> Snapshot {
        return clampFrom(interval.start, to: interval.end)
    }
    
    public subscript(interval: ClosedInterval<Key>) -> Snapshot {
        return clampFrom(interval.start, through: interval.end)
    }
    
}

public struct SnapshotGenerator<Key : protocol<DataSerializable, Comparable>,
                                Value : DataSerializable> : GeneratorType
{
    public typealias Element = (key: Key, value: Value)

    private let enumerator: LDBEnumerator
    
    internal init(snapshot: Snapshot<Key, Value>) {
        self.enumerator = snapshot.raw.enumerator()
    }
    
    public func next() -> Element? {
        while let (k, v) = enumerator.next() {
            if let key = Key.fromSerializedData(k),
               let value = Value.fromSerializedData(v)
            {
                return (key: key, value: value)
            }
        }
        return nil
    }
}

extension Snapshot : SequenceType {

    public typealias Generator = SnapshotGenerator<Key, Value>

    public func generate() -> Generator {
        return Generator(snapshot: self)
    }
}

extension Snapshot {
    
    public var keys: LazyMapSequence<Snapshot, Key> {
        return lazy.map {k, _ in k}
    }

    public var values: LazyMapSequence<Snapshot, Value> {
        return lazy.map {_, v in v}
    }
    
    public var first: Element? {
        let g = generate()
        return g.next()
    }
    
    public var last: Element? {
        let r = reversed
        let g = r.generate()
        return g.next()
    }
    
}

public final class WriteBatch<Key : protocol<DataSerializable, Comparable>,
                              Value : DataSerializable>
{
    public typealias Element = (key: Key, value: Value)

    public let raw: LDBWriteBatch
    
    public init() {
        self.raw = LDBWriteBatch()
    }
    
    public init(prefix: Key) {
        self.raw = LDBWriteBatch(prefix: prefix.serializedData)
    }
    
    public init(_ batch: LDBWriteBatch) {
        self.raw = batch
    }
    
    public func prefixed(prefix: Key) -> WriteBatch {
        return WriteBatch(raw.prefixed(prefix.serializedData))
    }
    
    public subscript(key: Key) -> Value? {
        get {
            return nil
        }
        set {
            raw[key.serializedData] = newValue?.serializedData
        }
    }
    
    public func enumerate(block: (Key, Value?) -> ()) {
        raw.enumerate {k, v in
            if let key = Key.fromSerializedData(k) {
                // Using flatMap here may turn an insert into a delete when the
                // deserialization fails. That, however, is how it also looks
                // like when reading the resulting database snapshot of type
                // `Snapshot<K, V>`, since a key with an unreadable value is
                // considered missing. So it's okay to transform `v` to `nil` in
                // that case.
                block(key, v.flatMap(Value.fromSerializedData))
            }
        }
    }
}
