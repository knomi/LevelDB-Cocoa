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
- (instancetype)initWithSnapshot:(LDBSnapshot *)snapshot;

@property (nonatomic, readonly) LDBSnapshot *snapshot;
@property (nonatomic, readonly) BOOL isValid;
@property (nonatomic, readonly, copy, nullable) NSData *key;
@property (nonatomic, readonly, copy, nullable) NSData *value;

- (void)step;
- (NSArray *)nextObject;

@end

#pragma clang assume_nonnull end
