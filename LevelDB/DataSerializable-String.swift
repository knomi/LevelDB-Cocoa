//
//  DataSerializable-String.swift
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation.NSData

extension String : DataSerializable {
    public static func fromSerializedData(data: NSData) -> String? {
        return String(data: data, encoding: NSUTF8StringEncoding)
    }
    
    public var serializedData: NSData {
        return dataUsingEncoding(NSUTF8StringEncoding)!
    }
}
