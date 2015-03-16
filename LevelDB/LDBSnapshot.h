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

- (LDBSnapshot *)clampStart:(NSData * __nullable)startKey end:(NSData * __nullable)endKey;
- (LDBSnapshot *)clampToInterval:(LDBInterval *)interval;
- (LDBSnapshot *)after:(NSData *)exclusiveStartKey;
- (LDBSnapshot *)prefix:(NSData *)keyPrefix;

- (NSData * __nullable)dataForKey:(NSData *)key;
- (NSData * __nullable)objectForKeyedSubscript:(NSData *)key;

- (void)enumerate:(LDB_NOESCAPE void (^)(NSData *key, NSData *data, BOOL *stop))block;

- (LDBEnumerator *)enumerator;

@end

#pragma clang assume_nonnull end
