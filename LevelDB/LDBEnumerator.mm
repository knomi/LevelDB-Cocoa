//
//  LDBEnumerator.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBEnumerator.h"

#import "LDBDatabase.h"
#import "LDBSnapshot.h"
#import "LDBPrivate.hpp"

#include "leveldb/db.h"
#include <memory>

@interface LDBEnumerator () {
    std::unique_ptr<leveldb::Iterator> _impl;
    NSUInteger _prefixLength;
    NSData *_start;
    NSData *_end;
    NSData *_value;
}
@end

@implementation LDBEnumerator

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class LDBEnumerator"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initWithSnapshot:(LDBSnapshot *)snapshot
{
    namespace ldb = leveldb_objc;
    if (!(self = [super init]) || !snapshot) {
        return nil;
    }
    
    _snapshot = snapshot;
    _impl = std::unique_ptr<leveldb::Iterator>(snapshot.private_db.private_database->NewIterator(snapshot.private_readOptions));
    _prefixLength = snapshot.prefix.length;
    _start = ldb::concat(snapshot.prefix, snapshot.start);
    _end   = snapshot.end ? ldb::concat(snapshot.prefix, snapshot.end)
                          : ldb::lexicographicalNextSibling(snapshot.prefix);

    if (!snapshot.isReversed) {
        if (_start.length) {
            _impl->Seek(ldb::to_Slice(_start));
        } else if (_start) {
            _impl->SeekToFirst();
        }
    } else {
        if (!_end) {
            _impl->SeekToLast();
        } else if (_end.length) {
            _impl->Seek(ldb::to_Slice(_end));
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

- (NSArray *)nextObject
{
    if (!self.isValid) {
        return nil;
    } else {
        NSArray *pair = @[self.key, self.value];
        [self step];
        return pair;
    }
}

- (void)private_stepForward
{
    namespace ldb = leveldb_objc;
    if (!self.isValid) return;
    _impl->Next();
    _key = nil;
    _value = nil;
    if (!_impl->Valid()) return;
    NSData *key = ldb::to_NSData(_impl->key());
    if (ldb::compare(key, _end) < 0) {
        _key = ldb::dropLength(_prefixLength, key);
    }
}

- (void)private_stepBackward
{
    namespace ldb = leveldb_objc;
    if (!self.isValid) return;
    _impl->Prev();
    _key = nil;
    _value = nil;
    if (!_impl->Valid()) return;
    NSData *key = ldb::to_NSData(_impl->key());
    if (ldb::compare(_start, key) <= 0) {
        _key = ldb::dropLength(_prefixLength, key);
    }
}

- (void)private_update
{
    namespace ldb = leveldb_objc;
    _key = nil;
    _value = nil;
    if (!_impl->Valid()) return;
    
    NSData *key = ldb::to_NSData(_impl->key());
    if (ldb::compare(_start, key) <= 0 && ldb::compare(key, _end) < 0) {
        _key = ldb::dropLength(_prefixLength, key);
    }
}

@end
