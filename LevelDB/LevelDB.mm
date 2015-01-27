//
//  LevelDB.mm
//  LevelDB
//
//  Created by Pyry Jahkola on 27.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//


#import <Foundation/Foundation.h>
#import "helpers/memenv/memenv.h"
#import "leveldb/c.h"
#import "leveldb/db.h"
#import "leveldb/options.h"
#import "leveldb/status.h"

extern "C" {

static bool SaveError(char** errptr, const leveldb::Status& s) {
    assert(errptr != NULL);
    if (s.ok()) {
        return false;
    } else if (*errptr == NULL) {
        *errptr = strdup(s.ToString().c_str());
    } else {
        free(*errptr);
        *errptr = strdup(s.ToString().c_str());
    }
    return true;
}

struct leveldb_t {
    leveldb::DB* rep;
};

struct leveldb_env_t {
    leveldb::Env* rep;
    bool is_default;
};

struct leveldb_readoptions_t {
    leveldb::ReadOptions rep;
};

leveldb_env_t *ext_leveldb_create_in_memory_env(leveldb_env_t *base_env) {
    leveldb_env_t *result = new leveldb_env_t;
    result->rep = leveldb::NewMemEnv(base_env->rep);
    return result;
}

NSData *ext_leveldb_get(leveldb_t *db,
                        const leveldb_readoptions_t *options,
                        const char *key,
                        size_t keylen,
                        char **errptr)
{
    std::string tmp;
    leveldb::Status s = db->rep->Get(options->rep, leveldb::Slice(key, keylen), &tmp);
    if (s.ok()) {
        return [NSData dataWithBytes:tmp.c_str() length:tmp.size()];
    } else {
        if (!s.IsNotFound()) {
            SaveError(errptr, s);
        }
        return nil;
    }
}

} // extern "C"
