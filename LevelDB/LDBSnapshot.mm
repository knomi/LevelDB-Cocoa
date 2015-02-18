//
//  LDBSnapshot.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBSnapshot.h"

#import "LDBDatabase.h"
#import "LDBPrivate.hpp"

#include "leveldb/db.h"

#include <memory>
#include <functional>

@implementation LDBSnapshot {
    std::shared_ptr<leveldb::Snapshot const> _impl;
}

- (instancetype)initWithDatabase:(LDBDatabase *)database
{
    if (!(self = [super init])) {
        return nil;
    }
    
    _impl.reset(database.impl->GetSnapshot(),
                [database](leveldb::Snapshot const * snapshot)
    {
        database.impl->ReleaseSnapshot(snapshot);
    });
    
    return self;
}

@end

@implementation LDBSnapshot (Private)

- (leveldb::Snapshot const *)impl
{
    return _impl.get();
}

@end
