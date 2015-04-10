//
//  LDBEnumerator.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

#pragma clang assume_nonnull begin

@class LDBDatabase;
@class LDBSnapshot;

@interface LDBEnumerator : NSEnumerator

- (instancetype)init __attribute__((unavailable("init not available")));

/// Create an enumerator to iterate over the `snapshot`. It is idiomatic to call
/// `[snapshot enumerator]` instead.
- (instancetype)initWithSnapshot:(LDBSnapshot *)snapshot;

/// The snapshot this enumerator is iterating over.
@property (nonatomic, readonly) LDBSnapshot *snapshot;

/// Check whether the enumerator currently has a key-value pair, and thus can be
/// stepped at least one more time. The enumerator turns invalid when there are
/// no more key-value pairs left.
@property (nonatomic, readonly) BOOL isValid;

/// The `key` of the current key-value pair if `self.isValid`, `nil` otherwise.
@property (nonatomic, readonly, copy) NSData * __nullable key;

/// The `value` of the current key-value pair if `self.isValid`, `nil`
/// otherwise.
@property (nonatomic, readonly, copy) NSData * __nullable value;

/// If the enumerator is still valid, move to the next position, possibly
/// invalidating the enumerator. Otherwise a no-op.
- (void)step;

/// If the enumerator is still valid, return the current key-value pair as an
/// `NSArray` of two `NSData` objects and step to the next position (possibly
/// invalidating the enumerator). Otherwise, return `nil`.
- (NSArray *)nextObject;

@end

#pragma clang assume_nonnull end
