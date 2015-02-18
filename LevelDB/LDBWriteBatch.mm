//
//  LDBWriteBatch.mm
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import "LDBWriteBatch.h"

#define LDB_UNIMPLEMENTED() /************************************************/ \
    do {                                                                       \
        NSLog(@"%s:%ull: unimplemented %s", __FILE__, __LINE__, __FUNCTION__); \
        abort();                                                               \
    } while(0)                                                                 \
    /**/

@implementation LDBWriteBatch

@end
