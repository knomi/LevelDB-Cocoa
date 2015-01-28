//
//  Optional+LevelDB.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

extension Optional {
    internal func flatMap<U>(transform: T -> U?) -> U? {
        return self.map(transform)?
    }
}
