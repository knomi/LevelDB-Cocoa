//
//  LDBError.m
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBError.h"

NSString * const LDBErrorDomain = @"pyrtsa.leveldb";

NSString * const LDBErrorMessageKey = @"LDBErrorMessageKey";

@implementation NSError (LevelDB)

- (NSString *)ldb_errorMessage
{
    return [self.userInfo[LDBErrorMessageKey] copy];
}

@end
