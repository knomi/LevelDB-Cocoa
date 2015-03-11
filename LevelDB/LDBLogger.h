//
//  LDBLogger.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LevelDB/LDBCompatibility.h>

#pragma clang assume_nonnull begin

@interface LDBLogger : NSObject

+ (instancetype)loggerWithBlock:(void (^)(NSString *message))block;

- (instancetype)init __attribute__((unavailable("init not available")));
- (instancetype)initWithBlock:(void (^)(NSString *message))block;

@property (nonatomic, readonly) void (^block)(NSString *message);

@end

#pragma clang assume_nonnull end
