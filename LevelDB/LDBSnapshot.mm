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
    _start = [NSData data];
    
    return self;
}

- (instancetype)
    initWithImpl:(std::shared_ptr<leveldb_objc::snapshot_t const>)impl
    prefix:(NSData *)prefix
    start:(NSData *)start
    end:(NSData *)end
    reversed:(BOOL)isReversed
    noncaching:(BOOL)isNoncaching
    checksummed:(BOOL)isChecksummed
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _impl          = impl;
    _prefix        = [prefix copy];
    _start         = [start copy];
    _end           = [end copy];
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
        start:        self.start
        end:          self.end
        reversed:     self.isReversed
        noncaching:   YES
        checksummed:  self.isChecksummed];
}

- (LDBSnapshot *)checksummed
{
    return [[LDBSnapshot alloc]
        initWithImpl: _impl
        prefix:       self.prefix
        start:        self.start
        end:          self.end
        reversed:     self.isReversed
        noncaching:   self.isNoncaching
        checksummed:  YES];
}

- (LDBSnapshot *)reversed
{
    return [[LDBSnapshot alloc]
        initWithImpl: _impl
        prefix:       self.prefix
        start:        self.start
        end:          self.end
        reversed:     !self.isReversed
        noncaching:   self.isNoncaching
        checksummed:  self.isChecksummed];
}

- (LDBSnapshot *)clampStart:(NSData *)start end:(NSData *)end
{
    namespace ldb = leveldb_objc;
    if (start == nil) {
        start = [NSData data];
    }
    if (ldb::compare(start, end) > 0) {
        return [[LDBSnapshot alloc]
            initWithImpl: _impl
            prefix:       self.prefix
            start:        nil
            end:          nil
            reversed:     self.isReversed
            noncaching:   self.isNoncaching
            checksummed:  self.isChecksummed];
    }
    
    BOOL clampsStart = ldb::compare(self.start, start) < 0;
    BOOL clampsEnd   = ldb::compare(end, self.end) < 0;
    
    if (!clampsStart && !clampsEnd) {
        return self;
    }
    
    return [[LDBSnapshot alloc]
        initWithImpl: _impl
        prefix:       self.prefix
        start:        clampsStart ? start : self.start
        end:          clampsEnd ? end : self.end
        reversed:     self.isReversed
        noncaching:   self.isNoncaching
        checksummed:  self.isChecksummed];
}

- (LDBSnapshot *)clampToInterval:(LDBInterval *)interval
{
    if (interval.start == nil) {
        return [[LDBSnapshot alloc]
            initWithImpl: _impl
            prefix:       self.prefix
            start:        nil
            end:          nil
            reversed:     self.isReversed
            noncaching:   self.isNoncaching
            checksummed:  self.isChecksummed];
    } else {
        return [self clampStart:interval.start end:interval.end];
    }
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
        start:        start
        end:          end
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
