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
    std::shared_ptr<leveldb::WriteBatch> _impl;
    unsigned long _mutations;
}
@end

@implementation LDBWriteBatch

- (instancetype)init
{
    return [self initWithPrefix:[NSData data]];
}

- (instancetype)initWithPrefix:(NSData *)prefix
{
    if (!(self = [super init])) return nil;
    _impl = std::make_shared<leveldb::WriteBatch>();
    _prefix = [prefix copy];
    return self;
}

- (instancetype)initWithImpl:(std::shared_ptr<leveldb::WriteBatch> const &)impl prefix:(NSData *)prefix
{
    if (!(self = [super init])) return nil;
    _impl = impl;
    _prefix = [prefix copy];
    return self;
}

- (LDBWriteBatch *)prefixed:(NSData *)prefix
{
    return [[LDBWriteBatch alloc] initWithImpl:_impl prefix:leveldb_objc::concat(self.prefix, prefix)];
}

- (NSData *)objectForKeyedSubscript:(NSData *)key
{
    return nil;
}

- (void)setObject:(NSData *)data forKeyedSubscript:(NSData *)key
{
    [self setData:data forKey:key];
}

- (void)setData:(NSData *)data forKey:(NSData *)key
{
    namespace ldb = leveldb_objc;
    if (!key) {
        return;
    }
    
    if (data) {
        _impl->Put(ldb::to_Slice(ldb::concat(self.prefix, key)),
                   ldb::to_Slice(data));
    } else {
        _impl->Delete(ldb::to_Slice(ldb::concat(self.prefix, key)));
    }
    
    _mutations++;
}

- (void)removeDataForKey:(NSData *)key
{
    [self setData:nil forKey:key];
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
    auto status = _impl->Iterate(&it);
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
    return _impl.get();
}
@end
