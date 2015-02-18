//
//  LDBSnapshot.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

@class LDBDatabase;

@interface LDBSnapshot : NSObject

- (instancetype)initWithDatabase:(LDBDatabase *)database;

@end

#ifdef __cplusplus
} // extern "C"
#endif
