//
//  LDBPrivate.hpp
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "leveldb/status.h"

BOOL objc_result(leveldb::Status const & status,
                 NSError * __autoreleasing * error);
NSError * to_NSError(leveldb::Status const & status);
