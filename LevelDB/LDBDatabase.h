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
extern NSString * const LDBOptionReuseLogs;       // NSNumber with BOOL
extern NSString * const LDBOptionBloomFilterBits; // NSNumber with integer 0…32

#ifdef __cplusplus
} // extern "C"
#endif

// -----------------------------------------------------------------------------
#pragma mark - LDBDatabase

@interface LDBDatabase : NSObject

/// Destroy the contents of the database in the given `path` on disk. Be very
/// careful using this method.
///
/// Iff there is an error, returns `NO` and sets the `error` pointer with
/// `LDBErrorMessageKey` set in the `userInfo`.
+ (BOOL)
    destroyDatabaseAtPath:(NSString *)path
    error:(NSError * __autoreleasing *)error;


/// Try to repair the database in the given `path` on disk.
///
/// If a DB cannot be opened, you may attempt to call this method to resurrect
/// as much of the contents of the database as possible. Some data may be lost,
/// so be careful when calling this function on a database that contains
/// important information.
///
/// Iff there is an error, returns `NO` and sets the `error` pointer with
/// `LDBErrorMessageKey` set in the `userInfo`.
+ (BOOL)
    repairDatabaseAtPath:(NSString *)path
    error:(NSError * __autoreleasing *)error;


/// Create an in-memory database that is not persisted on disk.
- (instancetype)init;


/// Open the database in the given `path` on disk. If the directory doesn't
/// exist a blank database is created. Iff there is an error, returns `nil` and
/// sets the `error` pointer with `LDBErrorMessageKey` set in the `userInfo`.
///
/// Also sets up the database using the 10-bit Bloom filter.
///
/// **See also:** `-[LDBDatabase initWithPath:options:error:]`
- (nullable instancetype)initWithPath:(NSString *)path
    error:(NSError * __autoreleasing *)error;


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
/// - `LDBOptionReuseLogs`:       `BOOL`-valued `NSNumber`, default `NO` for now
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


/// Perform a `batch` of put and delete writes to the database. If `sync` is
/// `YES`, the writes are flushed to disk (similarly to `fsync()`, see
/// `man 2 fsync`) before the method returns.
///
/// Iff there is an error, returns `NO` and sets the `error` pointer with
/// `LDBErrorMessageKey` set in the `userInfo`.
- (BOOL)
    write:(LDBWriteBatch *)batch
    sync:(BOOL)sync
    error:(NSError * __autoreleasing *)error;

/// DB implementations may export properties about their state. If `name` is a
/// valid property understood by this DB implementation, returns its value.
/// Otherwise returns `nil`.
///
/// Valid property names include:
///
/// - `"leveldb.num-files-at-level<N>"` -- return the number of files at level
///   `<N>`, where `<N>` is an ASCII representation of a level number (e.g.
///   `"0"`).
/// - `"leveldb.stats"` -- returns a multi-line string that describes statistics
///   about the internal operation of the DB.
/// - `"leveldb.sstables"` -- returns a multi-line string that describes all
///   of the sstables that make up the db contents.
/// - `"leveldb.approximate-memory-usage"` -- returns the approximate number of
///   bytes of memory in use by the DB.
- (NSString *)propertyNamed:(NSString *)name;

/// Retrieve as an `NSArray` of `NSNumber`s the approximate file system space
/// used by the keys `intervals[i].start ..< intervals[i].end` where `intervals`
/// is an array of `LDBInterval`s.
- (NSArray <NSNumber *> *)approximateSizesForIntervals:(NSArray <LDBInterval *> *)intervals;

/// Compact the underlying storage for the key range `interval`. In particular,
/// deleted and overwritten versions are discarded, and the data is rearranged
/// to reduce the cost of operations needed to access the data. This operation
/// should typically only be invoked by users who understand the underlying
/// implementation.
///
/// To compact the entire database, pass `[LDBInterval everything]` as interval.
- (void)compactInterval:(LDBInterval *)interval;

/// Drop the on-memory read cache of the database to relief memory shortage.
- (void)pruneCache;

@end

#pragma clang assume_nonnull end
