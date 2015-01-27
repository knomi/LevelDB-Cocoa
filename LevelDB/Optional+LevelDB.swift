//
//  Optional+LevelDB.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 27.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

extension Optional {
    internal func flatMap<U>(transform: T -> U?) -> U? {
        return self.map(transform)?
    }
}
