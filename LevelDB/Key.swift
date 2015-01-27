//
//  Key.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 27.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

/// TODO
public struct KeyBy<C : ComparatorType where C.Reverse : ComparatorType> : TwoWayComparable {

    public typealias Comparator = C

    public let key: C.Key
    
    public init(_ key: C.Key) {
        self.key = key
    }
    
    public func twoWayCompare(to: KeyBy) -> Ordering {
        return C.compare(key, to.key)
    }

}

extension KeyBy : Printable {
    public var description: String {
        return "KeyBy" // TODO
    }
}
