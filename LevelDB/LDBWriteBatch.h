//
//  LDBWriteBatch.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LevelDB/LDBCompatibility.h>

#pragma clang assume_nonnull begin

@interface LDBWriteBatch : NSObject

- (__nullable NSData *)objectForKeyedSubscript:(NSData *)key;
- (void)setObject:(__nullable NSData *)data forKeyedSubscript:(NSData *)key;
- (void)setData:(__nullable NSData *)data forKey:(NSData *)key;
- (void)removeDataForKey:(NSData *)key;

- (void)enumerate:(LDB_NOESCAPE void (^)(NSData *key, __nullable NSData *data))block;

@end

#pragma clang assume_nonnull end
