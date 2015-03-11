//
//  LDBInterval.h
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface LDBInterval : NSObject

+ (instancetype)intervalWithStart:(NSData *)start end:(NSData *)end;

/// The interval from the empty byte sequence `[NSData data]` to `nil`.
+ (instancetype)everything;

- (instancetype)initWithStart:(NSData *)start end:(NSData *)end;

@property (nonatomic, readonly, copy) NSData *start;
@property (nonatomic, readonly, copy) NSData *end;

@end
