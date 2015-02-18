//
//  LDBWriteBatch.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBWriteBatch.h"
#import "LDBPrivate.hpp"

@implementation LDBWriteBatch

- (void)setObject:(NSData *)object forKeyedSubscript:(NSData *)key
{
    LDB_UNIMPLEMENTED();
}

- (void)setData:(NSData *)data forKey:(NSData *)key
{
    LDB_UNIMPLEMENTED();
}

- (void)removeDataForKey:(NSData *)key
{
    LDB_UNIMPLEMENTED();
}

- (void)enumerate:(void (^)(NSData *key, NSData *data, BOOL *stop))block
{
    LDB_UNIMPLEMENTED();
}

- (NSUInteger)
    countByEnumeratingWithState:(NSFastEnumerationState *)state
    objects:(id __unsafe_unretained [])buffer
    count:(NSUInteger)len
{
    LDB_UNIMPLEMENTED();
}

@end
