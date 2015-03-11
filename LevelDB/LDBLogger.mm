//
//  LDBLogger.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBLogger.h"
#import "LDBPrivate.hpp"
#include "leveldb/env.h"

namespace leveldb_objc {
struct block_logger_t : leveldb::Logger {

    void (^block)(NSString *message);
    
    virtual void Logv(const char *f, va_list a) override {
        if (!block) return;
        auto m = [[NSString alloc] initWithFormat:@(f) locale:nil arguments:a];
        if (m) block(m);
    }
    
};
} // namespace leveldb_objc

@interface LDBLogger () {
    leveldb_objc::block_logger_t _impl;
}
@end

@implementation LDBLogger : NSObject

+ (instancetype)loggerWithBlock:(void (^)(NSString *message))block
{
    return [[self alloc] initWithBlock:block];
}

- (instancetype)init
{
    @throw [NSException exceptionWithName:NSInternalInconsistencyException
                                   reason:@"-init is not a valid initializer for the class LDBLogger"
                                 userInfo:nil];
    return nil;
}

- (instancetype)initWithBlock:(void (^)(NSString *message))block
{
    if (!(self = [super init])) {
        return nil;
    }
    _impl.block = [block copy];
    return self;
}

- (void (^)(NSString *))block
{
    return _impl.block;
}

@end // LDBLogger

@implementation LDBLogger (Private)

- (leveldb::Logger *)private_logger
{
    return &_impl;
}

@end
