//
//  LDBInterval.h
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LevelDB/LDBCompatibility.h>

#pragma clang assume_nonnull begin

@interface LDBInterval : NSObject

+ (instancetype)intervalWithStart:(NSData * __nullable)start end:(NSData * __nullable)end;

/// The interval from the empty byte sequence `[NSData data]` to `nil`.
+ (instancetype)everything;

- (instancetype)initWithStart:(NSData * __nullable)start end:(NSData * __nullable)end;

@property (nonatomic, readonly, copy) NSData * __nullable start;
@property (nonatomic, readonly, copy) NSData * __nullable end;

@end

#pragma clang assume_nonnull end
