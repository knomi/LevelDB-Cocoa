//
//  LevelDB.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation.NSError
import Foundation.NSData

public extension LDBDatabase {

    public typealias Element = (key: Data, value: Data)
    
    /// Convenience constructor for setting up database options.
    public static func options(createIfMissing: Bool? = nil,
                               errorIfExists:        Bool?           = nil,
                               paranoidChecks:       Bool?           = nil,
                               infoLog:              ((String) -> ())? = nil,
                               writeBufferSize:      Int?            = nil,
                               maxOpenFiles:         Int?            = nil,
                               cacheCapacity:        Int?            = nil,
                               blockSize:            Int?            = nil,
                               blockRestartInterval: Int?            = nil,
                               compression:          LDBCompression? = nil,
                               reuseLogs:            Bool?           = nil,
                               bloomFilterBits:      Int?            = nil,
                               // Suppress trailing closure warning for infoLog.
                               _ignored: (() -> ())? = nil) -> [String: AnyObject]
    {
        var opts = [String: AnyObject]()
        if let x = createIfMissing { opts[LDBOptionCreateIfMissing] = x as AnyObject? }
        if let x = errorIfExists   { opts[LDBOptionErrorIfExists] = x as AnyObject? }
        if let x = paranoidChecks  { opts[LDBOptionParanoidChecks] = x as AnyObject? }
        if let f = infoLog         { opts[LDBOptionInfoLog] = LDBLogger {s in f(s)} }
        if let x = writeBufferSize { opts[LDBOptionWriteBufferSize] = x as AnyObject? }
        if let x = maxOpenFiles    { opts[LDBOptionMaxOpenFiles] = x as AnyObject? }
        if let x = cacheCapacity   { opts[LDBOptionCacheCapacity] = x as AnyObject? }
        if let x = blockSize       { opts[LDBOptionBlockSize] = x as AnyObject? }
        if let x = blockRestartInterval { opts[LDBOptionBlockRestartInterval] = x as AnyObject? }
        if let x = compression     { opts[LDBOptionCompression] = x.rawValue as AnyObject? }
        if let x = reuseLogs       { opts[LDBOptionReuseLogs] = x as AnyObject? }
        if let x = bloomFilterBits { opts[LDBOptionBloomFilterBits] = x as AnyObject? }
        return opts
    }

    /// Convenience function to write the batch as set in `block`.
    public func write(sync: Bool = true,
                      block: (LDBWriteBatch) throws -> ()) throws
    {
        let batch = LDBWriteBatch()
        try block(batch)
        try write(batch, sync: sync)
    }
}

extension LDBInterval {
    public convenience init(from: Data?) {
        self.init(uncheckedStart: from, end: nil)
    }

    public convenience init(after: Data?) {
        self.init(uncheckedStart: (after as NSData?)?.ldb_lexicographicalFirstChild(), end: nil)
    }

    public convenience init(to: Data?) {
        self.init(uncheckedStart: Data(), end: to)
    }

    public convenience init(through: Data?) {
        self.init(uncheckedStart: Data(), end: (through as NSData?)?.ldb_lexicographicalFirstChild())
    }

    public convenience init(from: Data?, to: Data?) {
        if NSData.ldb_compareLeft(from, right: to).rawValue <= 0 {
            self.init(uncheckedStart: from, end: to)
        } else {
            self.init(uncheckedStart: nil, end: nil)
        }
    }

    public convenience init(from: Data?, through: Data?) {
        if NSData.ldb_compareLeft(from, right: through).rawValue <= 0 {
            self.init(uncheckedStart: from,
                      end: (through as NSData?)?.ldb_lexicographicalFirstChild())
        } else {
            self.init(uncheckedStart: nil, end: nil)
        }
    }

