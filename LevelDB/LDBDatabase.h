//
//  LDBDatabase.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

@class LDBSnapshot;
@class LDBWriteBatch;

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

@interface LDBDatabase : NSObject


/// Destroy the contents of the database in the given `path` on disk. Be very
/// careful using this method.
///
/// Iff there is an error, returns `NO` and sets the `error` pointer with
/// `LDBErrorMessageKey` set in the `userInfo`.
+ (BOOL)
    destroyDatabaseWithPath:(NSString *)path
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
    repairDatabaseWithPath:(NSString *)path
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
- (instancetype)initWithPath:(NSString *)path;


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
- (instancetype)
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
- (NSData *)objectForKey:(NSData *)key;


/// Return the `NSData` stored at `key` or `nil` if not found.
///
/// **See also:** `-[LDBDatabase snapshot]`
- (NSData *)objectForKeyedSubscript:(NSData *)key;


/// Take an immutable snapshot of `self` for performing multiple reads
/// efficiently. This is the preferred method of reading the database.
- (LDBSnapshot *)snapshot;


/// Set the `NSData` stored at `key` to `object` if `object` is not `nil`.
/// Otherwise, calls `[self removeObjectForKey:key]`. The key subscript operator
/// can be used synonymously:
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
/// Returns `NO` iff the writing failed.
///
/// **See also:** `-[LDBDatabase write:sync:error:]`
- (BOOL)setObject:(NSData *)object forKey:(NSData *)key;


/// Set the `NSData` at `key` to `object` if `object` is not `nil`. Otherwise,
/// calls `[self removeObjectForKey:key]`.
///
/// Does not flush the write on disk, which means that if the machine crashes,
/// the write may be lost.
///
/// Note that multiple updates are better performed using
/// `-[LDBDatabase write:sync:error:]`.
///
/// **See also:** `-[LDBDatabase write:sync:error:]`
- (BOOL)setObject:(NSData *)object forKeyedSubscript:(NSData *)key;


/// Remove the `NSData` stored at `key`.
///
/// Does not flush the write on disk, which means that if the machine crashes,
/// the write may be lost.
///
/// Note that this function flushes the files on disk, so multiple updates are
/// better performed using `-[LDBDatabase write:sync:error:]`.
///
/// **See also:** `-[LDBDatabase write:sync:error:]`
- (void)removeObjectForKey:(NSData *)key;


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

@end

@interface LDBLogger : NSObject
+ (instancetype)loggerWithBlock:(void (^)(NSString *message))block;
- (instancetype)initWithBlock:(void (^)(NSString *message))block;
@property (nonatomic, readonly) void (^block)(NSString *message);
@end

#ifdef __cplusplus
} // extern "C"
#endif
