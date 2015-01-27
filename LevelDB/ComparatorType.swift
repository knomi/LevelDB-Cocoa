//
//  ComparatorType.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 26.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

/// TODO
public protocol ComparatorType {

    /// TODO
    typealias Key
    
    /// TODO
    typealias Value

    /// TODO
    class var name: StaticString { get }

    /// TODO
    class func compare(left: Key, _ right: Key) -> NSComparisonResult

}
