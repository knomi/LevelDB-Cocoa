//
//  LDBSnapshot.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma clang assume_nonnull begin

@class LDBDatabase;
@class LDBEnumerator;
@class LDBInterval;

@interface LDBSnapshot : NSObject

- (instancetype)init __attribute__((unavailable("init not available")));
- (instancetype)initWithDatabase:(LDBDatabase *)database;

@property (nonatomic, readonly) LDBSnapshot *noncaching;
@property (nonatomic, readonly) LDBSnapshot *checksummed;
@property (nonatomic, readonly) LDBSnapshot *reversed;
@property (nonatomic, readonly, nullable) NSData *startKey;
@property (nonatomic, readonly, nullable) NSData *endKey;
@property (nonatomic, readonly) BOOL isNoncaching;
@property (nonatomic, readonly) BOOL isChecksummed;
@property (nonatomic, readonly) BOOL isReversed;

- (LDBSnapshot *)clampStart:(nullable NSData *)startKey end:(nullable NSData *)endKey;
- (LDBSnapshot *)clampToInterval:(LDBInterval *)interval;
- (LDBSnapshot *)after:(NSData *)exclusiveStartKey;
- (LDBSnapshot *)prefix:(NSData *)keyPrefix;

- (nullable NSData *)dataForKey:(NSData *)key;
- (nullable NSData *)objectForKeyedSubscript:(NSData *)key;

- (void)enumerate:(__attribute__((noescape)) void (^)(NSData *key, NSData *data, BOOL *stop))block;

- (LDBEnumerator *)enumerator;

@end

#pragma clang assume_nonnull end
