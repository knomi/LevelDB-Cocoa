//
//  LDBEnumerator.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LevelDB/LDBCompatibility.h>

#pragma clang assume_nonnull begin

@class LDBDatabase;
@class LDBSnapshot;

@interface LDBEnumerator : NSEnumerator

- (instancetype)init __attribute__((unavailable("init not available")));
- (instancetype)initWithSnapshot:(LDBSnapshot *)snapshot;

@property (nonatomic, readonly) LDBSnapshot *snapshot;
@property (nonatomic, readonly) BOOL isValid;
@property (nonatomic, readonly, copy) NSData * __nullable key;
@property (nonatomic, readonly, copy) NSData * __nullable value;

- (void)step;
- (NSArray *)nextObject;

@end

#pragma clang assume_nonnull end
