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

    /// Create an instance with the serialized `data`.
    ///
    /// If the result is `.Some(x)`, then `x.serializedData` should be equal to
    /// `data`.
    static func fromSerializedData(_ data: Data) -> Self?
    
    /// Get the serialized data representation of `self`.
    ///
    /// The serialization should round-trip, i.e.
    /// `Self.fromSerializedData(x.serializedData)` should return `.Some(x)` for
    /// all values of `x`.
    var serializedData: Data { get }
    
}
