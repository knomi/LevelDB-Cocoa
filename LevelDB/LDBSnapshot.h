//
//  LDBSnapshot.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LDBDatabase;

@interface LDBSnapshot : NSObject

- (instancetype)initWithDatabase:(LDBDatabase *)database;

@property (nonatomic, readonly) LDBSnapshot *noncaching;
@property (nonatomic, readonly) LDBSnapshot *checksummed;
@property (nonatomic, readonly) LDBSnapshot *reversed;
@property (nonatomic, readonly) NSData *startKey;
@property (nonatomic, readonly) NSData *endKey;
@property (nonatomic, readonly) BOOL isNoncaching;
@property (nonatomic, readonly) BOOL isChecksummed;
@property (nonatomic, readonly) BOOL isReversed;

- (LDBSnapshot *)clampStart:(NSData *)startKey end:(NSData *)endKey;
- (LDBSnapshot *)after:(NSData *)exclusiveStartKey;
- (LDBSnapshot *)prefix:(NSData *)keyPrefix;

- (NSData *)dataForKey:(NSData *)key;
- (NSData *)objectForKeyedSubscript:(NSData *)key;

- (void)enumerate:(void (^)(NSData *key, NSData *data, BOOL *stop))block;

@end
