//
//  Snapshot.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 26.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

/// TODO
public struct Snapshot<K : KeyType, V : ValueType>  {

    public typealias Database = LevelDB.Database<K, V>
    public typealias Key = K
    public typealias Value = V
    public typealias Element = (Key, Value)

    internal let database: Database
    internal let handle: Handle
    internal let interval: RealInterval<AddBounds<K>>
    
    internal init(database: Database,
                  handle: Handle,
                  interval: RealInterval<AddBounds<K>>) {
        self.database = database
        self.handle = handle
        self.interval = interval
    }

    internal init(database: Database, interval: RealInterval<AddBounds<K>>) {
        self.database = database
        self.handle = Handle(leveldb_create_snapshot(database.handle.pointer)) {pointer in
            leveldb_release_snapshot(database.handle.pointer, pointer)
        }
        self.interval = interval
    }

//    public var reversed: SnapshotBy<Comparator.Reverse> {
//        return undefined()
//    }

    /// TODO
    public subscript(interval: ClosedInterval<Key>) -> Snapshot {
        let capped = AddBounds(interval.start) ... AddBounds(interval.end)
        let clamped = self.interval.clamp(RealInterval(capped))
        return Snapshot(database: database,
                        handle: handle,
                        interval: clamped)
    }
    
    /// TODO
    public subscript(interval: HalfOpenInterval<Key>) -> Snapshot {
        let capped = AddBounds(interval.start) ..< AddBounds(interval.end)
        let clamped = self.interval.clamp(RealInterval(capped))
        return Snapshot(database: database,
                        handle: handle,
                        interval: clamped)
    }
    
}

extension Snapshot : SequenceType {
    /// TODO
    public typealias Generator = SnapshotGenerator<Key, Value>

    /// TODO
    public func generate() -> Generator {
        return Generator(snapshot: self)
    }
}

//extension Snapshot : CollectionType {
//
//    public typealias Index = SnapshotIndex<Key, Value>
//
//    public var startIndex: Index {
//        return undefined()
//    }
//
//    public var endIndex: Index {
//        return undefined()
//    }
//
//    public subscript(index: Index) -> Element {
//        return undefined()
//    }
//    
//}

// -----------------------------------------------------------------------------
// MARK: Generator

/// TODO
public struct SnapshotGenerator<K : KeyType, V : ValueType> : GeneratorType {

    private let snapshot: Snapshot<K, V>
    private let handle: Handle
    
    internal init(snapshot: Snapshot<K, V>) {
        self.snapshot = snapshot
        let db = snapshot.database
        self.handle = Handle(
            leveldb_create_iterator(db.handle.pointer, db.readOptions.pointer),
            leveldb_iter_destroy)
        switch snapshot.interval.start {
        case .MinBound:
            leveldb_iter_seek_to_first(handle.pointer)
        case let .NoBound(start):
            let data = start.serializedBytes
            leveldb_iter_seek(handle.pointer, UnsafePointer<Int8>(data.bytes), UInt(data.length))
            if !snapshot.interval.closedStart {
                let keyData = ext_leveldb_iter_key_unsafe(handle.pointer)
                if let key = K.fromSerializedBytes(keyData) {
                    // skip over the open start of interval
                    switch start.threeWayCompare(key) {
                    case .LT: break
                    case .EQ: leveldb_iter_next(handle.pointer)
                    case .GT: assert(false, "Found key beyond the limited interval: \(keyData)")
                    }
                }
            }
        case .MaxBound:
            // just leave the iterator in its initial invalid state so the iteration will stop
            assert(leveldb_iter_valid(handle.pointer) == 0)
        }
    }
    
    /// TODO
    public typealias Element = (K, V)
    
    /// TODO
    public mutating func next() -> Element? {
        while leveldb_iter_valid(handle.pointer) != 0 {
            let keyData = ext_leveldb_iter_key_unsafe(handle.pointer)
            let valueData = ext_leveldb_iter_value_unsafe(handle.pointer)
            var element: Element?
            if let key = K.fromSerializedBytes(keyData) {
                if !snapshot.interval.contains(AddBounds(key)) {
                    return nil
                }
                if let value = V.fromSerializedBytes(valueData) {
                    element = (key, value)
                }
            }
            leveldb_iter_next(handle.pointer)
            if element != nil {
                return element
            }
        }
        return nil
    }
}

// -----------------------------------------------------------------------------
// MARK: Index

public struct SnapshotIndex<K : KeyType, V : ValueType> {
    
    public typealias Key = K
    
    private var key: Key
    
    public func successor() -> SnapshotIndex {
        return undefined()
    }
    
    public func predecessor() -> SnapshotIndex {
        return undefined()
    }
    
}

extension SnapshotIndex : ThreeWayComparable {
    public func threeWayCompare(to: SnapshotIndex) -> Ordering {
        return key.threeWayCompare(to.key)
    }
}

extension SnapshotIndex : BidirectionalIndexType {}

//extension SnapshotBy : CollectionType {
//    
//    /// TODO
//    public struct Index : BidirectionalIndexType {
//    
//        /// TODO
//        public typealias Distance = Int
//        
//        /// TODO
//        public func successor() -> Index {
//            return undefined()
//        }
//
//        /// TODO
//        public func predecessor() -> Index {
//            return undefined()
//        }
//    }
//    
//    /// TODO
//    public var startIndex: Index {
//        return undefined()
//    }
//    
//    /// TODO
//    public var endIndex: Index {
//        return undefined()
//    }
//    
//    /// TODO
//    public subscript (position: Index) -> Generator.Element {
//        return undefined()
//    }
//    
//    /// TODO
//    public subscript (interval: HalfOpenInterval<Key>) -> SnapshotBy {
//        return undefined()
//    }
//    
//    /// TODO
//    public subscript (interval: ClosedInterval<Key>) -> SnapshotBy {
//        return undefined()
//    }
//    
//}
//
//public func == <C : ComparatorType>(_: SnapshotBy<C>.Index, _: SnapshotBy<C>.Index) -> Bool {
//    return undefined()
//}
//
//extension SnapshotBy : Printable {
//
//    /// TODO
//    public var description: String {
//        return "Snapshot" // TODO
//    }
//
//}
//
//extension SnapshotBy : DebugPrintable {
//
//    /// TODO
//    public var debugDescription: String {
//        return "Snapshot" // TODO
//    }
//
//}
