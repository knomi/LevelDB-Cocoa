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

#import <LevelDB/LDBDatabase.h>
#import <LevelDB/LDBEnumerator.h>
#import <LevelDB/LDBError.h>
#import <LevelDB/LDBInterval.h>
#import <LevelDB/LDBLogger.h>
#import <LevelDB/LDBSnapshot.h>
#import <LevelDB/LDBWriteBatch.h>
#import <LevelDB/NSData+LDB.h>

#ifdef __cplusplus
} // extern "C"
#endif
