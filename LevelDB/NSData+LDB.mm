//
//  NSData+LDB.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "NSData+LDB.h"
#import "LDBPrivate.hpp"

@implementation NSData (LDB)

+ (NSComparisonResult)ldb_compareLeft:(NSData *)left right:(NSData *)right
{
    return leveldb_objc::compare(left, right);
}

- (NSData *)ldb_lexicographicalNextSibling
{
    return leveldb_objc::lexicographicalNextSibling(self);
}

- (NSData *)ldb_lexicographicalFirstChild
{
    return leveldb_objc::lexicographicalFirstChild(self);
}

@end
