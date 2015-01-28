//
//  LevelDB.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
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

NSData *ext_leveldb_iter_key_unsafe(const leveldb_iterator_t *iter)
{
    size_t length = 0;
    const char *bytes = leveldb_iter_key(iter, &length);
    return [NSData dataWithBytesNoCopy:(void *)bytes length:length freeWhenDone:false];
}

NSData *ext_leveldb_iter_value_unsafe(leveldb_iterator_t *iter)
{
    size_t length = 0;
    const char *bytes = leveldb_iter_value(iter, &length);
    return [NSData dataWithBytesNoCopy:(void *)bytes length:length freeWhenDone:false];
}

struct writebatch_iterator_t {
    void (^block)(NSData *key, NSData *optionalValue);
};

static void writebatch_put(void *iter, const char *key, size_t keylen, const char *value, size_t valuelen) {
    writebatch_iterator_t *it = static_cast<writebatch_iterator_t *>(iter);
    it->block([NSData dataWithBytesNoCopy:(void *)key   length:keylen   freeWhenDone:NO],
              [NSData dataWithBytesNoCopy:(void *)value length:valuelen freeWhenDone:NO]);
}

static void writebatch_deleted(void *iter, const char *key, size_t keylen) {
    writebatch_iterator_t *it = static_cast<writebatch_iterator_t *>(iter);
    it->block([NSData dataWithBytesNoCopy:(void *)key length:keylen freeWhenDone:NO], nil);
}

void ext_leveldb_writebatch_iterate(leveldb_writebatch_t *batch, void (^block)(NSData *key, NSData *optionalValue))
{
    writebatch_iterator_t iter;
    iter.block = block;
    leveldb_writebatch_iterate(batch, &iter, writebatch_put, writebatch_deleted);
}

} // extern "C"
