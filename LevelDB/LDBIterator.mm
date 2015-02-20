//
//  LDBIterator.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBIterator.h"

#import "LDBDatabase.h"
#import "LDBSnapshot.h"
#import "LDBPrivate.hpp"

#include "leveldb/db.h"
#include <memory>

@interface LDBIterator () {
    std::unique_ptr<leveldb::Iterator> _impl;
    NSData *_value;
}
@end

@implementation LDBIterator

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class LDBIterator"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initWithSnapshot:(LDBSnapshot *)snapshot
{
    if (!(self = [super init]) || !snapshot) {
        return nil;
    }
    
    _snapshot = snapshot;
    _impl = std::unique_ptr<leveldb::Iterator>(snapshot.private_db.private_database->NewIterator(snapshot.private_readOptions));

    if (!snapshot.isReversed) {
        NSData *startKey = self.snapshot.startKey;
        if (startKey.length) {
            _impl->Seek(leveldb_objc::to_Slice(startKey));
        } else if (startKey) {
            _impl->SeekToFirst();
        }
    } else {
        NSData *endKey = self.snapshot.endKey;
        if (!endKey) {
            _impl->SeekToLast();
        } else if (endKey.length) {
            _impl->Seek(leveldb_objc::to_Slice(endKey));
            if (_impl->Valid()) {
                _impl->Prev();
            } else {
                _impl->SeekToLast();
            }
        }
    }
    [self private_update];
    
    return self;
}

- (BOOL)isValid
{
    return self.key != nil;
}

- (NSData *)value
{
    if (!_value && self.key) {
        _value = leveldb_objc::to_NSData(_impl->value());
    }
    return _value;
}

- (void)step
{
    if (!self.snapshot.isReversed) {
        [self private_stepForward];
    } else {
        [self private_stepBackward];
    }
}

- (void)private_stepForward
{
    if (!self.isValid) return;
    _impl->Next();
    _key = nil;
    _value = nil;
    if (!_impl->Valid()) return;
    NSData *key = leveldb_objc::to_NSData(_impl->key());
    if (leveldb_objc::compare(key, self.snapshot.endKey) < 0) {
        _key = key;
    }
}

- (void)private_stepBackward
{
    if (!self.isValid) return;
    _impl->Prev();
    _key = nil;
    _value = nil;
    if (!_impl->Valid()) return;
    NSData *key = leveldb_objc::to_NSData(_impl->key());
    if (leveldb_objc::compare(self.snapshot.startKey, key) <= 0) {
        _key = key;
    }
}

- (void)private_update
{
    _key = nil;
    _value = nil;
    if (!_impl->Valid()) return;
    
    NSData *key = leveldb_objc::to_NSData(_impl->key());
    if (leveldb_objc::compare(self.snapshot.startKey, key) <= 0 &&
        leveldb_objc::compare(key, self.snapshot.endKey) < 0)
    {
        _key = key;
    }
}

@end
