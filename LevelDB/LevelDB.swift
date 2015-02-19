//
//  LevelDB.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation.NSError
import LevelDB
import protocol Allsorts.Orderable

/// An orderable type which preserves the order after byte serialization:
///
/// ```swift
/// (a <=> b) == (a.serializedBytes <=> b.serializedBytes)
/// ```
public typealias ByteSerializeableKey = protocol<ByteSerializable, Orderable>

public func destroyDatabase(directoryPath: String, inout error: NSError?) -> Bool {
    return LDBDatabase.destroyDatabaseAtPath(directoryPath, error: &error)
}

public func repairDatabase(directoryPath: String, inout error: NSError?) -> Bool {
    return LDBDatabase.destroyDatabaseAtPath(directoryPath, error: &error)
}
