//
//  LDBIterator.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

@class LDBDatabase;
@class LDBSnapshot;

@interface LDBIterator : NSObject

- (instancetype)init __attribute__((unavailable("init not available")));
- (instancetype)initWithSnapshot:(LDBSnapshot *)snapshot;

@property (nonatomic, readonly) LDBSnapshot *snapshot;
@property (nonatomic, readonly) BOOL isValid;
@property (nonatomic, readonly, copy) NSData *key;
@property (nonatomic, readonly, copy) NSData *value;

- (void)step;

@end
