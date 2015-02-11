//
//  ReverseSnapshot.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

extension Snapshot {

    /// TODO
    public var reverse: ReverseSnapshot<Key, Value> {
        return ReverseSnapshot(reverse: self)
    }

}

public struct ReverseSnapshot<K : KeyType, V : ValueType> {
    
    internal typealias Database = LevelDB.Database<K, V>
    public typealias Key = K
    public typealias Value = V
    public typealias Element = (key: Key, value: Value)
    
    /// TODO
    public let reverse: Snapshot<Key, Value>
    
    /// TODO
    public var dataInterval: HalfOpenInterval<NSData> {
        return reverse.dataInterval
    }

    /// TODO
    public func clamp(#from: Key?, to: Key?) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse.clamp(from: from, to: to))
    }

    /// TODO
    public func clamp(#from: Key?, through: Key?) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse.clamp(from: from, through: through))
    }
    
    /// TODO
    public func after(key: Key) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse.after(key))
    }
    
    /// TODO
    public func prefix(key: Key) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse.prefix(key))
    }

    /// TODO
    public subscript(key: Key) -> Value? {
        return reverse[key]
    }

    /// TODO
    public subscript(interval: HalfOpenInterval<Key>) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse[interval])
    }
    
    /// TODO
    public subscript(interval: ClosedInterval<Key>) -> ReverseSnapshot {
        return ReverseSnapshot(reverse: reverse[interval])
    }
    
    /// TODO
    public var keys: LazySequence<MapSequenceView<ReverseSnapshot, K>> {
        return lazy(self).map {(k, _) in k}
    }
    
    /// TODO
    public var values: LazySequence<MapSequenceView<ReverseSnapshot, V>> {
        return lazy(self).map {(_, v) in v}
    }
    
}

extension ReverseSnapshot : SnapshotType {}
