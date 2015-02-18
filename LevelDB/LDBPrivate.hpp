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
- (leveldb::DB *)impl;
@end



@interface LDBSnapshot (Private)
- (leveldb::Snapshot const *)impl;
@end



@interface LDBWriteBatch (Private)
- (leveldb::WriteBatch *)impl;
@end



@interface LDBLogger (Private)
- (leveldb::Logger *)impl;
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
NSError * to_NSError(leveldb::Status const &status);

/// Convert `NSData` into (a temporary, non-data-owning) `leveldb::Slice`.
leveldb::Slice to_Slice(NSData *data);

NSComparisonResult compare(NSData *left, NSData *right);
NSData *min(NSData *left, NSData *right);
NSData *max(NSData *left, NSData *right);

NSData *lexicographicalSuccessor(NSData *data);
NSData *lexicographicalChild(NSData *data);

} // namespace leveldb_objc
