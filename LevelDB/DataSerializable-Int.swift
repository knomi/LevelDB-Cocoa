//
//  DataSerializable-Int.swift
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation.NSData

extension Int : DataSerializable {
    public init?(serializedData data: NSData) {
        if let u = UInt(serializedData: data) {
            self.init(bitPattern: offsetSign(u))
        } else {
            return nil
        }
    }
    
    public var serializedData: NSData {
        return offsetSign(UInt(bitPattern: self)).serializedData
    }
}

extension Int8 : DataSerializable {
    public init?(serializedData data: NSData) {
        if let u = UInt8(serializedData: data) {
            self.init(bitPattern: offsetSign(u))
        } else {
            return nil
        }
    }
    
    public var serializedData: NSData {
        return offsetSign(UInt8(bitPattern: self)).serializedData
    }
}

extension Int16 : DataSerializable {
    public init?(serializedData data: NSData) {
        if let u = UInt16(serializedData: data) {
            self.init(bitPattern: offsetSign(u))
        } else {
            return nil
        }
    }
    
    public var serializedData: NSData {
        return offsetSign(UInt16(bitPattern: self)).serializedData
    }
}

extension Int32 : DataSerializable {
    public init?(serializedData data: NSData) {
        if let u = UInt32(serializedData: data) {
            self.init(bitPattern: offsetSign(u))
        } else {
            return nil
        }
    }
    
    public var serializedData: NSData {
        return offsetSign(UInt32(bitPattern: self)).serializedData
    }
}

extension Int64 : DataSerializable {
    public init?(serializedData data: NSData) {
        if let u = UInt64(serializedData: data) {
            self.init(bitPattern: offsetSign(u))
        } else {
            return nil
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
