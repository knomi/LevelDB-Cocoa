//
//  LDBPrivate.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBPrivate.hpp"
#import "LDBError.h"

BOOL objc_result(leveldb::Status const & status,
                 NSError * __autoreleasing * error)
{
    if (!status.ok()) {
        if (error) {
            *error = to_NSError(status);
        }
        return NO;
    } else {
        return YES;
    }
}

NSError * to_NSError(leveldb::Status const & status)
{
    if (status.ok()) {
        return nil;
    }

    auto const message = status.ToString();
    auto const userInfo = @{
        LDBErrorMessageKey: [NSString stringWithUTF8String:message.c_str()]
    };

    LDBError const code = status.IsNotFound()   ? LDBErrorNotFound
                        : status.IsCorruption() ? LDBErrorCorruption
                        : status.IsIOError()    ? LDBErrorIOError
                                                : LDBErrorOther;

    return [NSError errorWithDomain:LDBErrorDomain code:code userInfo:userInfo];
}
