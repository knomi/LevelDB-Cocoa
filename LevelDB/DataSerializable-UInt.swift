//
//  DataSerializable-UInt.swift
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation.NSData

extension UInt : DataSerializable {
    public static func fromSerializedData(data: NSData) -> UInt? {
        if let u: UInt64 = fromData(data) where u <= UInt64(UInt.max) {
            return UInt(u)
        } else {
            return nil
        }
    }
    
    public var serializedData: NSData {
        return UInt64(self).serializedData
    }
}

extension UInt8 : DataSerializable {
    public static func fromSerializedData(data: NSData) -> UInt8? {
        return fromData(data)
    }
    
    public var serializedData: NSData {
        return toData(self)
    }
}

extension UInt16 : DataSerializable {
    public static func fromSerializedData(data: NSData) -> UInt16? {
        return fromData(data)
    }
    
    public var serializedData: NSData {
        return toData(UInt8(self >> 8 & 0xff),
                      UInt8(self >> 0 & 0xff))
    }
}

extension UInt32 : DataSerializable {
    public static func fromSerializedData(data: NSData) -> UInt32? {
        return fromData(data)
    }
    
    public var serializedData: NSData {
        return toData(UInt8(self >> 24 & 0xff),
                      UInt8(self >> 16 & 0xff),
                      UInt8(self >>  8 & 0xff),
                      UInt8(self >>  0 & 0xff))
    }
}

extension UInt64 : DataSerializable {
    public static func fromSerializedData(data: NSData) -> UInt64? {
        return fromData(data)
    }
    
    public var serializedData: NSData {
        return toData(UInt8(self >> 56 & 0xff),
                      UInt8(self >> 48 & 0xff),
                      UInt8(self >> 40 & 0xff),
                      UInt8(self >> 32 & 0xff),
                      UInt8(self >> 24 & 0xff),
                      UInt8(self >> 16 & 0xff),
                      UInt8(self >>  8 & 0xff),
                      UInt8(self >>  0 & 0xff))
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

private func toData(bytes: UInt8...) -> NSData {
    return bytes.withUnsafeBufferPointer {ptr in
        return NSData(bytes: ptr.baseAddress, length: ptr.count)
    }
}
