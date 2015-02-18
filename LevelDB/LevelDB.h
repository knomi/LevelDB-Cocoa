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

#import "leveldb/c.h"

leveldb_env_t* ext_leveldb_create_in_memory_env(leveldb_env_t* base_env);

NSData *ext_leveldb_get(leveldb_t *db,
                        const leveldb_readoptions_t *options,
                        const char *key,
                        size_t keylen,
                        char **errptr);

NSData *ext_leveldb_iter_key_unsafe(const leveldb_iterator_t *iter);
NSData *ext_leveldb_iter_value_unsafe(const leveldb_iterator_t *iter);

void ext_leveldb_writebatch_iterate(leveldb_writebatch_t *batch, void (^block)(NSData *key, NSData *optionalValue));

#ifdef __cplusplus
} // extern "C"
#endif
