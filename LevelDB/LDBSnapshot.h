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
@property (nonatomic, readonly) NSData * prefix;
@property (nonatomic, readonly) LDBInterval * interval;
@property (nonatomic, readonly) NSData * __nullable start;
@property (nonatomic, readonly) NSData * __nullable end;
@property (nonatomic, readonly) BOOL isNoncaching;
@property (nonatomic, readonly) BOOL isChecksummed;
@property (nonatomic, readonly) BOOL isReversed;
@property (nonatomic, readonly) BOOL isClamped;

- (LDBSnapshot *)clampStart:(NSData * __nullable)start end:(NSData * __nullable)end;
- (LDBSnapshot *)clampToInterval:(LDBInterval *)interval;
- (LDBSnapshot *)after:(NSData *)exclusiveStart;
- (LDBSnapshot *)prefixed:(NSData *)prefix;

- (NSData * __nullable)dataForKey:(NSData *)key;
- (NSData * __nullable)objectForKeyedSubscript:(NSData *)key;

- (void)enumerate:(LDB_NOESCAPE void (^)(NSData *key, NSData *data, BOOL *stop))block;

- (LDBEnumerator *)enumerator;

@end

#pragma clang assume_nonnull end
