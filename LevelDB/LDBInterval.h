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

/// Create the half-open interval from `start` (inclusive) to `end`
/// (non-inclusive). A `start` or `end` of `nil` indicates the infinite byte
/// sequence of `0xff`, comparing greater than any non-`nil` argumnent value.
///
/// If `[NSData ldb_compareLeft:start right:end] > 0`, returns the empty
/// interval `[LDBInterval nothing]`.
+ (instancetype)intervalWithStart:(NSData * __nullable)start end:(NSData * __nullable)end;

/// The interval from the empty byte sequence `[NSData data]` to `nil`.
+ (instancetype)everything;

/// The empty interval from the `nil` to `nil`.
+ (instancetype)nothing;

/// Bypasses the checks made by `+[LDBInterval intervalWithStart:end:]`.
- (instancetype)initWithUncheckedStart:(NSData * __nullable)start end:(NSData * __nullable)end;

/// The inclusive start position of the interval.
///
/// This value always compares less than or equal to `self.end` in
/// `+[NSData ldb_compareLeft:right:]`. The value of `nil` indicates an infinite
/// byte sequence of `0xff`, and is only possible when `self.end` is also `nil`.
@property (nonatomic, readonly, copy) NSData * __nullable start;

/// The exclusive end position of the interval.
///
/// This value always compares greater than or equal to `self.start` in
/// `+[NSData ldb_compareLeft:right:]`. The value of `nil` indicates an infinite
/// byte sequence of `0xff`.
@property (nonatomic, readonly, copy) NSData * __nullable end;

/// Test whether `self.start` is equal to `self.end`, making an empty interval.
@property (nonatomic, readonly) BOOL isEmpty;

@property (readonly) NSUInteger hash;

- (BOOL)isEqual:(id)object;

/// Test whether `self` contains `key`, i.e. `self.start` ≤ `key` and `key` <
/// `self.end`.
- (BOOL)contains:(NSData * __nullable)key;

/// Test whether `self` contains the (possibly infinite byte sequence) position
/// just before `key`, i.e. `self.start` < `key` and `key` ≤ `self.end`.
- (BOOL)containsBefore:(NSData * __nullable)key;

/// Returns `NSOrderedSame` if `[self contains:key]`, otherwise
/// `NSOrderedAscending` if `self.end` is less than or equal to `key`, else
/// `NSOrderedDescending`.
- (NSComparisonResult)compareToKey:(NSData * __nullable)key;

/// Trim `intervalToClamp` such that if `self` and `intervalToClamp` intersect,
/// the result is the intersection of the intervals, and if not, return the
/// empty interval at `intervalToClamp.start` or `intervalToClamp.end`
/// depending whether `intervalToClamp` is after or before `self`, respectively.
- (LDBInterval *)clamp:(LDBInterval *)intervalToClamp;

- (NSString *)description;

@end

#pragma clang assume_nonnull end
