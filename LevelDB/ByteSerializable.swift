//
//  ByteSerializable.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 27.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

/// TODO
public protocol ByteSerializable {
    
    /// TODO
    class func fromSerializedBytes(data: NSData) -> Self?

    /// TODO
    var serializedBytes: NSData { get }
    
}

extension NSData : ByteSerializable {

    /// TODO
    public class func fromSerializedBytes(data: NSData) -> Self? {
        return self(bytes: data.bytes, length: data.length)
    }

    /// TODO
    public var serializedBytes: NSData {
        return self
    }

}

extension String : ByteSerializable {
    
    public static func fromSerializedBytes(data: NSData) -> String? {
        return NSString(data: data, encoding: NSUTF8StringEncoding)
    }
    
    public var serializedBytes: NSData {
        return dataUsingEncoding(NSUTF8StringEncoding)!
    }

}
