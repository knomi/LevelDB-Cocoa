//
//  LDBSnapshot.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBSnapshot.h"

#import "LDBDatabase.h"
#import "LDBEnumerator.h"
#import "LDBInterval.h"
#import "LDBPrivate.hpp"
#import "NSData+LDB.h"

#include "leveldb/db.h"

#include <memory>
#include <functional>

namespace leveldb_objc {

struct snapshot_t final {
    LDBDatabase * database;
    leveldb::Snapshot const * snapshot;
    
    explicit snapshot_t(LDBDatabase *database)
        : database(database)
        , snapshot(database.private_database->GetSnapshot())
    {}
    
    ~snapshot_t() {
        database.private_database->ReleaseSnapshot(snapshot);
    }
private:
    snapshot_t(snapshot_t &) = delete;
    void operator=(snapshot_t &) = delete;
};

} // namespace leveldb_objc

@implementation LDBSnapshot {
    std::shared_ptr<leveldb_objc::snapshot_t const> _impl;
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class LDBSnapshot"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initWithDatabase:(LDBDatabase *)database
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _impl = std::make_shared<leveldb_objc::snapshot_t const>(database);
    _prefix = [NSData data];
    _interval = [LDBInterval everything];
    
    return self;
}

- (instancetype)
    initWithImpl:(std::shared_ptr<leveldb_objc::snapshot_t const>)impl
    prefix:(NSData *)prefix
    interval:(LDBInterval *)interval
    reversed:(BOOL)isReversed
    noncaching:(BOOL)isNoncaching
    checksummed:(BOOL)isChecksummed
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _impl          = impl;
    _prefix        = [prefix copy];
    _interval      = interval;
    _isReversed    = isReversed;
    _isNoncaching  = isNoncaching;
    _isChecksummed = isChecksummed;
    
    return self;
}

- (LDBSnapshot *)noncaching
{
    return [[LDBSnapshot alloc]
        initWithImpl: _impl
        prefix:       self.prefix
        interval:     self.interval
        reversed:     self.isReversed
        noncaching:   YES
        checksummed:  self.isChecksummed];
}

- (LDBSnapshot *)checksummed
{
    return [[LDBSnapshot alloc]
        initWithImpl: _impl
        prefix:       self.prefix
        interval:     self.interval
        reversed:     self.isReversed
        noncaching:   self.isNoncaching
        checksummed:  YES];
}

- (LDBSnapshot *)reversed
{
    return [[LDBSnapshot alloc]
        initWithImpl: _impl
        prefix:       self.prefix
        interval:     self.interval
        reversed:     !self.isReversed
        noncaching:   self.isNoncaching
        checksummed:  self.isChecksummed];
}

- (NSData *)start
{
    return self.interval.start;
}

- (NSData *)end
{
    return self.interval.end;
}

- (BOOL)isClamped
{
    return ![self.interval isEqual:[LDBInterval everything]];
}

- (LDBSnapshot *)clampStart:(NSData *)start end:(NSData *)end
{
    return [self clampToInterval:[LDBInterval
        intervalWithStart:start
        end:end]];
}

- (LDBSnapshot *)clampToInterval:(LDBInterval *)interval
{
    return [[LDBSnapshot alloc]
        initWithImpl: _impl
        prefix:       self.prefix
        interval:     [interval clamp:self.interval]
        reversed:     self.isReversed
        noncaching:   self.isNoncaching
        checksummed:  self.isChecksummed];
}

- (LDBSnapshot *)after:(NSData *)exclusiveStart
{
    auto start = leveldb_objc::lexicographicalFirstChild(exclusiveStart);
    return [self clampStart:start end:self.end];
}

- (LDBSnapshot *)prefixed:(NSData *)prefix
{
    namespace ldb = leveldb_objc;
    if (prefix == nil) {
        return self;
    }
    auto start = ldb::cutPrefix(prefix, self.start);
    auto end   = ldb::cutPrefix(prefix, self.end);
    return [[LDBSnapshot alloc]
        initWithImpl: _impl
        prefix:       ldb::concat(self.prefix, prefix)
        interval:     [[LDBInterval alloc] initWithUncheckedStart:start end:end]
        reversed:     self.isReversed
        noncaching:   self.isNoncaching
        checksummed:  self.isChecksummed];
}

- (NSData *)dataForKey:(NSData *)key
{
    namespace ldb = leveldb_objc;
    if (!key) {
        return nil;
    }
    
    std::string value;
    auto db = self.private_db.private_database;
    auto status = db->Get(self.private_readOptions,
                          ldb::to_Slice(ldb::concat(self.prefix, key)),
                          &value);
    if (status.ok()) {
        return [NSData dataWithBytes:value.data() length:value.size()];
    } else {
        return nil;
    }
}

- (NSData *)objectForKeyedSubscript:(NSData *)key
{
    return [self dataForKey:key];
}

- (NSData *)floorKey:(NSData *)key
{
    LDBSnapshot *reversed = (self.isReversed) ? self : self.reversed;
    auto afterKey = key.ldb_lexicographicalFirstChild;
    auto throughKey = [LDBInterval intervalWithStart:[NSData data] end:afterKey];
    return [[reversed clampToInterval:throughKey] enumerator].key ?: self.start;
}

- (NSData *)ceilKey:(NSData *)key
{
    LDBSnapshot *straight = (self.isReversed) ? self.reversed : self;
    auto fromKey = [LDBInterval intervalWithStart:key end:nil];
    return [[straight clampToInterval:fromKey] enumerator].key ?: self.end;
}

- (void)enumerate:(void (^)(NSData *key, NSData *data, BOOL *stop))block
{
    auto enumerator = [self enumerator];
    BOOL stop = NO;
    while (!stop && enumerator.isValid) {
        block(enumerator.key, enumerator.value, &stop);
        [enumerator step];
    }
}

- (LDBEnumerator *)enumerator
{
    return [[LDBEnumerator alloc] initWithSnapshot:self];
}

@end

@implementation LDBSnapshot (Private)

- (leveldb::Snapshot const *)private_snapshot
{
    return _impl->snapshot;
}

- (LDBDatabase *)private_db
{
    return _impl->database;
}

- (leveldb::ReadOptions)private_readOptions
{
    auto options = leveldb::ReadOptions{};
    options.snapshot         = self.private_snapshot;
    options.verify_checksums = self.isChecksummed;
    options.fill_cache       = !self.isNoncaching;
    return options;
}

@end