    public convenience init(after: Data?, to: Data?) {
        if NSData.ldb_compareLeft(after, right: to).rawValue <= 0 {
            self.init(uncheckedStart: (after as NSData?)?.ldb_lexicographicalFirstChild(),
                      end: to)
        } else {
            self.init(uncheckedStart: nil, end: nil)
        }
    }

    public convenience init(after: Data?, through: Data?) {
        if NSData.ldb_compareLeft(after, right: through).rawValue <= 0 {
            self.init(uncheckedStart: (after as NSData?)?.ldb_lexicographicalFirstChild(),
                      end: (through as NSData?)?.ldb_lexicographicalFirstChild())
        } else {
            self.init(uncheckedStart: nil, end: nil)
        }
    }
}

extension LDBEnumerator : IteratorProtocol {

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

extension LDBSnapshot : Sequence {
    
    public typealias Iterator = LDBEnumerator
    
    public func makeIterator() -> Iterator {
        return enumerator()
    }
}

extension LDBSnapshot {

    public typealias Element = LDBDatabase.Element
    
    public func clampFrom(_ from: Data?) -> LDBSnapshot {
        return clamp(to: LDBInterval(from: from))
    }
    
    public func clampAfter(_ after: Data?) -> LDBSnapshot {
        return clamp(to: LDBInterval(after: after))
    }
    
    public func clampTo(_ to: Data?) -> LDBSnapshot {
        return clamp(to: LDBInterval(to: to))
    }
    
    public func clampThrough(_ through: Data?) -> LDBSnapshot {
        return clamp(to: LDBInterval(through: through))
    }
    
    public func clampFrom(_ from: Data?, to: Data?) -> LDBSnapshot {
        return clamp(to: LDBInterval(from: from, to: to))
    }

    public func clampFrom(_ from: Data?, through: Data?) -> LDBSnapshot {
        return clamp(to: LDBInterval(from: from, through: through))
    }
    
    public func clampAfter(_ after: Data?, to: Data?) -> LDBSnapshot {
        return clamp(to: LDBInterval(after: after, to: to))
    }
    
    public func clampAfter(_ after: Data?, through: Data?) -> LDBSnapshot {
        return clamp(to: LDBInterval(after: after, through: through))
    }
    
    public var keys: LazyMapSequence<LDBSnapshot, Data> {
        return lazy.map {k, _ in k}
    }

    public var values: LazyMapSequence<LDBSnapshot, Data> {
        return lazy.map {_, v in v}
    }
    
    public var first: Element? {
        let g = makeIterator()
        return g.next()
    }
    
    public var last: Element? {
        let r = reversed
        let g = r.makeIterator()
        return g.next()
    }
    
}

public final class Database<Key : DataSerializable & Comparable,
                            Value : DataSerializable>
{
    public typealias Element = (key: Key, value: Value)
    
    fileprivate var _raw: LDBDatabase?
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
            return raw[key.serializedData as Data].flatMap(Value.fromSerializedData)
        }
        set {
            raw[key.serializedData as Data] = newValue?.serializedData as Data?
        }
    }
    
    public func snapshot() -> Snapshot<Key, Value> {
        return Snapshot(raw.snapshot())
    }
    
    public func write(_ batch: WriteBatch<Key, Value>,
                      sync: Bool) throws
    {
        try raw.write(batch.raw, sync: sync)
    }
    
    /// Convenience function to write the batch as set in `block`.
    public func write(sync: Bool = true,
                      block: (WriteBatch<Key, Value>) throws -> ()) throws
    {
        let batch = WriteBatch<Key, Value>()
        try block(batch)
        try write(batch, sync: sync)
    }
    
    public func approximateSizes(_ intervals: [(Key?, Key?)]) -> [UInt64] {
        let dataIntervals = intervals.map {start, end in
            LDBInterval(start: start?.serializedData,
                        end: end?.serializedData)
        }
        return raw.approximateSizes(for: dataIntervals).map {n in
            n.uint64Value
        }
    }

    public func approximateSize(from start: Key?, to end: Key?) -> UInt64 {
        return approximateSizes([(start, end)])[0]
    }

    public func compactInterval(_ start: Key?, _ end: Key?) {
        raw.compactInterval(LDBInterval(start: start?.serializedData as Data?,
                                        end:   end?.serializedData as Data?))
    }
}

