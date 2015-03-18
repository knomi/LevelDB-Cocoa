//
//  DataSerializable-UInt.swift
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation.NSData

extension UInt : DataSerializable {
    public init?(serializedData data: NSData) {
        if let u: UInt64 = fromData(data) {
            if u <= UInt64(UInt.max) {
                self = UInt(u)
            }
        }
        return nil
    }
    
    public var serializedData: NSData {
        return toData(UInt64(self))
    }
}

extension UInt8 : DataSerializable {
    public init?(serializedData data: NSData) {
        if let u: UInt8 = fromData(data) { self = u } else { return nil }
    }
    
    public var serializedData: NSData {
        return toData(self)
    }
}

extension UInt16 : DataSerializable {
    public init?(serializedData data: NSData) {
        if let u: UInt16 = fromData(data) { self = u } else { return nil }
    }
    
    public var serializedData: NSData {
        return toData(bigEndian)
    }
}

extension UInt32 : DataSerializable {
    public init?(serializedData data: NSData) {
        if let u: UInt32 = fromData(data) { self = u } else { return nil }
    }
    
    public var serializedData: NSData {
        return toData(bigEndian)
    }
}

extension UInt64 : DataSerializable {
    public init?(serializedData data: NSData) {
        if let u: UInt64 = fromData(data) { self = u } else { return nil }
    }
    
    public var serializedData: NSData {
        return toData(bigEndian)
    }
}

// MARK: - Implementation details

private func fromData<T : UnsignedIntegerType>(data: NSData) -> T? {
    if (data.length != sizeof(T)) {
        return nil
    } else {
        let bytes = UnsafeBufferPointer(start: UnsafePointer<UInt8>(data.bytes), count: data.length)
        return T(reduce(bytes, UIntMax(0)) {total, n in total * 256 + UIntMax(n)})
    }
}

private func toData<T>(var value: T) -> NSData {
    return NSData(bytes: &value, length: sizeof(T))
}
