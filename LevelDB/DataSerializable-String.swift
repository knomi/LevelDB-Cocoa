//
//  DataSerializable-String.swift
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation.NSData

extension String : DataSerializable {
    public static func fromSerializedData(_ data: Data) -> String? {
        return String(data: data, encoding: .utf8)
    }
    
    public var serializedData: Data {
        return data(using: .utf8)!
    }
}
