//
//  LDBWriteBatch.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma clang assume_nonnull begin

@interface LDBWriteBatch : NSObject

- (nullable NSData *)objectForKeyedSubscript:(NSData *)key;
- (void)setObject:(nullable NSData *)data forKeyedSubscript:(NSData *)key;
- (void)setData:(nullable NSData *)data forKey:(NSData *)key;
- (void)removeDataForKey:(NSData *)key;

- (void)enumerate:(__attribute__((noescape)) void (^)(NSData *key, __nullable NSData *data))block;

@end

#pragma clang assume_nonnull end
