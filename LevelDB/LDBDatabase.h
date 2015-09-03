//
//  LDBDatabase.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma clang assume_nonnull begin

@class LDBInterval;
@class LDBSnapshot;
@class LDBWriteBatch;

// -----------------------------------------------------------------------------
#pragma mark - Constants

#ifdef __cplusplus
extern "C" {
#endif

typedef NS_ENUM(NSInteger, LDBCompression) {
    LDBCompressionNoCompression     = 0,
    LDBCompressionSnappyCompression = 1
};

extern NSString * const LDBOptionCreateIfMissing; // NSNumber with BOOL
extern NSString * const LDBOptionErrorIfExists;   // NSNumber with BOOL
extern NSString * const LDBOptionParanoidChecks;  // NSNumber with BOOL
// - no `env` option yet
extern NSString * const LDBOptionInfoLog;         // LDBLogger or nil
extern NSString * const LDBOptionWriteBufferSize; // NSNumber with size_t 64K…1G
extern NSString * const LDBOptionMaxOpenFiles;    // NSNumber with integer 74…50000
extern NSString * const LDBOptionCacheCapacity;   // NSNumber with integer
extern NSString * const LDBOptionBlockSize;       // NSNumber with size_t 1K…4M
extern NSString * const LDBOptionBlockRestartInterval; // NSNumber with int > 0
extern NSString * const LDBOptionCompression;     // NSNumber with LDBCompression
extern NSString * const LDBOptionBloomFilterBits; // NSNumber with integer 0…32

#ifdef __cplusplus
} // extern "C"
#endif

// -----------------------------------------------------------------------------
#pragma mark - LDBDatabase

@interface LDBDatabase : NSObject

/// @brief Destroy the contents of the database in the given @p path on disk. Be
/// very careful using this method.
///
/// Iff there is an error, returns @c NO and sets the @p error pointer with
/// @c LDBErrorMessageKey set to an @c NSString value in its @c userInfo.
+ (BOOL)
    destroyDatabaseAtPath:(NSString *)path
    error:(NSError * __autoreleasing *)error;


/// @brief Try to repair the database in the given @p path on disk.
///
/// If a DB cannot be opened, you may attempt to call this method to resurrect
/// as much of the contents of the database as possible. Some data may be lost,
/// so be careful when calling this function on a database that contains
/// important information.
///
/// Iff there is an error, returns @c NO and sets the @p error pointer with
/// @c LDBErrorMessageKey set to an @c NSString value in its @c userInfo.
+ (BOOL)
    repairDatabaseAtPath:(NSString *)path
    error:(NSError * __autoreleasing *)error;


/// @brief Create an in-memory database that is not persisted on disk.
- (instancetype)init;


/// @brief Open the database in the given @p path on disk. If the directory
/// doesn't exist a blank database is created.
///
/// Iff there is an error, returns @c nil and sets the @p error pointer with
/// @c LDBErrorMessageKey set to an @NSString value in its @c userInfo.
///
/// @note Also configures database to use the 10-bit Bloom filter.
///
/// @see -[LDBDatabase initWithPath:options:error:]
- (nullable instancetype)initWithPath:(NSString *)path;


/// Create or open the database with the given `options`. Iff there is an
/// error, returns `nil` and sets the `error` pointer with `LDBErrorMessageKey`
/// set in the `userInfo`.
///
/// **Options:**
///
/// - `LDBOptionCreateIfMissing`: `BOOL`-valued `NSNumber`, default `NO`
/// - `LDBOptionErrorIfExists`:   `BOOL`-valued `NSNumber`, default `NO`
/// - `LDBOptionParanoidChecks`:  `BOOL`-valued `NSNumber`, default `NO`
/// - `LDBOptionInfoLog`:         `LDBLogger` or `nil`, default `nil`
/// - `LDBOptionWriteBufferSize`: `size_t`-valued `NSNumber`, default 4 MB
/// - `LDBOptionMaxOpenFiles`:    `int`-valued `NSNumber` > 0, default 1000
/// - `LDBOptionCacheCapacity`:   `int`-valued `NSNumber` >= 0, default 8 MB
/// - `LDBOptionBlockSize`:       `size_t`-valued `NSNumber`, default 4 K
/// - `LDBOptionBlockRestartInterval`: `int`-valued `NSNumber`, default 16
/// - `LDBOptionCompression`:     `LDBCompression`-valued `NSNumber`, default 1
/// - `LDBOptionBloomFilterBits`: `int`-valued `NSNumber` 0...32, default 0
///
/// Iff there is an error, returns `NO` and sets the `error` pointer with
/// `LDBErrorMessageKey` set in the `userInfo`.
- (nullable instancetype)
    initWithPath:(NSString *)path
    options:(NSDictionary *)options
    error:(NSError * __autoreleasing *)error;


/// Return the `NSData` stored at `key` or `nil` if not found. The key subscript
/// operator can be used synonymously:
///
/// ```objc
/// NSData *value = database[key];
/// ```
///
/// **See also:** `snapshot`
- (NSData * __nullable)dataForKey:(NSData *)key;


