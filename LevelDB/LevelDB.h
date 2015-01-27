//
//  LevelDB.h
//  LevelDB
//
//  Created by Pyry Jahkola on 26.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

#import <Foundation/Foundation.h>

//! Project version number for LevelDB.
FOUNDATION_EXPORT double LevelDBVersionNumber;

//! Project version string for LevelDB.
FOUNDATION_EXPORT const unsigned char LevelDBVersionString[];

// In this header, you should import all the public headers of your framework using statements like #import <LevelDB/PublicHeader.h>

#import "leveldb/c.h"

leveldb_env_t* ext_leveldb_create_in_memory_env(leveldb_env_t* base_env);
