//
//  LevelDB.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

public typealias KeyType = protocol<ByteSerializable, ThreeWayComparable>

public typealias ValueType = ByteSerializable

public typealias ByteDatabase = Database<NSData, NSData>

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

internal func tryC<T>(block: UnsafeMutablePointer<UnsafeMutablePointer<Int8>> -> T) -> Either<String, T> {
    var error: UnsafeMutablePointer<Int8> = nil
    let result = block(&error)
    if error != nil {
        let string = String.fromCString(error)!
        leveldb_free(error)
        return .error(string)
    } else {
        return .value(result)
    }
}
