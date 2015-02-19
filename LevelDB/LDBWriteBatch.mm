//
//  LDBWriteBatch.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBWriteBatch.h"
#import "LDBPrivate.hpp"
#include "leveldb/write_batch.h"

@interface LDBWriteBatch () {
    leveldb::WriteBatch _impl;
}
@end

@implementation LDBWriteBatch

- (void)setObject:(NSData *)data forKeyedSubscript:(NSData *)key
{
    [self setData:data forKey:key];
}

- (void)setData:(NSData *)data forKey:(NSData *)key
{
    LDB_UNIMPLEMENTED();
}

- (void)removeDataForKey:(NSData *)key
{
    LDB_UNIMPLEMENTED();
}

- (void)removeAllData
{
    LDB_UNIMPLEMENTED();
}

- (void)enumerate:(void (^)(NSData *key, NSData *data, BOOL *stop))block
{
    LDB_UNIMPLEMENTED();
}

- (NSUInteger)
    countByEnumeratingWithState:(NSFastEnumerationState *)enumerationState
    objects:(id __unsafe_unretained [])stackBuffer
    count:(NSUInteger)bufferSize
{
    // NSFastEnumerationState:
    // - state:        unsigned long            -- initially 0, change before
    //                                             returning
    // - itemsPtr:     id __unsafe_unretained * -- initially NULL, set to
    //                                             stackBuffer or own buffer
    // - mutationsPtr: unsigned long *          -- initially NULL, set to point
    //                                             to a memory location that
    //                                             changes along with self
    // - extra:        unsigned long[5]         -- initially 0's, free to use
    //                                             for local enumeration state

    LDB_UNIMPLEMENTED();
}

@end

@implementation LDBWriteBatch (Private)
- (leveldb::WriteBatch *)impl
{
    return &_impl;
}
@end
