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

    public typealias Comparator = C
    public typealias Key = C.Key
    public typealias Value = C.Value
    public typealias Element = (Key, Value)

    /// TODO
    public let database: DatabaseBy<C>
    
}

/// TODO
public struct SnapshotGeneratorBy<C : ComparatorType> : GeneratorType {
    
    /// TODO
    public typealias Element = SnapshotBy<C>.Element
    
    /// TODO
    public mutating func next() -> Element? {
        return undefined()
    }
    
}

extension SnapshotBy : SequenceType {
    /// TODO
    public typealias Generator = SnapshotGeneratorBy<C>

    /// TODO
    public func generate() -> Generator {
        return undefined()
    }
}

public struct SnapshotIndexBy<C : ComparatorType> : BidirectionalIndexType {
    
    public func successor() -> SnapshotIndexBy {
        return undefined()
    }
    
    public func predecessor() -> SnapshotIndexBy {
        return undefined()
    }
    
}

public func == <C : ComparatorType>(left: SnapshotIndexBy<C>,
                                    right: SnapshotIndexBy<C>) -> Bool
{
    return undefined()
}

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
