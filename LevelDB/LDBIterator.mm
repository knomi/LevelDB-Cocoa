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

- (instancetype)initWithSnapshot:(LDBSnapshot *)snapshot
{
    if (!(self = [super init]) || !snapshot) {
        return nil;
    }
    
    _snapshot = snapshot;
    _impl = std::unique_ptr<leveldb::Iterator>(snapshot.private_db.private_database->NewIterator(snapshot.private_readOptions));
    
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

- (void)seekToFirst
{
    NSData *startKey = self.snapshot.startKey;
    if (startKey.length) {
        _impl->Seek(leveldb_objc::to_Slice(startKey));
    } else if (startKey) {
        _impl->SeekToFirst();
    }
    [self update];
}

- (void)seekToLast
{
    NSData *endKey = self.snapshot.endKey;
    if (!endKey) {
        _impl->SeekToLast();
    } else if (endKey.length) {
        _impl->Seek(leveldb_objc::to_Slice(endKey));
        _impl->Prev();
    }
    [self update];
}

- (void)seek:(NSData *)key
{
    _impl->Seek(leveldb_objc::to_Slice(key));
    [self update];
}

- (void)next
{
    if (!_impl->Valid()) return;
    _impl->Next();
    [self update];
}

- (void)prev
{
    if (!_impl->Valid()) return;
    _impl->Prev();
    [self update];
}

- (void)update
{
    _key = nil;
    _value = nil;
    if (!_impl->Valid()) return;
    
    NSData *key = leveldb_objc::to_NSData(_impl->key());
    if (leveldb_objc::compare(self.snapshot.startKey, key) <= 0 &&
        leveldb_objc::compare(key, self.snapshot.endKey) < 0)
    {
        _key = key;
        return;
    }
}

@end
