//
//  DataSerializable.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

/// Value type that can be serialised into bytes.
public protocol DataSerializable {
    
    /// TODO
    init?(serializedData: NSData)

    /// TODO
    var serializedData: NSData { get }
    
}

extension String : DataSerializable {
    
    public init?(serializedData data: NSData) {
        if let s = NSString(data: data, encoding: NSUTF8StringEncoding) {
            self = s as String
        } else {
            return nil
        }
    }
    
    public var serializedData: NSData {
        return dataUsingEncoding(NSUTF8StringEncoding)!
    }

}
