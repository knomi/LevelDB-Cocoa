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
    if ([NSData ldb_compareLeft:start right:end] <= 0) {
        return [[self alloc] initWithUncheckedStart:start end:end];
    } else {
        return [self nothing];
    }
}

+ (instancetype)everything
{
    static dispatch_once_t once;
    static LDBInterval *instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] initWithUncheckedStart:[NSData data] end:nil];
    });
    return instance;
}

+ (instancetype)nothing
{
    static dispatch_once_t once;
    static LDBInterval *instance;
    dispatch_once(&once, ^{
        instance = [[self alloc] initWithUncheckedStart:nil end: nil];
    });
    return instance;
}

- (instancetype)initWithUncheckedStart:(NSData *)start end:(NSData *)end
{
    if (!(self = [super init])) return nil;
    _start = [start copy];
    _end   = [end copy];
    return self;
}

- (BOOL)isEmpty
{
    return [NSData ldb_compareLeft:self.start right:self.end] >= 0;
}

- (NSUInteger)hash
{
    return self.start.hash ^ (self.end.hash + 1);
}

- (BOOL)isEqual:(id)object
{
    if (![object isKindOfClass:LDBInterval.class]) return NO;
    LDBInterval *other = object;
    return [NSData ldb_compareLeft:self.start right:other.start] == 0
        && [NSData ldb_compareLeft:self.end   right:other.end  ] == 0;
}

- (BOOL)contains:(NSData * __nullable)key
{
    return [NSData ldb_compareLeft:self.start right:key     ] <= 0
        && [NSData ldb_compareLeft:key        right:self.end] < 0;
}

- (BOOL)containsBefore:(NSData * __nullable)key
{
    return [NSData ldb_compareLeft:self.start right:key     ] < 0
        && [NSData ldb_compareLeft:key        right:self.end] <= 0;
}

- (NSComparisonResult)compareToKey:(NSData *)key
{
    NSComparisonResult startToKey = [NSData ldb_compareLeft:self.start right:key];
    if (startToKey > 0) return NSOrderedDescending;
    NSComparisonResult endToKey = [NSData ldb_compareLeft:self.end right:key];
    if (endToKey <= 0) return NSOrderedAscending;
    return NSOrderedSame;
}

- (LDBInterval *)clamp:(LDBInterval *)intervalToClamp
{
    LDBInterval *other = intervalToClamp;
    if ([NSData ldb_compareLeft:self.end right:other.start] <= 0) {
        return [LDBInterval intervalWithStart:other.start end:other.start];
    }
    if ([NSData ldb_compareLeft:other.end right:self.start] <= 0) {
        return [LDBInterval intervalWithStart:other.end end:other.end];
    }
    NSData *start = [NSData ldb_compareLeft:self.start right:other.start] >= 0 ? self.start : other.start;
    NSData *end   = [NSData ldb_compareLeft:self.end   right:other.end  ] <= 0 ? self.end   : other.end;
    return [LDBInterval intervalWithStart:start end:end];
}

- (NSString *)description
{
    return [NSString stringWithFormat:@"(%@ ..< %@)", self.start, self.end];
}

@end
