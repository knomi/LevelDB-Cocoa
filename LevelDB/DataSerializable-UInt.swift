//
//  DataSerializable-UInt.swift
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation.NSData

extension UInt : DataSerializable {
    public static func fromSerializedData(_ data: Data) -> UInt? {
        if let u: UInt64 = fromData(data), u <= UInt64(UInt.max) {
            return UInt(u)
        } else {
            return nil
        }
    }
    
    public var serializedData: Data {
        return UInt64(self).serializedData
    }
}

extension UInt8 : DataSerializable {
    public static func fromSerializedData(_ data: Data) -> UInt8? {
        return fromData(data)
    }
    
    public var serializedData: Data {
        return toData(self)
    }
}

extension UInt16 : DataSerializable {
    public static func fromSerializedData(_ data: Data) -> UInt16? {
        return fromData(data)
    }
    
    public var serializedData: Data {
        return toData(UInt8(self >> 8 & 0xff),
                      UInt8(self >> 0 & 0xff))
    }
}

extension UInt32 : DataSerializable {
    public static func fromSerializedData(_ data: Data) -> UInt32? {
        return fromData(data)
    }
    
    public var serializedData: Data {
        return toData(UInt8(self >> 24 & 0xff),
                      UInt8(self >> 16 & 0xff),
                      UInt8(self >>  8 & 0xff),
                      UInt8(self >>  0 & 0xff))
    }
}

extension UInt64 : DataSerializable {
    public static func fromSerializedData(_ data: Data) -> UInt64? {
        return fromData(data)
    }
    
    public var serializedData: Data {
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

private func fromData<T : UnsignedInteger>(_ data: Data) -> T? {
    if (data.count != MemoryLayout<T>.size) {
        return nil
    } else {
        let bytes = UnsafeBufferPointer(start: (data as NSData).bytes.bindMemory(to: UInt8.self, capacity: data.count), count: data.count)
        return T(bytes.reduce(UIntMax(0)) {total, n -> UIntMax in total * 256 + UIntMax(n)})
    }
}

private func toData(_ bytes: UInt8...) -> Data {
    return bytes.withUnsafeBufferPointer {ptr in
        return Data(bytes: UnsafePointer<UInt8>(ptr.baseAddress!), count: ptr.count)
    }
}
