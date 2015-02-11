//
//  NSData+LevelDB.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

private var infiniteBytes = Array(count: 1024, repeatedValue: UInt8.max)
private let infinityInstance = Infinity()
private let infinityError: StaticString = "trying to read all bytes of NSData.infinity"

public extension NSData {

    /// TODO
    public class var infinity: NSData {
        return infinityInstance
    }
    
    @objc public var isInfinity: Bool {
        return self is Infinity
    }

    /// TODO
    public func lexicographicNextSibling() -> NSData {
        if isInfinity {
            return self
        }
        let copy = mutableCopy() as NSMutableData
        let bytes = UnsafeMutableBufferPointer<UInt8>(
            start: UnsafeMutablePointer<UInt8>(copy.mutableBytes),
            count: copy.length
        )
        for i in reverse(indices(bytes)) {
            if bytes[i] < UInt8.max {
                bytes[i]++
                for j in i + 1 ..< bytes.count {
                    bytes[j] = 0
                }
                return NSData(data: copy)
            }
        }
        return NSData.infinity
    }

    /// TODO
    public func lexicographicFirstChild() -> NSData {
        if isInfinity {
            return self
        }
        let copy = mutableCopy() as NSMutableData
        [UInt8(0)].withUnsafeBufferPointer {bytes -> () in
            copy.appendBytes(bytes.baseAddress, length: bytes.count)
            return ()
        }
        return NSData(data: copy)
    }

}

private class Infinity: NSData {

    @objc override var length: Int {
        return Int.max
    }
    
    @objc override var bytes: UnsafePointer<Void> {
        assert(false, "\(__FUNCTION__): \(infinityError)")
        return nil
    }
    
    @objc override var description: String {
        return "NSData.infinity"
    }
    
    override func enumerateByteRangesUsingBlock(block:
        (UnsafePointer<Void>, NSRange, UnsafeMutablePointer<ObjCBool>) -> Void)
    {
        var stop: ObjCBool = false
        for (var i = 0; !stop; i += infiniteBytes.count) {
            block(&infiniteBytes, NSMakeRange(i, infiniteBytes.count), &stop)
        }
    }
    
    override func getBytes(buffer: UnsafeMutablePointer<Void>, length: Int) {
        let bytes = UnsafeMutableBufferPointer<UInt8>(start: UnsafeMutablePointer(buffer), count: length)
        for i in 0 ..< length {
            bytes[i] = UInt8.max
        }
    }
    
    override func getBytes(buffer: UnsafeMutablePointer<Void>, range: NSRange) {
        let bytes = UnsafeMutableBufferPointer<UInt8>(start: UnsafeMutablePointer(buffer), count: range.length)
        for i in 0 ..< range.length {
            bytes[i] = UInt8.max
        }
    }
    
    override func subdataWithRange(range: NSRange) -> NSData {
        let data = NSMutableData(length: range.length)!
        getBytes(data.mutableBytes, range: range)
        return data
    }
    
    // Default implementation is "okay".
//    override func rangeOfData(dataToFind: NSData, options mask: NSDataSearchOptions, range searchRange: NSRange) -> NSRange
    
    override func base64EncodedDataWithOptions(options: NSDataBase64EncodingOptions) -> NSData {
        assert(false, "\(__FUNCTION__): \(infinityError)")
        return NSData()
    }
    
    override func base64EncodedStringWithOptions(options: NSDataBase64EncodingOptions) -> String {
        assert(false, "\(__FUNCTION__): \(infinityError)")
        return ""
    }
    
    override func isEqualToData(other: NSData) -> Bool {
        return other is Infinity
    }
    
    override func isEqual(other: AnyObject?) -> Bool {
        return other is Infinity
    }
    
    override func writeToFile(path: String, atomically useAuxiliaryFile: Bool) -> Bool {
        return false
    }
    
    override func writeToFile(path: String, options writeOptionsMask: NSDataWritingOptions, error errorPtr: NSErrorPointer) -> Bool {
        if errorPtr != nil {
            errorPtr.memory = NSError(domain: "leveldb.NSData.infinity", code: 666, userInfo: nil)
        }
        return false
    }
    
    override func writeToURL(url: NSURL, atomically: Bool) -> Bool {
        return false
    }
    
    override func writeToURL(url: NSURL, options writeOptionsMask: NSDataWritingOptions, error errorPtr: NSErrorPointer) -> Bool {
        if errorPtr != nil {
            errorPtr.memory = NSError(domain: "leveldb.NSData.infinity", code: 666, userInfo: nil)
        }
        return false
    }
    
}
