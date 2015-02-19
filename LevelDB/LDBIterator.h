//
//  LDBIterator.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LDBDatabase;
@class LDBSnapshot;

@interface LDBIterator : NSObject

- (instancetype)initWithSnapshot:(LDBSnapshot *)snapshot;

@property (nonatomic, readonly) LDBSnapshot *snapshot;
@property (nonatomic, readonly) BOOL isValid;
@property (nonatomic, readonly, copy) NSData *key;
@property (nonatomic, readonly, copy) NSData *value;

@property (nonatomic, readonly) NSData *unsafeKey;
@property (nonatomic, readonly) NSData *unsafeValue;

- (void)seekToFirst;
- (void)seekToLast;
- (void)seek:(NSData *)key;

- (void)next;
- (void)prev;

@end
