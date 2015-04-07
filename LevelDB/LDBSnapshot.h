//
//  LDBSnapshot.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LevelDB/LDBCompatibility.h>

#pragma clang assume_nonnull begin

@class LDBDatabase;
@class LDBEnumerator;
@class LDBInterval;

@interface LDBSnapshot : NSObject

- (instancetype)init __attribute__((unavailable("init not available")));
- (instancetype)initWithDatabase:(LDBDatabase *)database;

@property (nonatomic, readonly) LDBSnapshot *noncaching;
@property (nonatomic, readonly) LDBSnapshot *checksummed;
@property (nonatomic, readonly) LDBSnapshot *reversed;
@property (nonatomic, readonly) NSData * prefix;
@property (nonatomic, readonly) LDBInterval * interval;
@property (nonatomic, readonly) NSData * __nullable start;
@property (nonatomic, readonly) NSData * __nullable end;
@property (nonatomic, readonly) BOOL isNoncaching;
@property (nonatomic, readonly) BOOL isChecksummed;
@property (nonatomic, readonly) BOOL isReversed;
@property (nonatomic, readonly) BOOL isClamped;

/// Create a clamped snapshot with `self.interval` clamped by the interval from
/// `start` to `end`, `nil` comparing greater than any other value.
///
/// The resulting snapshot contains the key-value pairs of `self` which have a
/// key greater than or equal to `start` and less than `end`, as compared by
/// `+[NSData ldb_compareLeft:right:]`.
///
/// Remark: Unlike in the C++ API of LevelDB, `[snap clampStart:nil end:nil]`
/// always returns an empty snapshot at "infinity". To "ignore" the `start`
/// parameter, pass `[NSData data]` instead.
- (LDBSnapshot *)clampStart:(NSData * __nullable)start end:(NSData * __nullable)end;

/// Create a clamped snapshot with `self.interval` clamped by `interval` as
/// `[interval clamp:self.interval]`.
///
/// Remark: The returned snapshot always has its `start` and `end` within
/// `self.start ... self.end`.
- (LDBSnapshot *)clampToInterval:(LDBInterval *)interval;

/// Create a clamped snapshot clamped after `exclusiveStart`.
///
/// Remark: This method is convenience for:
///
/// ```objc
/// [snapshot clampStart:exclusiveStart.ldb_lexicographicFirstChild end:nil];
/// ```
- (LDBSnapshot *)after:(NSData *)exclusiveStart;

/// Construct a prefixed snapshot from `self`.
///
/// The resulting snapshot is strictly within the bounds of `self` but with keys
/// that omit the given `prefix` (itself suffixed to `self.prefix`). If `self`
/// is clamped, then `prefix` is first removed from `self.interval`, and the
/// resulting interval is then reapplied to the result.
///
/// Example. Given the snapshot (prefix, interval) on the left, we get:
/// - ("foo", "bar" ..< "baz") prefixed with "ba" returns ("fooba", "r" ..< "z")
/// - ("foo", "bar" ..< "baz") prefixed with "bb" returns ("foobb", ""  ..< nil)
/// - ("foo", "BAR" ..< "BOZ") prefixed with "BA" returns ("fooBA", "R" ..< nil)
/// - ("foo", "BAR" ..< "BOZ") prefixed with "BO" returns ("fooBO", ""  ..< "Z")
- (LDBSnapshot *)prefixed:(NSData *)prefix;

/// Get the value at the given `key` if it exists, otherwise `nil`.
- (NSData * __nullable)dataForKey:(NSData *)key;

/// Get the value at the given `key` if it exists, otherwise `nil`.
- (NSData * __nullable)objectForKeyedSubscript:(NSData *)key;

/// Find the greatest key less than or equal to `key`, or return `self.start` if
/// none.
- (NSData * __nullable)floorKey:(NSData * __nullable)key;

/// Find the least key greater than or equal to `key`, or return `self.end` if
/// none.
- (NSData * __nullable)ceilKey:(NSData * __nullable)key;

/// Iterate in order the key-value pairs within the bounds of the snapshot.
/// To break out of the iteration early, set `*stop = YES` in the `block`.
- (void)enumerate:(LDB_NOESCAPE void (^)(NSData *key, NSData *data, BOOL *stop))block;

/// Create the `NSEnumerator`-style enumerator over the ordered key-value pairs
/// of the snapshot.
///
/// The enumerator yields key-value pairs as `NSArray`s of two `NSData` objects,
/// but the `enumerator.key` and `enumerator.value` properties can also be used.
- (LDBEnumerator *)enumerator;

@end

#pragma clang assume_nonnull end
