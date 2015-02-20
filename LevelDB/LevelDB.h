//
//  LevelDB.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

#ifdef __cplusplus
extern "C" {
#endif

//! Project version number for LevelDB.
FOUNDATION_EXPORT double LevelDBVersionNumber;

//! Project version string for LevelDB.
FOUNDATION_EXPORT const unsigned char LevelDBVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <LevelDB/PublicHeader.h>

#import "LDBDatabase.h"
#import "LDBError.h"
#import "LDBIterator.h"
#import "LDBLogger.h"
#import "LDBSnapshot.h"
#import "LDBWriteBatch.h"
#import "NSData+LDB.h"

#ifdef __cplusplus
} // extern "C"
#endif
