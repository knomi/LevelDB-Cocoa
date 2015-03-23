//
//  DataSerializable.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation.NSData

/// Value type that can be serialised into bytes.
///
/// If the type is both Comparable and DataSerializable, it *should* implement
/// this serialization such that the relative ordering of values is preserved in
/// the lexicographic ordering of the produced `NSData` objects.
public protocol DataSerializable {

    /// TODO
    class func fromSerializedData(data: NSData) -> Self?
    
    /// TODO
    var serializedData: NSData { get }
    
}
