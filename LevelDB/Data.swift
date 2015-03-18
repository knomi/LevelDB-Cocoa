//
//  Data.swift
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

public struct Data {
    public typealias ByteArray = [UInt8]

    public var bytes: ByteArray
    
    public init() {
        self.bytes = []
    }
    
    public init(_ bytes: [UInt8]) {
        self.bytes = bytes
    }
}

extension Data : SequenceType {
    public typealias Generator = ByteArray.Generator
    
    public func generate() -> Generator {
        return bytes.generate()
    }
}

extension Data : MutableCollectionType {
    public typealias Index = ByteArray.Index

    public var startIndex: Index { return bytes.startIndex }
    
    public var endIndex: Index { return bytes.endIndex }

    public subscript (position: Index) -> Generator.Element {
        get { return bytes[position] }
        set { bytes[position] = newValue }
    }
}

extension Data : Equatable {}

public func == (a: Data, b: Data) -> Bool {
    return equal(a, b)
}

extension Data : Comparable {}

public func < (a: Data, b: Data) -> Bool {
    return lexicographicalCompare(a, b)
}

extension Data : DataSerializable {
    public init?(serializedData data: NSData) {
        var bytes = [UInt8]()
        bytes.reserveCapacity(data.length)
        data.enumerateByteRangesUsingBlock {ptr, range, stop in
            bytes.extend(UnsafeBufferPointer(start: UnsafePointer<UInt8>(ptr),
                                             count: range.length))
        }
        self.bytes = bytes
    }
    
    public var serializedData: NSData {
        return bytes.withUnsafeBufferPointer {ptr in
            NSData(bytes: ptr.baseAddress, length: ptr.count)
        }
    }
}
