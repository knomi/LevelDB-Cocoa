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

+ (instancetype)intervalWithStart:(__nullable NSData *)start end:(__nullable NSData *)end;

/// The interval from the empty byte sequence `[NSData data]` to `nil`.
+ (instancetype)everything;

- (instancetype)initWithStart:(__nullable NSData *)start end:(__nullable NSData *)end;

@property (nonatomic, readonly, copy) NSData * __nullable start;
@property (nonatomic, readonly, copy) NSData * __nullable end;

@end

#pragma clang assume_nonnull end
