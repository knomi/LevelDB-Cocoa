//
//  LevelDB.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 26.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

public typealias DefaultComparator = BytewiseComparator

public typealias Database   = DatabaseBy   <DefaultComparator>
public typealias Snapshot   = SnapshotBy   <DefaultComparator>
public typealias WriteBatch = WriteBatchBy <DefaultComparator>
public typealias Key        = KeyBy        <DefaultComparator>
//public typealias RevKey     = KeyBy        <DefaultComparator.Reverse>

public func destroyDatabase(directoryPath: String) -> Either<String, ()> {
    let options = Handle(leveldb_options_create(), leveldb_options_destroy)
    let name = (directoryPath as NSString).UTF8String
    return tryC({error in leveldb_destroy_db(options.pointer, name, error)})
}

public func repairDatabase(directoryPath: String) -> Either<String, ()> {
    let options = Handle(leveldb_options_create(), leveldb_options_destroy)
    let name = (directoryPath as NSString).UTF8String
    return tryC({error in leveldb_repair_db(options.pointer, name, error)})
}

// MARK: implementation details

#if DEBUG
@noreturn internal func undefined<T>(function: StaticString = __FUNCTION__,
                                     file:     StaticString = __FILE__,
                                     line:     UWord = __LINE__) -> T
{
    fatalError("\(file):\(line): undefined \(function)")
}
#endif