public struct Snapshot<Key : DataSerializable & Comparable,
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
    
    public func prefixed(_ prefix: Key) -> Snapshot {
        return Snapshot(raw.prefixed(prefix.serializedData as Data))
    }
    
    public func clampFrom(_ from: Key?) -> Snapshot {
        return Snapshot(raw.clampFrom(from?.serializedData as Data?))
    }
    
    public func clampAfter(_ after: Key?) -> Snapshot {
        return Snapshot(raw.clampAfter(after?.serializedData as Data?))
    }
    
    public func clampTo(_ to: Key?) -> Snapshot {
        return Snapshot(raw.clampTo(to?.serializedData as Data?))
    }
    
    public func clampThrough(_ through: Key?) -> Snapshot {
        return Snapshot(raw.clampThrough(through?.serializedData as Data?))
    }

    public func clampFrom(_ from: Key?, to: Key?) -> Snapshot {
        return Snapshot(raw.clampFrom(from?.serializedData as Data?,
                                      to: to?.serializedData as Data?))
    }
    
    public func clampFrom(_ from: Key?, through: Key?) -> Snapshot {
        return Snapshot(raw.clampFrom(from?.serializedData as Data?,
                                      through: through?.serializedData as Data?))
    }
    
    public func clampAfter(_ after: Key?, to: Key?) -> Snapshot {
        return Snapshot(raw.clampAfter(after?.serializedData as Data?,
                                       to: to?.serializedData as Data?))
    }
    
    public func clampAfter(_ after: Key?, through: Key?) -> Snapshot {
        return Snapshot(raw.clampAfter(after?.serializedData as Data?,
                                       through: through?.serializedData as Data?))
    }
    
    public subscript(key: Key) -> Value? {
        return raw[key.serializedData as Data].flatMap(Value.fromSerializedData)
    }
    
    public subscript(interval: Range<Key>) -> Snapshot {
        return clampFrom(interval.lowerBound, to: interval.upperBound)
    }
    
    public subscript(interval: ClosedRange<Key>) -> Snapshot {
        return clampFrom(interval.lowerBound, through: interval.upperBound)
    }
    
}

public struct SnapshotGenerator<Key : DataSerializable & Comparable,
                                Value : DataSerializable> : IteratorProtocol
{
    public typealias Element = (key: Key, value: Value)

    fileprivate let enumerator: LDBEnumerator
    
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

extension Snapshot : Sequence {

    public typealias Iterator = SnapshotGenerator<Key, Value>

    public func makeIterator() -> Iterator {
        return Iterator(snapshot: self)
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
        let g = makeIterator()
        return g.next()
    }
    
    public var last: Element? {
        let r = reversed
        let g = r.makeIterator()
        return g.next()
    }
    
}

public final class WriteBatch<Key : DataSerializable & Comparable,
                              Value : DataSerializable>
{
    public typealias Element = (key: Key, value: Value)

    public let raw: LDBWriteBatch
    
    public init() {
        self.raw = LDBWriteBatch()
    }
    
    public init(prefix: Key) {
        self.raw = LDBWriteBatch(prefix: prefix.serializedData as Data)
    }
    
    public init(_ batch: LDBWriteBatch) {
        self.raw = batch
    }
    
    public func prefixed(_ prefix: Key) -> WriteBatch {
        return WriteBatch(raw.prefixed(prefix.serializedData as Data))
    }
    
    public subscript(key: Key) -> Value? {
        get {
            return nil
        }
        set {
            raw[key.serializedData as Data] = newValue?.serializedData as Data?
        }
    }
    
    public func enumerate(_ block: (Key, Value?) -> ()) {
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
