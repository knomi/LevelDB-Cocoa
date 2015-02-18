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

// -----------------------------------------------------------------------------
#pragma mark - Constants

NSString * const LDBOptionCreateIfMissing      = @"LDBOptionCreateIfMissing";
NSString * const LDBOptionErrorIfExists        = @"LDBOptionErrorIfExists";
NSString * const LDBOptionParanoidChecks       = @"LDBOptionParanoidChecks";
// - no `env` option yet
NSString * const LDBOptionInfoLog              = @"LDBOptionInfoLog";
NSString * const LDBOptionWriteBufferSize      = @"LDBOptionWriteBufferSize";
NSString * const LDBOptionMaxOpenFiles         = @"LDBOptionMaxOpenFiles";
NSString * const LDBOptionCacheCapacity        = @"LDBOptionCacheCapacity";
NSString * const LDBOptionBlockSize            = @"LDBOptionBlockSize";
NSString * const LDBOptionBlockRestartInterval = @"LDBOptionBlockRestartInterval";
NSString * const LDBOptionCompression          = @"LDBOptionCompression";
NSString * const LDBOptionBloomFilterBits      = @"LDBOptionBloomFilterBits";

// -----------------------------------------------------------------------------
#pragma mark - leveldb_objc::block_logger_t

namespace leveldb_objc {

struct block_logger_t : leveldb::Logger {

    void (^block)(NSString *message);
    
    virtual void Logv(const char* f, va_list a) override {
        if (!block) return;
        auto m = [[NSString alloc] initWithFormat:@(f) locale:nil arguments:a];
        if (m) block(m);
    }
    
};

} // namespace leveldb_objc

// -----------------------------------------------------------------------------
#pragma mark - LDBDatabase

@interface LDBDatabase () {
    std::unique_ptr<leveldb::Env>                 _env;
    LDBLogger *                                   _logger;
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
    return leveldb_objc::objc_result(status, error);
}

+ (BOOL)
    repairDatabaseWithPath:(NSString *)path
    error:(NSError * __autoreleasing *)error;
{
    auto options = leveldb::Options{};
    auto status = leveldb::RepairDB(path.UTF8String, options);
    return leveldb_objc::objc_result(status, error);
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
    [self _readOptions:options optionsDictionary:optionsDictionary];
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


// -----------------------------------------------------------------------------
#pragma mark - Private parts

void readOption(int & option, NSDictionary *dict, NSString *key, BOOL (^valid)(int value))
{
    if (id input = dict[key]) {
        auto number = [NSNumber ldb_cast:input];
        if (number && valid(number.intValue)) {
            option = number.intValue;
        } else {
            NSLog(@"[WARN] LevelDB: invalid value %@ for option %@", input, key);
        }
    }
}

/// Parse database options and set `_logger`, `_filter_policy` and `_cache` if
/// needed.
- (void)
    _readOptions:(leveldb::Options &)opts
    optionsDictionary:(NSDictionary *)dict
{
    // create if missing
    
    // error if exists
    
    
    // paranoid checks
    
    // logger
    
    // write buffer size

    readOption(opts.create_if_missing, dict, LDBOptionCreateIfMissing, ^{});
    READ_BOOL(opts.error_if_exists,   LDBOptionErrorIfExists);
    READ_BOOL(opts.paranoid_checks,   LDBOptionParanoidChecks);
    READ_INT(opts.max_open_files, LDBOptionMaxOpenFiles);
    READ_SIZE_T(opts.write_buffer_size, LDBOptionWriteBufferSize);

    if (auto x = [NSNumber ldb_cast:dict[LDBOptionBloomFilterBits]]) {
        int bits_per_key = x.intValue;
        if (bits_per_key > 0) {
            using ptr_t = std::unique_ptr<leveldb::FilterPolicy const>;
            _filter_policy = ptr_t(leveldb::NewBloomFilterPolicy(bits_per_key));
            opts.filter_policy = _filter_policy.get();
        }
    }
    if (auto x = [NSNumber ldb_cast:dict[LDBOptionCacheCapacity]]) {
        if (size_t capacity = x.unsignedLongValue) {
            using ptr_t = std::unique_ptr<leveldb::Cache>;
            _cache = ptr_t(leveldb::NewLRUCache(capacity));
            opts.block_cache = _cache.get();
        }
    }
}

@end // LDBDatabase

// -----------------------------------------------------------------------------
#pragma mark - LDBLogger

@interface LDBLogger () {
    leveldb_objc::block_logger_t _impl;
}

@end

@implementation LDBLogger : NSObject

+ (instancetype)loggerWithBlock:(void (^)(NSString *message))block
{
    return [[self alloc] initWithBlock:block];
}

- (instancetype)initWithBlock:(void (^)(NSString *message))block
{
    if (!(self = [super init])) {
        return nil;
    }
    _impl.block = block;
    return self;
}

- (void (^)(NSString *))block
{
    return _impl.block;
}

@end // LDBLogger
