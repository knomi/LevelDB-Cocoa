//
//  Snapshot.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 26.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

/// TODO
public struct SnapshotBy<C : ComparatorType>  {

    public typealias Database = DatabaseBy<C>
    public typealias Comparator = C
    public typealias Key = C.Key
    public typealias Value = C.Value
    public typealias Element = (Key, Value)

    internal let database: Database
    internal let handle: Handle
    internal let start: Key?
    internal let end: Key?
    internal let isClosed: Bool
    
    internal init(database: Database, start: Key?, end: Key?, isClosed: Bool) {
        self.database = database
        self.handle = Handle(leveldb_create_snapshot(database.handle.pointer)) {pointer in
            leveldb_release_snapshot(database.handle.pointer, pointer)
        }
        self.start = start
        self.end = end
        self.isClosed = isClosed
    }

//    public var reversed: SnapshotBy<Comparator.Reverse> {
//        return undefined()
//    }

//    public subscript(interval: ClosedInterval<C.Key>) -> SnapshotBy {
//        return undefined()
//    }
//    
//    public subscript(interval: HalfOpenInterval<C.Key>) -> SnapshotBy {
//        return undefined()
//    }
    
}

extension SnapshotBy : SequenceType {
    /// TODO
    public typealias Generator = SnapshotGeneratorBy<Comparator>

    /// TODO
    public func generate() -> Generator {
        return undefined()
    }
}

extension SnapshotBy : CollectionType {

    public typealias Index = SnapshotIndexBy<Comparator>

    public var startIndex: Index {
        return undefined()
    }

    public var endIndex: Index {
        return undefined()
    }

    public subscript(index: Index) -> Element {
        return undefined()
    }
    
}

// -----------------------------------------------------------------------------
// MARK: Generator

/// TODO
public struct SnapshotGeneratorBy<C : ComparatorType> : GeneratorType {

    private let snapshot: SnapshotBy<C>
    private let handle: Handle
    
    internal init(snapshot: SnapshotBy<C>) {
        self.snapshot = snapshot
        let db = snapshot.database
        self.handle = Handle(
            leveldb_create_iterator(db.handle.pointer, db.readOptions.pointer),
            leveldb_iter_destroy)
        if let data = snapshot.start?.serializedBytes {
            leveldb_iter_seek(handle.pointer, UnsafePointer<Int8>(data.bytes), UInt(data.length))
        } else {
            leveldb_iter_seek_to_first(handle.pointer)
        }
    }
    
    /// TODO
    public typealias Element = (C.Key, C.Value)
    
    /// TODO
    public mutating func next() -> Element? {
        while leveldb_iter_valid(handle.pointer) != 0 {
            let keyData: NSData = {
                var length: UInt = 0
                let bytes = leveldb_iter_key(self.handle.pointer, &length)
                return NSData(bytesNoCopy: UnsafeMutablePointer<Void>(bytes), length: Int(length), freeWhenDone: false)
            }()
            let valueData: NSData = {
                var length: UInt = 0
                let bytes = leveldb_iter_key(self.handle.pointer, &length)
                return NSData(bytesNoCopy: UnsafeMutablePointer<Void>(bytes), length: Int(length), freeWhenDone: false)
            }()
            var element: Element?
            if let key = C.Key.fromSerializedBytes(keyData) {
                if let end = snapshot.end {
                    switch C.compare(key, end) {
                    case .LT: break
                    case .EQ: if !snapshot.isClosed { return nil }
                    case .GT: return nil
                    }
                }
                if let value = C.Value.fromSerializedBytes(valueData) {
                    element = (key, value)
                }
            }
            leveldb_iter_next(handle.pointer)
            if element != nil { return element }
        }
        return nil
    }
}

// -----------------------------------------------------------------------------
// MARK: Index

public struct SnapshotIndexBy<C : ComparatorType> {
    
    public typealias Comparator = C
    public typealias Key = C.Key
    
    private var key: C.Key
    
    public func successor() -> SnapshotIndexBy {
        return undefined()
    }
    
    public func predecessor() -> SnapshotIndexBy {
        return undefined()
    }
    
}

extension SnapshotIndexBy : TwoWayComparable {
    public func twoWayCompare(to: SnapshotIndexBy) -> Ordering {
        return Comparator.compare(key, to.key)
    }
}

extension SnapshotIndexBy : BidirectionalIndexType {}

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
