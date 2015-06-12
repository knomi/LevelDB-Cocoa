//
//  LDBSnapshot.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma clang assume_nonnull begin

@class LDBDatabase;
@class LDBEnumerator;
@class LDBInterval;

/// @brief Immutable snapshot of @c LDBDatabase, optionally @em prefixed or
/// @em clamped to a subinterval of keys.
///
/// @b Create a snapshot by calling @code
/// LDBDatabase *database;
/// LDBSnapshot *snapshot = [database snapshot];
/// @endcode The created @c snapshot won't change even if more data is written
/// to the @c database.
///
/// @b Enumerate over the keys and values of a snapshot by using @code
/// [snapshot enumerate:^(NSData *key, NSData *value, BOOL *stop) {
///     NSLog(@"%@: %@", key, value);
/// }];
/// @endcode Enumerate @b backwards by using @c snapshot.reversed instead.
///
/// Use the keyed @b subscript, @code
/// NSData *value = snapshot[key];
/// @endcode to check the value of a specific @c key.
///
/// @remarks As indexed access would be @em O(N) in complexity, there is no
/// direct accessor to the @em nth key or to the count of keys present in a
/// snapshot.
@interface LDBSnapshot : NSObject

- (instancetype)init __attribute__((unavailable("init not available")));
- (instancetype)initWithDatabase:(LDBDatabase *)database;

// MARK: Properties

/// @brief Don't alter the LevelDB cache when the returned snapshot is read.
@property (nonatomic, readonly) LDBSnapshot *noncaching;

/// @brief Verify database checksums when the returned snapshot is read.
@property (nonatomic, readonly) LDBSnapshot *checksummed;

/// @brief Reverse the order of keys when the returned snapshot is enumerated.
@property (nonatomic, readonly) LDBSnapshot *reversed;

/// @brief Key prefix of a @em prefixed snapshot.
///
/// If the @c snapshot has been prefixed its keys are actually stored with
/// @c snapshot.prefix prepended to them, yet when enumerated or subscripted,
/// it behaves as if the prefix did not exist.
///
/// @note Defaults to the empty @c NSData buffer
@property (nonatomic, readonly) NSData * prefix;

/// @brief Key interval of a @em clamped snapshot.
///
/// If the @c snapshot is clamped, its enumeration and subscripted read access
/// is limited to this half-open key interval.
///
/// If the @c snapshot is both clamped and @em prefixed, then the key prefix
/// applies to the bounds of @c snapshot.interval; to compute the absolute key
/// interval, prepend @c snapshot.prefix to the bounds.
///
/// @note Defaults to @c LDBInterval.everything
@property (nonatomic, readonly) LDBInterval * interval;

/// @brief Convenience for @c self.interval.start
@property (nonatomic, readonly) NSData * __nullable start;

/// @brief Convenience for @c self.interval.end
@property (nonatomic, readonly) NSData * __nullable end;

/// @returns whether reading this snapshot leaves the LevelDB cache untouched.
@property (nonatomic, readonly) BOOL isNoncaching;

/// @returns whether reading this snapshot verifies database checksums.
@property (nonatomic, readonly) BOOL isChecksummed;

/// @returns whether enumerating this snapshot starts from the last key backwards.
@property (nonatomic, readonly) BOOL isReversed;

/// @returns whether @c self.interval is not @c LDBInterval.everything.
@property (nonatomic, readonly) BOOL isClamped;

/// @returns whether this snapshot has a non-empty key prefix.
@property (nonatomic, readonly) BOOL isPrefixed;

// MARK: Methods

/// @brief Create a @em clamped snapshot with @c self.interval clamped by the
/// interval from @p start to @p end; @c nil comparing greater than any other
/// value.
///
/// The resulting snapshot contains those key-value pairs of @c self which have
/// a key greater than or equal to @p start and less than @p end, as compared by
/// @code +[NSData ldb_compareLeft:right:] @endcode
///
/// @remarks Unlike in the C++ API of LevelDB,
/// @code [snap clampStart:nil end:nil] @endcode
/// always returns an empty snapshot at "infinity". To ignore the @p start
/// parameter, pass the empty @c NSData instead:
/// @code LDBSnapshot *clamp = [snap clampStart:[NSData data] end:end]; @endcode
- (LDBSnapshot *)clampStart:(NSData * __nullable)start end:(NSData * __nullable)end;

/// @brief Create a @em clamped snapshot with @c self.interval clamped by @p
/// interval as @code [interval clamp:self.interval] @endcode
///
/// @remarks The returned snapshot always has its @c start and @c end within
/// @c self.start ... @c self.end.
- (LDBSnapshot *)clampToInterval:(LDBInterval *)interval;

/// @brief Create a @em clamped snapshot clamped after @p exclusiveStart.
///
/// @remarks This method is convenience for
/// @code
/// [self clampStart:exclusiveStart.ldb_lexicographicFirstChild end:nil];
/// @endcode
- (LDBSnapshot *)after:(NSData *)exclusiveStart;

/// @brief Construct a @em prefixed snapshot from @c self.
///
/// The resulting snapshot is strictly within the bounds of @c self but with its
/// keys omit the given @p prefix (itself suffixed to @c self.prefix). If @c
/// self is clamped, then @p prefix is first removed from @p self.interval, and
/// the resulting interval is then reapplied to the result.
///
/// @b Example: Given the snapshot @c (prefix, @c start, @c end) on the left, we get:
///
/// <li> @c ("foo", @c "bar", @c "baz") prefixed with @c "ba" → @c ("fooba", @c "r", @c "z")
///
/// <li> @c ("foo", @c "bar", @c "baz") prefixed with @c "bb" → @c ("foobb", @c "",  @c nil)
///
/// <li> @c ("foo", @c "BAR", @c "BOZ") prefixed with @c "BA" → @c ("fooBA", @c "R", @c nil)
///
/// <li> @c ("foo", @c "BAR", @c "BOZ") prefixed with @c "BO" → @c ("fooBO", @c "",  @c "Z")
- (LDBSnapshot *)prefixed:(NSData *)prefix;

/// @brief Get the value at the given @p key if it exists, otherwise @c nil.
///
/// @see The keyed subscript syntax syntax works equivalently and is shorter:
/// @code NSData *data = snapshot[key]; @endcode
- (NSData * __nullable)dataForKey:(NSData *)key;

/// @brief Get the value at the given @p key if it exists, otherwise @c nil.
- (NSData * __nullable)objectForKeyedSubscript:(NSData *)key;

/// @brief Find the greatest existing key less than or equal to @p key, or
/// return @c self.start if none.
- (NSData * __nullable)floorKey:(NSData * __nullable)key;

/// @brief Find the least existing key that is greater than or equal to @p key,
/// or return @c self.end if none.
- (NSData * __nullable)ceilKey:(NSData * __nullable)key;

/// @brief Enumerate in lexicographic key order the key-value pairs within the
/// bounds of the snapshot.
///
/// Respects the value of @c self.isReversed.
///
/// To break out of the iteration early, set
/// @code *stop = YES; @endcode
/// in the @p block.
- (void)enumerate:(__attribute__((noescape)) void (^)(NSData *key, NSData *data, BOOL *stop))block;

/// @brief Create the @c NSEnumerator style enumerator over the ordered
/// key-value pairs of the snapshot.
///
/// The enumerator yields every key-value pair as an @c NSArray of two @c NSData
/// objects, but the @c enumerator.key and @c enumerator.value properties can
/// also be used.
- (LDBEnumerator *)enumerator;

@end

#pragma clang assume_nonnull end
