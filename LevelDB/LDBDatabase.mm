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
#include "helpers/memenv/memenv.h"
#include "leveldb/cache.h"
#include "leveldb/db.h"
#include "leveldb/env.h"
#include "leveldb/filter_policy.h"

using namespace leveldb_objc;

NSString * const LDBOptionCreateIfMissing = @"LDBOptionCreateIfMissing";
NSString * const LDBOptionErrorIfExists   = @"LDBOptionErrorIfExists";
NSString * const LDBOptionParanoidChecks  = @"LDBOptionParanoidChecks";
NSString * const LDBOptionWriteBufferSize = @"LDBOptionWriteBufferSize";
NSString * const LDBOptionMaxOpenFiles    = @"LDBOptionMaxOpenFiles";
NSString * const LDBOptionBloomFilterBits = @"LDBOptionBloomFilterBits";
NSString * const LDBOptionCacheCapacity   = @"LDBOptionCacheCapacity";

namespace leveldb_objc {
    static void read_database_options(
        leveldb::Options & opts,
        std::unique_ptr<leveldb::FilterPolicy const> & filter_policy,
        std::unique_ptr<leveldb::Cache> & cache,
        NSDictionary *dict);
}

@interface LDBDatabase () {
    std::unique_ptr<leveldb::Env>                 _env;
    std::unique_ptr<leveldb::FilterPolicy const>  _filter_policy;
    std::unique_ptr<leveldb::Cache>               _cache;
    std::unique_ptr<leveldb::DB>                  _db;
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
    if (!(self = [super init])) {
        return nil;
    }
    
    auto env = std::shared_ptr<leveldb::Env>(
        leveldb::NewMemEnv(leveldb::Env::Default()));
    auto options = leveldb::Options{};
    options.env = env.get();
    options.create_if_missing = true;

    static std::int64_t counter = 0;
    auto name = "leveldb-" + std::to_string(OSAtomicIncrement64(&counter));
    
    leveldb::DB * db = nullptr;
    auto status = leveldb::DB::Open(options, name, &db);

    if (!status.ok()) {
        return nil;
    }

    _db = std::unique_ptr<leveldb::DB>(db);

    return self;
}

- (instancetype)initWithPath:(NSString *)path
{
    auto options = @{
        LDBOptionCreateIfMissing: @YES,
        LDBOptionBloomFilterBits: @10
    };
    return [self initWithPath:path options:options error:NULL];
}

- (instancetype)
    initWithPath:(NSString *)path
    options:(NSDictionary *)optionsDictionary
    error:(NSError * __autoreleasing *)error
{
    if (!(self = [super init])) {
        return nil;
    }
    
    auto options = leveldb::Options{};
    read_database_options(options, _filter_policy, _cache, optionsDictionary);
    leveldb::DB * db = nullptr;
    auto status = leveldb::DB::Open(options, path.UTF8String, &db);

    if (!status.ok()) {
        return nil;
    }

    _db = std::unique_ptr<leveldb::DB>(db);

    return self;
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


/// Parse database options and set `filter_policy` and `cache` if needed.
static void leveldb_objc::read_database_options(
    leveldb::Options & opts,
    std::unique_ptr<leveldb::FilterPolicy const> & filter_policy,
    std::unique_ptr<leveldb::Cache> & cache,
    NSDictionary *dict)
{
#define READ_BOOL(option, key) /******************************************/ \
    do {                                                                    \
        if (id opt = dict[(key)]) {                                         \
            if (auto val = [NSNumber ldb_cast:opt].ldb_bool) {              \
                option = val.boolValue;                                     \
            } else {                                                        \
                NSLog(@"[WARN] LevelDB: Expected BOOL for %@, got %@",      \
                    (key), opt);                                            \
            }                                                               \
        }                                                                   \
    } while (0)                                                             \
    /**/
#define READ_INT(option, key) /*******************************************/ \
    do {                                                                    \
        if (id opt = dict[(key)]) {                                         \
            if (auto val = [NSNumber ldb_cast:opt]) {                       \
                option = val.intValue;                                      \
            } else {                                                        \
                NSLog(@"[WARN] LevelDB: Expected int for %@, got %@",       \
                    (key), opt);                                            \
            }                                                               \
        }                                                                   \
    } while (0)                                                             \
    /**/
#define READ_SIZE_T(option, key) /****************************************/ \
    do {                                                                    \
        if (id opt = dict[(key)]) {                                         \
            if (auto val = [NSNumber ldb_cast:opt]) {                       \
                option = val.unsignedLongValue;                             \
            } else {                                                        \
                NSLog(@"[WARN] LevelDB: Expected size_t for %@, got %@",    \
                    (key), opt);                                            \
            }                                                               \
        }                                                                   \
    } while (0)                                                             \
    /**/

    READ_BOOL(opts.create_if_missing, LDBOptionCreateIfMissing);
    READ_BOOL(opts.error_if_exists,   LDBOptionErrorIfExists);
    READ_BOOL(opts.paranoid_checks,   LDBOptionParanoidChecks);
    READ_INT(opts.max_open_files, LDBOptionMaxOpenFiles);
    READ_SIZE_T(opts.write_buffer_size, LDBOptionWriteBufferSize);

#undef READ_SIZE_T
#undef READ_INT
#undef READ_BOOL

    if (auto x = [NSNumber ldb_cast:dict[LDBOptionBloomFilterBits]]) {
        int bits_per_key = x.intValue;
        if (bits_per_key > 0) {
            using ptr_t = std::unique_ptr<leveldb::FilterPolicy const>;
            filter_policy = ptr_t(leveldb::NewBloomFilterPolicy(bits_per_key));
            opts.filter_policy = filter_policy.get();
        }
    }
    if (auto x = [NSNumber ldb_cast:dict[LDBOptionCacheCapacity]]) {
        if (size_t capacity = x.unsignedLongValue) {
            using ptr_t = std::unique_ptr<leveldb::Cache>;
            cache = ptr_t(leveldb::NewLRUCache(capacity));
            opts.block_cache = cache.get();
        }
    }
}
