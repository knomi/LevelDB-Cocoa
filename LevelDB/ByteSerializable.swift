//
//  ByteSerializable.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

/// Value type that can be serialised into bytes.
public protocol ByteSerializable {
    
    /// TODO
    class func fromSerializedBytes(data: NSData) -> Self?

    /// TODO
    var serializedBytes: NSData { get }
    
}

extension String : ByteSerializable {
    
    public static func fromSerializedBytes(data: NSData) -> String? {
        return NSString(data: data, encoding: NSUTF8StringEncoding).map {s in s as String}
    }
    
    public var serializedBytes: NSData {
        return dataUsingEncoding(NSUTF8StringEncoding)!
    }

}

extension NSData : ByteSerializable {

    public class func fromSerializedBytes(data: NSData) -> Self? {
        let x = Double()
        return self(data: data)
    }
    
    public var serializedBytes: NSData {
        return self
    }

}
