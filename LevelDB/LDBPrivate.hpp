//
//  LDBPrivate.hpp
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "leveldb/status.h"

#define LDB_UNIMPLEMENTED() /************************************************/ \
    do {                                                                       \
        NSLog(@"%s:%ull: unimplemented %s", __FILE__, __LINE__, __FUNCTION__); \
        abort();                                                               \
    } while(0)                                                                 \
    /**/



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
BOOL objc_result(leveldb::Status const & status,
                 NSError * __autoreleasing * error);

/// Convert the `status` into an `NSError` with `domain` equal to
/// `LDBErrorDomain`, `code` one of `LDBError`, and `userInfo` filled with
/// `LDBErrorMessageKey` as reported by `status.ToString()`.
NSError * to_NSError(leveldb::Status const & status);

/// Convert `NSData` into (a temporary, non-data-owning) `leveldb::Slice`.
leveldb::Slice to_Slice(NSData * data);

} // namespace leveldb_objc
