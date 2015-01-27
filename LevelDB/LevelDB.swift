//
//  LevelDB.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 26.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

//public typealias DefaultComparator = LexicographicBytes
//
//public typealias Database   = DatabaseBy   <DefaultComparator>
//public typealias Snapshot   = SnapshotBy   <DefaultComparator>
//public typealias WriteBatch = WriteBatchBy <DefaultComparator>
//public typealias Key        = KeyBy        <DefaultComparator>
//public typealias RevKey     = RevKeyBy     <DefaultComparator>

// MARK: implementation details

#if DEBUG
@noreturn internal func undefined<T>(function: StaticString = __FUNCTION__,
                                     file:     StaticString = __FILE__,
                                     line:     UWord = __LINE__) -> T
{
    fatalError("\(file):\(line): undefined \(function)")
}
#endif