/// Return the `NSData` stored at `key` or `nil` if not found.
///
/// **See also:** `-[LDBDatabase snapshot]`
- (NSData * __nullable)objectForKeyedSubscript:(NSData *)key;


/// Take an immutable snapshot of `self` for performing multiple reads
/// efficiently. This is the preferred method of reading the database.
- (LDBSnapshot *)snapshot;


/// Set the `NSData` stored at `key` to `data`. If `data` is `nil`, the
/// key-value pair is removed exactly like `[self removeDataForKey:key]` does.
/// The key subscript operator can be used synonymously:
///
/// ```objc
/// database[key] = value;
/// database[key] = nil;
/// ```
///
/// Does not flush the write on disk, which means that if the machine crashes,
/// the write may be lost.
///
/// Note that multiple updates are better performed using
/// `-[LDBDatabase write:error:]`.
///
/// Returns `NO` iff there was an error. For better error reporting, consider
/// using a write batch.
///
/// **See also:** `-[LDBDatabase write:sync:error:]`
- (BOOL)setData:(NSData * __nullable)data forKey:(NSData *)key;


/// Set the `NSData` at `key` to `data` if `data` is not `nil`. Otherwise,
/// calls `[self removeDataForKey:key]`.
///
/// Does not flush the write on disk, which means that if the machine crashes,
/// the write may be lost.
///
/// Note that multiple updates are better performed using
/// `-[LDBDatabase write:sync:error:]`.
///
/// Returns `NO` iff there was an error. For better error reporting, consider
/// using a write batch.
///
/// **See also:** `-[LDBDatabase write:sync:error:]`
- (BOOL)setObject:(NSData * __nullable)data forKeyedSubscript:(NSData *)key;


/// Remove the `NSData` stored at `key`.
///
/// Does not flush the write on disk, which means that if the machine crashes,
/// the write may be lost.
///
/// Note that this function flushes the files on disk, so multiple updates are
/// better performed using `-[LDBDatabase write:sync:error:]`.
///
/// Returns `NO` iff there was an error. For better error reporting, consider
/// using a write batch.
///
/// **See also:** `-[LDBDatabase write:sync:error:]`
- (BOOL)removeDataForKey:(NSData *)key;


/// @brief Perform the @p batch of put and delete writes to the database.
///
/// @param batch sequence of put and delete writes to perform.
///
/// @param sync whether writes are flushed to disk before the method
/// returns (similarly to @c fsync, see "man 2 fsync").
///
/// @param error Iff the write was unsuccessful and @p error is not nil, sets
/// the @p *error pointer with the @c LDBErrorMessageKey set to an @c NSString
/// in its @c userInfo.
///
/// @returns whether the write was successful.
- (BOOL)
    write:(LDBWriteBatch *)batch
    sync:(BOOL)sync
    error:(NSError * __autoreleasing *)error;

/// @brief Perform the @p batch of put and delete writes to the database.
///
/// @param batch sequence of put and delete writes to perform.
///
/// @param sync whether writes are flushed to disk before the method
/// returns (similarly to @c fsync, see "man 2 fsync").
///
/// @returns @c nil if the write was successful, otherwise an @c NSError with
/// the @c LDBErrorMessageKey set to an @c NSString in its @c userInfo.
- (NSError * __nullable)write:(LDBWriteBatch *)batch sync:(BOOL)sync;

/// @brief Get the value of a database implementation specific property @p name.
///
/// DB implementations may export properties about their state. If @p name is a
/// valid property understood by this DB implementation, returns its value.
/// Otherwise returns @c nil.
///
/// Valid property names include:
///
/// - @c "leveldb.num-files-at-level<N>" — return the number of files at level
///   @c <N>, where @c <N> is the ASCII representation of a level number, e.g.
///   @c "0"
///
/// - @c "leveldb.stats" — return a multi-line string that describes statistics
///   about the internal operation of the DB.
///
/// - @c "leveldb.sstables" — return a multi-line string that describes all
///   of the sstables that make up the DB contents.
- (NSString * __nullable)propertyNamed:(NSString *)name;

/// @brief Approximate the file system space (in bytes) used by the given key
/// @p intervals.
///
/// @param intervals the @p NSArray of @p LDBInterval values to look up.
///
/// @return as @c NSArray of @c NSNumber values the approximate file system
/// space used by the keys from @c intervals[i].start to @c intervals[i].end
- (NSArray *)approximateSizesForIntervals:(NSArray *)intervals;

/// @brief Compact the underlying storage for the key range @p interval.
///
/// In particular, deleted and overwritten versions are discarded, and the data
/// is rearranged to reduce the cost of operations needed to access the data.
/// This operation should typically only be invoked by users who understand the
/// underlying implementation.
///
/// To compact the entire database, call:
/// @code
/// [database compactInterval:[LDBInterval everything]];
/// @endcode
- (void)compactInterval:(LDBInterval *)interval;

@end

#pragma clang assume_nonnull end
