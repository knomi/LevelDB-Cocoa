//
//  LDBCompatibility.h
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//


// Hiding noescape in Swift 1.1
#if __has_attribute(noescape)
#  define LDB_NOESCAPE __attribute__((noescape))
#else
#  define LDB_NOESCAPE
#endif


// Hiding nullability annotations in Swift 1.1
#if __has_feature(nullability)
#  define LDB_NULLABLE_INSTANCETYPE nullable instancetype
#else
#  define LDB_NULLABLE_INSTANCETYPE instancetype
#  if !defined(__nonnull)
#    define __nonnull
#  endif
#  if !defined(__nullable)
#    define __nullable
#  endif
#  if !defined(__null_unspecified)
#    define __null_unspecified
#  endif
#endif
