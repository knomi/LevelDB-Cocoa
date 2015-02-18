//
//  LevelDB.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

import enum LlamaKit.Result
import func LlamaKit.failure
import func LlamaKit.success
import let LlamaKit.ErrorFileKey
import let LlamaKit.ErrorLineKey

public func destroyDatabase(directoryPath: String) -> Result<(), String> {
    let options = Handle(leveldb_options_create(), leveldb_options_destroy)
    let name = (directoryPath as NSString).UTF8String
    return tryC({error in leveldb_destroy_db(options.pointer, name, error)})
}

public func repairDatabase(directoryPath: String) -> Result<(), String> {
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

internal func tryC<T>(block: UnsafeMutablePointer<UnsafeMutablePointer<Int8>> -> T) -> Result<T, String> {
    var error: UnsafeMutablePointer<Int8> = nil
    let result = block(&error)
    if error != nil {
        let string = String.fromCString(error)!
        leveldb_free(error)
        return failure(string)
    } else {
        return success(result)
    }
}

extension Result {
    internal func either<U>(failure: E -> U, _ success: T -> U) -> U {
        switch self {
        case let .Failure(e): return failure(e.unbox)
        case let .Success(x): return success(x.unbox)
        }
    }
}
