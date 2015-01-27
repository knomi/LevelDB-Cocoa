//
//  Key.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 27.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

/// TODO
public struct KeyBy<C : ComparatorType> : Comparable {
    public let key: C.Key
    
    public init(_ key: C.Key) {
        self.key = key
    }
}

extension KeyBy : Printable {
    public var description: String {
        return "KeyBy" // TODO
    }
}

// MARK: Operators

public func == <C : ComparatorType>(left: KeyBy<C>, right: KeyBy<C>) -> Bool {
    return C.compare(left.key, right.key) == .OrderedSame
}

public func < <C : ComparatorType>(left: KeyBy<C>, right: KeyBy<C>) -> Bool {
    return C.compare(left.key, right.key).rawValue < 0
}
