//
//  LDBSnapshot.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBSnapshot.h"

#import "LDBDatabase.h"
#import "LDBPrivate.hpp"

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

- (instancetype)initWithDatabase:(LDBDatabase *)database
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _impl = std::make_shared<leveldb_objc::snapshot_t const>(database);
    
    
    return self;
}

- (instancetype)
    initWithImpl:(std::shared_ptr<leveldb_objc::snapshot_t const>)impl
    startKey:(NSData *)startKey
    endKey:(NSData *)endKey
    reversed:(BOOL)isReversed
    noncaching:(BOOL)isNoncaching
    checksummed:(BOOL)isChecksummed
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _impl          = impl;
    _startKey      = [startKey copy];
    _endKey        = [endKey copy];
    _isReversed    = isReversed;
    _isNoncaching  = isNoncaching;
    _isChecksummed = isChecksummed;
    
    return self;
}

- (LDBSnapshot *)noncaching
{
    return [[LDBSnapshot alloc]
        initWithImpl: _impl
        startKey:     self.startKey
        endKey:       self.endKey
        reversed:     self.isReversed
        noncaching:   YES
        checksummed:  self.isChecksummed];
}

- (LDBSnapshot *)checksummed
{
    return [[LDBSnapshot alloc]
        initWithImpl: _impl
        startKey:     self.startKey
        endKey:       self.endKey
        reversed:     self.isReversed
        noncaching:   self.isNoncaching
        checksummed:  YES];
}

- (LDBSnapshot *)reversed
{
    return [[LDBSnapshot alloc]
        initWithImpl: _impl
        startKey:     self.startKey
        endKey:       self.endKey
        reversed:     !self.isReversed
        noncaching:   self.isNoncaching
        checksummed:  self.isChecksummed];
}

- (LDBSnapshot *)clampStart:(NSData *)startKey end:(NSData *)endKey
{
    if (!startKey || leveldb_objc::compare(startKey, endKey) > 0) {
        return [[LDBSnapshot alloc]
            initWithImpl: _impl
            startKey:     nil
            endKey:       nil
            reversed:     self.isReversed
            noncaching:   self.isNoncaching
            checksummed:  self.isChecksummed];
    }
    
    BOOL clampsStart = leveldb_objc::compare(self.startKey, startKey) < 0;
    BOOL clampsEnd   = leveldb_objc::compare(endKey, self.endKey) < 0;
    
    if (!clampsStart && !clampsEnd) {
        return self;
    }
    
    return [[LDBSnapshot alloc]
        initWithImpl: _impl
        startKey:     clampsStart ? startKey : self.startKey
        endKey:       clampsEnd ? endKey : self.endKey
        reversed:     self.isReversed
        noncaching:   self.isNoncaching
        checksummed:  self.isChecksummed];
}

- (LDBSnapshot *)after:(NSData *)exclusiveStartKey
{
    auto startKey = leveldb_objc::lexicographicalChild(exclusiveStartKey);
    return [self clampStart:startKey end:self.endKey];
}

- (LDBSnapshot *)prefix:(NSData *)keyPrefix
{
    auto startKey = keyPrefix;
    NSData *endKey = leveldb_objc::lexicographicalSuccessor(keyPrefix);
    return [self clampStart:startKey end:endKey];
}

- (NSData *)dataForKey:(NSData *)key
{
    if (!key) {
        return nil;
    }
    
    std::string value;
    auto db = self.private_db.private_database;
    auto status = db->Get(self.private_readOptions,
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
    return [self dataForKey:key];
}

- (void)enumerate:(void (^)(NSData *key, NSData *data, BOOL *stop))block
{
    LDB_UNIMPLEMENTED();
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
