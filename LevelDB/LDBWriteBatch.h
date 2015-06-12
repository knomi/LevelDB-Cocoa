//
//  LDBWriteBatch.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma clang assume_nonnull begin

@interface LDBWriteBatch : NSObject

/// Create a new write batch with an empty `prefix`.
- (instancetype)init;

/// Create a new write batch with the given `prefix`. Any keys set or deleted
/// through `self` will have `prefix` prepended to the key.
- (instancetype)initWithPrefix:(NSData *)prefix;

/// The key prefix to be applied to all keys modified.
@property (nonatomic, readonly, copy) NSData * prefix;

/// Create a prefixed proxy write batch to write keys of `self` with another
/// `prefix` applied to the key. The result has a prefix of `self.prefix` and
/// `prefix` concatenated, and shares the backing memory of `self`.
///
/// Remark: It is not thread-safe to write to `self` and to the returned write
/// batch without synchronization.
- (LDBWriteBatch *)prefixed:(NSData *)prefix;

/// Fake method to allow the key subscript operator to work. Always returns
/// `nil`.
- (NSData * __nullable)objectForKeyedSubscript:(NSData *)key;

/// Set the value for `key` to `data`, or remove the `key` if `data` is `nil`.
- (void)setObject:(NSData * __nullable)data forKeyedSubscript:(NSData *)key;

/// Set the value for `key` to `data`, or remove the `key` if `data` is `nil`.
- (void)setData:(NSData * __nullable)data forKey:(NSData *)key;

/// Remove the `key`.
- (void)removeDataForKey:(NSData *)key;

/// Iterate over the write batch. This function is probably mainly useful for
/// debugging purposes. Where `[self removeDataForKey:key]` has been called, the
/// block is called with `(key, nil)`, respectively.
- (void)enumerate:(__attribute__((noescape)) void (^)(NSData *key, NSData * __nullable data))block;

@end

#pragma clang assume_nonnull end
