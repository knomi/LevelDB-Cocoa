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

- (NSData * __nullable)objectForKeyedSubscript:(NSData *)key;
- (void)setObject:(NSData * __nullable)data forKeyedSubscript:(NSData *)key;
- (void)setData:(NSData * __nullable)data forKey:(NSData *)key;
- (void)removeDataForKey:(NSData *)key;

- (void)enumerate:(LDB_NOESCAPE void (^)(NSData *key, NSData * __nullable data))block;

@end

#pragma clang assume_nonnull end
