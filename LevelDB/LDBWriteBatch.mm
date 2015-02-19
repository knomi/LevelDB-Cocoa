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
    unsigned long _mutations;
}
@end

@implementation LDBWriteBatch

- (void)setObject:(NSData *)data forKeyedSubscript:(NSData *)key
{
    [self setData:data forKey:key];
}

- (void)setData:(NSData *)data forKey:(NSData *)key
{
    if (!key) {
        return;
    }
    
    if (data) {
        _impl.Put(leveldb_objc::to_Slice(key),
                  leveldb_objc::to_Slice(data));
    } else {
        _impl.Delete(leveldb_objc::to_Slice(key));
    }
    
    _mutations++;
}

- (void)removeDataForKey:(NSData *)key
{
    [self setData:nil forKey:key];
}

- (void)removeAllData
{
    _impl.Clear();
    _mutations++;
}

- (void)enumerate:(void (^)(NSData *key, NSData *data))block
{
    struct enumerator_t : leveldb::WriteBatch::Handler {
        void (^block)(NSData *key, NSData *data);
        virtual void Put(const leveldb::Slice &key,
                         const leveldb::Slice &value) override
        {
            block([NSData dataWithBytes:key.data() length:key.size()],
                  [NSData dataWithBytes:value.data() length:key.size()]);
        }
        virtual void Delete(const leveldb::Slice &key) override
        {
            block([NSData dataWithBytes:key.data() length:key.size()], nil);
        }
    };
    enumerator_t it;
    it.block = block;
    auto status = _impl.Iterate(&it);
    if (!status.ok()) {
        // It seems like iteration errors may only happen because of a bug
        // inside the LevelDB C++ implementation. Thus only reporting the error
        // in NSLog because user errors aren't expected to show up here.
        NSLog(@"[WARN] LDBWriteBatch enumeration error: %s",
              status.ToString().c_str());
    }
}

//- (NSUInteger)
//    countByEnumeratingWithState:(NSFastEnumerationState *)enumerationState
//    objects:(id __unsafe_unretained [])stackBuffer
//    count:(NSUInteger)bufferSize
//{
//    // NSFastEnumerationState:
//    // - state:        unsigned long            -- initially 0, change before
//    //                                             returning
//    // - itemsPtr:     id __unsafe_unretained * -- initially NULL, set to
//    //                                             stackBuffer or own buffer
//    // - mutationsPtr: unsigned long *          -- initially NULL, set to point
//    //                                             to a memory location that
//    //                                             changes along with self
//    // - extra:        unsigned long[5]         -- initially 0's, free to use
//    //                                             for local enumeration state
//
//    enumerationState->mutationsPtr = &_mutations;
//    LDB_UNIMPLEMENTED();
//}

@end

@implementation LDBWriteBatch (Private)
- (leveldb::WriteBatch *)private_batch
{
    return &_impl;
}
@end
