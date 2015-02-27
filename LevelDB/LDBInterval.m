//
//  LDBInterval.m
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBInterval.h"
#import "NSData+LDB.h"

@implementation LDBInterval

+ (instancetype)intervalWithStart:(NSData *)start end:(NSData *)end
{
    return [[self alloc] initWithStart:start end: end];
}

+ (instancetype)everything
{
    return [[self alloc] initWithStart:[NSData data] end:nil];
}

- (instancetype)initWithStart:(NSData *)start end:(NSData *)end
{
    if (!(self = [super init])) return nil;
    if ([NSData ldb_compareLeft:start right:end] <= 0) {
        _start = [start copy];
        _end   = [end copy];
    } else {
        NSAssert(NO, @"LDBInterval: `start` must not compare greater than `end`");
    }
    return self;
}

@end
