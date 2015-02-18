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
        , snapshot(database.impl->GetSnapshot())
    {}
    
    ~snapshot_t() {
        database.impl->ReleaseSnapshot(snapshot);
    }
private:
    snapshot_t(snapshot_t &) = delete;
    void operator=(snapshot_t &) = delete;
};

} // namespace leveldb_objc

@implementation LDBSnapshot {
    std::shared_ptr<leveldb_objc::snapshot_t const> _impl;
    BOOL _noncaching;
    BOOL _checking;
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
    noncaching:(BOOL)noncaching
    checking:(BOOL)checking
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _impl       = impl;
    _startKey   = [startKey copy];
    _endKey     = [endKey copy];
    _isReversed = isReversed;
    _noncaching = noncaching;
    _checking   = checking;
    
    return self;
}

- (leveldb::ReadOptions)options
{
    auto options = leveldb::ReadOptions{};
    options.snapshot         = self->_impl->snapshot;
    options.verify_checksums = self.checking;
    options.fill_cache       = !self.noncaching;
    return options;
}

- (LDBSnapshot *)noncaching
{
    return [[LDBSnapshot alloc]
        initWithImpl: self->_impl
        startKey:     self.startKey
        endKey:       self.endKey
        reversed:     self.isReversed
        noncaching:   YES
        checking:     self->_checking];
}

- (LDBSnapshot *)checking
{
    return [[LDBSnapshot alloc]
        initWithImpl: self->_impl
        startKey:     self.startKey
        endKey:       self.endKey
        reversed:     self.isReversed
        noncaching:   self->_noncaching
        checking:     YES];
}

- (LDBSnapshot *)reversed
{
    return [[LDBSnapshot alloc]
        initWithImpl: self->_impl
        startKey:     self.startKey
        endKey:       self.endKey
        reversed:     !self.isReversed
        noncaching:   self->_noncaching
        checking:     self->_checking];
}

- (LDBSnapshot *)clampStart:(NSData *)startKey end:(NSData *)endKey
{
    if (!startKey || leveldb_objc::compare(startKey, endKey) > 0) {
        return [[LDBSnapshot alloc]
            initWithImpl: self->_impl
            startKey:     nil
            endKey:       nil
            reversed:     self.isReversed
            noncaching:   self->_noncaching
            checking:     self->_checking];
    }
    
    BOOL clampsStart = leveldb_objc::compare(self.startKey, startKey) < 0;
    BOOL clampsEnd   = leveldb_objc::compare(endKey, self.endKey) < 0;
    
    if (!clampsStart && !clampsEnd) {
        return self;
    }
    
    return [[LDBSnapshot alloc]
        initWithImpl: self->_impl
        startKey:     clampsStart ? startKey : self.startKey
        endKey:       clampsEnd ? endKey : self.endKey
        reversed:     self.isReversed
        noncaching:   self->_noncaching
        checking:     self->_checking];
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
    LDB_UNIMPLEMENTED();
}

- (NSData *)objectForKeyedSubscript:(NSData *)key
{
    LDB_UNIMPLEMENTED();
}

- (void)enumerate:(void (^)(NSData *key, NSData *data, BOOL *stop))block
{
    LDB_UNIMPLEMENTED();
}

- (NSUInteger)
    countByEnumeratingWithState:(NSFastEnumerationState *)state
    objects:(id __unsafe_unretained [])buffer
    count:(NSUInteger)len
{
    LDB_UNIMPLEMENTED();
}

@end

@implementation LDBSnapshot (Private)

- (leveldb::Snapshot const *)impl
{
    return _impl->snapshot;
}

@end
