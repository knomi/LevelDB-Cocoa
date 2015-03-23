//
//  DataSerializable-Int.swift
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation.NSData

extension Int : DataSerializable {
    public static func fromSerializedData(data: NSData) -> Int? {
        return UInt.fromSerializedData(data).map {u in
            Int(bitPattern: offsetSign(u))
        }
    }
    
    public var serializedData: NSData {
        return offsetSign(UInt(bitPattern: self)).serializedData
    }
}

extension Int8 : DataSerializable {
    public static func fromSerializedData(data: NSData) -> Int8? {
        return UInt8.fromSerializedData(data).map {u in
            Int8(bitPattern: offsetSign(u))
        }
    }
    
    public var serializedData: NSData {
        return offsetSign(UInt8(bitPattern: self)).serializedData
    }
}

extension Int16 : DataSerializable {
    public static func fromSerializedData(data: NSData) -> Int16? {
        return UInt16.fromSerializedData(data).map {u in
            Int16(bitPattern: offsetSign(u))
        }
    }
    
    public var serializedData: NSData {
        return offsetSign(UInt16(bitPattern: self)).serializedData
    }
}

extension Int32 : DataSerializable {
    public static func fromSerializedData(data: NSData) -> Int32? {
        return UInt32.fromSerializedData(data).map {u in
            Int32(bitPattern: offsetSign(u))
        }
    }
    
    public var serializedData: NSData {
        return offsetSign(UInt32(bitPattern: self)).serializedData
    }
}

extension Int64 : DataSerializable {
    public static func fromSerializedData(data: NSData) -> Int64? {
        return UInt64.fromSerializedData(data).map {u in
            Int64(bitPattern: offsetSign(u))
        }
    }
    
    public var serializedData: NSData {
        return offsetSign(UInt64(bitPattern: self)).serializedData
    }
}

// MARK: - Implementation details

private func offsetSign<T : UnsignedIntegerType>(value: T) -> T {
    return value &+ ~(~0 / 2) // 0b10000...000
}
