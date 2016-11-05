//
//  DataSerializable-NSData.swift
//  LevelDB-Cocoa
//
//  Created by Pyry Jahkola on 23.03.2015.
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

extension Data : DataSerializable {
    public static func fromSerializedData(_ data: Data) -> Data? {
        return data
    }
    
    public var serializedData: Data {
        return self
    }
}
