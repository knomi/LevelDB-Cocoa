//
//  LDBSnapshot.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LevelDB/LDBCompatibility.h>

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
@property (nonatomic, readonly) NSData * __nullable startKey;
@property (nonatomic, readonly) NSData * __nullable endKey;
@property (nonatomic, readonly) BOOL isNoncaching;
@property (nonatomic, readonly) BOOL isChecksummed;
@property (nonatomic, readonly) BOOL isReversed;

- (LDBSnapshot *)clampStart:(__nullable NSData *)startKey end:(__nullable NSData *)endKey;
- (LDBSnapshot *)clampToInterval:(LDBInterval *)interval;
- (LDBSnapshot *)after:(NSData *)exclusiveStartKey;
- (LDBSnapshot *)prefix:(NSData *)keyPrefix;

- (__nullable NSData *)dataForKey:(NSData *)key;
- (__nullable NSData *)objectForKeyedSubscript:(NSData *)key;

- (void)enumerate:(LDB_NOESCAPE void (^)(NSData *key, NSData *data, BOOL *stop))block;

- (LDBEnumerator *)enumerator;

@end

#pragma clang assume_nonnull end
