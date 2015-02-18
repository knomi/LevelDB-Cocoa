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
#pragma mark - LDBLogger

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

- (leveldb_objc::block_logger_t *)impl
{
    return &_impl;
}

@end // LDBLogger

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
    if (!key) {
        return nil;
    }
    
    std::string value;
    auto status = _db->Get(leveldb::ReadOptions{},
                           leveldb_objc::to_Slice(key),
                           &value);
    if (status.ok()) {
        return [NSData dataWithBytes:value.data() length:value.size()];
    } else {
        return nil;
    }
}

- (NSData *)objectForKeyedSubscript:(NSData *)key
{
    return [self objectForKey:key];
}

- (LDBSnapshot *)snapshot
{
    LDB_UNIMPLEMENTED();
    // TODO
}

- (BOOL)setObject:(NSData *)object forKey:(NSData *)key
{
    if (!key) {
        return NO;
    }

    if (object) {
        auto status = _db->Put(leveldb::WriteOptions{},
                               leveldb_objc::to_Slice(key),
                               leveldb_objc::to_Slice(object));
        return status.ok();
    } else {
        auto status = _db->Delete(leveldb::WriteOptions{},
                                  leveldb_objc::to_Slice(key));
        return status.ok();
    }
}

- (BOOL)setObject:(NSData *)object forKeyedSubscript:(NSData *)key
{
    return [self setObject:object forKey:key];
}

- (BOOL)removeObjectForKey:(NSData *)key
{
    return [self setObject:nil forKey:key];
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



/// Parse database options and set `_logger`, `_filter_policy` and `_cache` if
/// needed.
- (void)
    _readOptions:(leveldb::Options &)opts
    optionsDictionary:(NSDictionary *)dict
{
    void (^parse)(NSString *key, void (^block)(id value, NSString ** error)) =
        ^(NSString *key, void (^block)(id value, NSString ** error))
    {
        if (id value = dict[key]) {
            NSString *error;
            block(value, &error);
            if (error.length) {
                NSLog(@"[WARN] LevelDB: invalid option %@ for key %@, %@", dict[key], key, error);
            } else {
                NSLog(@"[WARN] LevelDB: invalid option %@ for key %@", dict[key], key);
            }
        }
    };
    
    void (^parse_bool)(NSString *key, bool & option) = ^(NSString *key, bool & option) {
        parse(key, ^(id value, NSString ** error) {
            if (auto number = [NSNumber ldb_cast:value].ldb_bool) {
                option = number.boolValue;
            } else {
                *error = @"";
            }
        });
    };

    void (^parse_int)(NSString *key, int & option) = ^(NSString *key, int & option) {
        parse(key, ^(id value, NSString ** error) {
            if (auto number = [NSNumber ldb_cast:value]) {
                option = number.intValue;
            } else {
                *error = @"";
            }
        });
    };

    void (^parse_size_t)(NSString *key, size_t & option) = ^(NSString *key, size_t & option) {
        parse(key, ^(id value, NSString ** error) {
            if (auto number = [NSNumber ldb_cast:value]) {
                option = number.unsignedLongValue;
            } else {
                *error = @"";
            }
        });
    };

    parse_bool(LDBOptionCreateIfMissing, opts.create_if_missing);
    parse_bool(LDBOptionErrorIfExists, opts.error_if_exists);
    parse_bool(LDBOptionParanoidChecks, opts.paranoid_checks);
    parse_int(LDBOptionMaxOpenFiles, opts.max_open_files);
    parse_int(LDBOptionBlockRestartInterval, opts.block_restart_interval);
    parse_size_t(LDBOptionWriteBufferSize, opts.write_buffer_size);
    parse_size_t(LDBOptionBlockSize, opts.block_size);
    
    // info log
    parse(LDBOptionInfoLog, ^(id value, NSString ** error) {
        if (auto logger = [LDBLogger ldb_cast:value]) {
            _logger = logger;
            opts.info_log = logger.impl;
        }
    });
    
    // block cache (cache capacity)
    parse(LDBOptionCacheCapacity, ^(id value, NSString ** error) {
        if (auto number = [NSNumber ldb_cast:value]) {
            if (size_t capacity = number.unsignedLongValue) {
                using ptr_t = std::unique_ptr<leveldb::Cache>;
                _cache = ptr_t(leveldb::NewLRUCache(capacity));
                opts.block_cache = _cache.get();
            }
        } else {
            *error = @"";
        }
    });
    
    // compression
    parse(LDBOptionCompression, ^(id value, NSString ** error) {
        if (auto number = [NSNumber ldb_cast:value]) {
            if ([number compare:@(LDBCompressionNoCompression)] == NSOrderedSame) {
                opts.compression = leveldb::kNoCompression;
            } else if ([number compare:@(LDBCompressionSnappyCompression)] == NSOrderedSame) {
                opts.compression = leveldb::kSnappyCompression;
            } else {
                *error = @"unrecognized compression type";
            }
        } else {
            *error = @"";
        }
    });
    
    // filter policy (bloom filter bits)
    parse(LDBOptionBloomFilterBits, ^(id value, NSString ** error) {
        if (auto number = [NSNumber ldb_cast:value]) {
            int bits_per_key = number.intValue;
            if (bits_per_key > 0) {
                using ptr_t = std::unique_ptr<leveldb::FilterPolicy const>;
                _filter_policy = ptr_t(leveldb::NewBloomFilterPolicy(bits_per_key));
                opts.filter_policy = _filter_policy.get();
            }
        } else {
            *error = @"";
        }
    });
}

@end // LDBDatabase
