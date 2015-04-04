//
//  NSData+LDB.h
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <LevelDB/LDBCompatibility.h>

#pragma clang assume_nonnull begin

@interface NSData (LDB)

/// Compare `left` to `right` lexicographically. This method accepts `nil` as
/// inputs to denote "infinity", or the infinite sequence of `0xff` bytes which
/// compares greater than any non-`nil` argument.
///
/// For any valid inputs, the following identity always holds:
/// ```objc
/// [ldb_compareLeft:left right:right] == -[ldb_compareLeft:right right:left]
/// ```
+ (NSComparisonResult)
    ldb_compareLeft:(NSData * __nullable)left
    right:          (NSData * __nullable)right;

/// Calculate the byte sequence with equal length to `self` that is "one
/// greater", or the unique lexicographical successor to `self`. If no such
/// data can be found (i.e. `self` has zero length or consists of all `0xff`),
/// returns `nil` to mark "infinity" (the infinite sequence of `0xff` bytes).
///
/// **Remark:** Since the lexicographical next sibling of "infinity" is
/// "infinity", sending this selector to `nil` produces consistent results.
- (NSData * __nullable)ldb_lexicographicalNextSibling;

/// Get the immediate lexicographical successor to `self`, with length
/// `self.length + 1`. Returns a copy of `self` with the `0x00` byte appended.
///
/// **Remark:** Since the lexicographical first child of "infinity" is
/// "infinity", sending this selector to `nil` produces consistent results.
- (NSData *)ldb_lexicographicalFirstChild;

@end

#pragma clang assume_nonnull end
