//
//  LDBDatabase.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBDatabase.h"

#import "LDBSnapshot.h"
#import "LDBWriteBatch.h"
#import "LDBPrivate.hpp"

#include <memory>
#include "leveldb/db.h"

NSString * const LDBOptionCreateIfMissing = @"LDBOptionCreateIfMissing";
NSString * const LDBOptionErrorIfExists   = @"LDBOptionErrorIfExists";
NSString * const LDBOptionParanoidChecks  = @"LDBOptionParanoidChecks";
NSString * const LDBOptionMaxOpenFiles    = @"LDBOptionMaxOpenFiles";
NSString * const LDBOptionBloomFilterBits = @"LDBOptionBloomFilterBits";
NSString * const LDBOptionCacheCapacity   = @"LDBOptionCacheCapacity";

#define LDB_UNIMPLEMENTED() /************************************************/ \
    do {                                                                       \
        NSLog(@"%s:%ull: unimplemented %s", __FILE__, __LINE__, __FUNCTION__); \
        abort();                                                               \
    } while(0)                                                                 \
    /**/

@interface LDBDatabase () {

}

@end

@implementation LDBDatabase

+ (BOOL)
    destroyDatabaseWithPath:(NSString *)path
    error:(NSError * __autoreleasing *)error
{
    auto options = leveldb::Options{};
    auto status = leveldb::DestroyDB(path.UTF8String, options);
    return objc_result(status, error);
}

+ (BOOL)
    repairDatabaseWithPath:(NSString *)path
    error:(NSError * __autoreleasing *)error;
{
    auto options = leveldb::Options{};
    auto status = leveldb::RepairDB(path.UTF8String, options);
    return objc_result(status, error);
}

- (instancetype)init
{
    LDB_UNIMPLEMENTED();
    // TODO
}

- (instancetype)initWithPath:(NSString *)path
{
    LDB_UNIMPLEMENTED();
    // TODO
}

- (instancetype)
    initWithPath:(NSString *)path
    options:(NSDictionary *)options
    error:(NSError * __autoreleasing *)error
{
    LDB_UNIMPLEMENTED();
    // TODO
}

- (NSData *)objectForKey:(NSData *)key
{
    LDB_UNIMPLEMENTED();
    // TODO
}

- (NSData *)objectForKeyedSubscript:(NSData *)key
{
    LDB_UNIMPLEMENTED();
    // TODO
}

- (LDBSnapshot *)snapshot
{
    LDB_UNIMPLEMENTED();
    // TODO
}

- (BOOL)setObject:(NSData *)object forKey:(NSData *)key
{
    LDB_UNIMPLEMENTED();
    // TODO
}

- (BOOL)setObject:(NSData *)object forKeyedSubscript:(NSData *)key
{
    LDB_UNIMPLEMENTED();
    // TODO
}

- (void)removeObjectForKey:(NSData *)key
{
    LDB_UNIMPLEMENTED();
    // TODO
}

- (BOOL)
    write:(LDBWriteBatch *)batch
    sync:(BOOL)sync
    error:(NSError * __autoreleasing *)error
{
    LDB_UNIMPLEMENTED();
    // TODO
}

@end
