//
//  DataSerializable-NSData.swift
//  LevelDB-Cocoa
//
//  Created by Pyry Jahkola on 23.03.2015.
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

extension NSData : DataSerializable {
    public class func fromSerializedData(data: NSData) -> Self? {
        return self.init(data: data)
    }
    
    public var serializedData: NSData {
        return self
    }
}
