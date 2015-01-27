//
//  InMemory.mm
//  LevelDB
//
//  Created by Pyry Jahkola on 27.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

#import "helpers/memenv/memenv.h"

extern "C" struct leveldb_env_t {
  leveldb::Env* rep;
  bool is_default;
};

extern "C" leveldb_env_t* ext_leveldb_create_in_memory_env(leveldb_env_t* base_env) {
  leveldb_env_t* result = new leveldb_env_t;
  result->rep = leveldb::NewMemEnv(base_env->rep);
  return result;
}
