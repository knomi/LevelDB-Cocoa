//
//  LDBPrivate.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBPrivate.hpp"
#import "LDBError.h"
#include <type_traits>

#define LDB_UNIMPLEMENTED() /************************************************/ \
    do {                                                                       \
        NSLog(@"%s:%ull: unimplemented %s", __FILE__, __LINE__, __FUNCTION__); \
        abort();                                                               \
    } while(0)                                                                 \
    /**/

@implementation NSObject (LevelDB)

+ (instancetype)ldb_cast:(id)object
{
    return [object isKindOfClass:self] ? object : nil;
}

@end


@implementation NSNumber (LevelDB)

- (NSNumber *)ldb_bool
{
    if ((![self compare:@YES] && !strcmp(self.objCType, @YES.objCType)) ||
        (![self compare:@NO] && !strcmp(self.objCType, @NO.objCType)))
    {
        return self;
    } else {
        return nil;
    }
}

@end


namespace leveldb_objc {

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

} // namespace leveldb_objc

