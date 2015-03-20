//
//  LDBPrivate.hpp
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LDBDatabase.h"
#import "LDBLogger.h"
#import "LDBSnapshot.h"
#import "LDBWriteBatch.h"

#import "leveldb/slice.h"
#import "leveldb/options.h"

#define LDB_UNIMPLEMENTED() /************************************************/ \
    do {                                                                       \
        NSLog(@"%s:%ull: unimplemented %s", __FILE__, __LINE__, __FUNCTION__); \
        abort();                                                               \
    } while(0)                                                                 \
    /**/



namespace leveldb {
    class DB;
    class Logger;
    class Status;
    class Snapshot;
    class WriteBatch;
}


@interface LDBDatabase (Private)
- (leveldb::DB *)private_database;
@end



@interface LDBSnapshot (Private)
- (leveldb::Snapshot const *)private_snapshot;
- (LDBDatabase *)private_db;
- (leveldb::ReadOptions)private_readOptions;
@end



@interface LDBWriteBatch (Private)
- (leveldb::WriteBatch *)private_batch;
@end



@interface LDBLogger (Private)
- (leveldb::Logger *)private_logger;
@end



@interface NSObject (LevelDB)
/// Return `object` if it is a kind of `self`, otherwise `nil`.
+ (instancetype)ldb_cast:(id)object;
@end



@interface NSNumber (LevelDB)
/// Return `self` only if it contains a `BOOL`.
@property (nonatomic, readonly) NSNumber * ldb_bool;
@end



namespace leveldb_objc {

/// Check whether the `status` is successful. If not, and `error` is not `NULL`,
/// set the `*error` to `to_NSError(status)`.
BOOL objc_result(leveldb::Status const &status,
                 NSError * __autoreleasing *error);

/// Convert the `status` into an `NSError` with `domain` equal to
/// `LDBErrorDomain`, `code` one of `LDBError`, and `userInfo` filled with
/// `LDBErrorMessageKey` as reported by `status.ToString()`.
NSError *to_NSError(leveldb::Status const &status);

/// Copy the bytes of `slice` into an immutable `NSData`.
NSData *to_NSData(leveldb::Slice const &slice);

/// Convert `NSData` into (a temporary, non-data-owning) `leveldb::Slice`.
leveldb::Slice to_Slice(NSData *data);

NSComparisonResult compare(NSData *left, NSData *right);
NSData *min(NSData *left, NSData *right);
NSData *max(NSData *left, NSData *right);

NSData *lexicographicalNextSibling(NSData *data);
NSData *lexicographicalFirstChild(NSData *data);

NSData *dropLength(NSUInteger length, NSData *data);
NSData *cutPrefix(NSData *prefix, NSData *data);
NSData *concat(NSData *left, NSData *right);

} // namespace leveldb_objc
