//
//  LDBError.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Foundation/FoundationErrors.h>

#pragma clang assume_nonnull begin

#ifdef __cplusplus
extern "C" {
#endif

extern NSString * const LDBErrorDomain;

extern NSString * const LDBErrorMessageKey; // NSString

@interface NSError (LevelDB)
@property (readonly, copy) NSString * __nullable ldb_errorMessage;
@end

/// NSError codes in LDBErrorDomain.
typedef NS_ENUM(NSInteger, LDBError) {
    LDBErrorOk              =  0,
    LDBErrorNotFound        =  1,
    LDBErrorCorruption      =  2,
    LDBErrorIOError         =  5,
    LDBErrorOther           = -1
};

#ifdef __cplusplus
} // extern "C"
#endif

#pragma clang assume_nonnull end
