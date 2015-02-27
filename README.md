LevelDB
=======

Simple but versatile Objective-C & Swift wrapper around the [LevelDB][] key-value storage library written at Google.

The base building block is a `LDBDatabase` of key-value pairs `(NSData, NSData)` ordered by key. The database can be either in-memory or persisted on disk, and snapshots are used to make reads consistent.

Quick example (Objective-C):

```objc
#import <LevelDB/LevelDB.h>

LDBDatabase *database = [[LDBDatabase alloc] initWithPath:@"demo.ldb"];

NSData *key1 = [@"foo" dataUsingEncoding:NSUTF8StringEncoding];
NSData *val1 = [@"FOO" dataUsingEncoding:NSUTF8StringEncoding];
database[key1] = val1;

NSCAssert([database[key1] isEqual:val1], @"");

LDBWriteBatch *batch = [LDBWriteBatch new];
for (NSString *k in @[@"aha", @"bar", @"baz", @"boo", @"xyz"]) {
    batch[[k dataUsingEncoding:NSUTF8StringEncoding]] =
        [[k uppercaseString] dataUsingEncoding:NSUTF8StringEncoding];
}
NSError *error;
if (![database write:batch sync:NO error:&error]) {
    NSLog(@"batch write failed: %@", error);
} else {
    LDBSnapshot *snapshot = database.snapshot;

    NSLog(@"snapshot contents:");
    for (LDBEnumerator *e = snapshot.enumerator; e.isValid; [e step]) {
        NSLog(@"  - %@: %@",
            [[NSString alloc] initWithData:e.key encoding:NSUTF8StringEncoding],
            [[NSString alloc] initWithData:e.value encoding:NSUTF8StringEncoding]);
    }
    // snapshot contents:
    //   - aha: AHA
    //   - bar: BAR
    //   - baz: BAZ
    //   - boo: BOO
    //   - foo: FOO
    //   - xyz: XYZ

    LDBSnapshot *clamped = [snapshot prefix:[@"ba" dataUsingEncoding:NSUTF8StringEncoding]];
    NSLog(@"clamped snapshot contents:");
    for (LDBEnumerator *e = clamped.enumerator; e.isValid; [e step]) {
        NSLog(@"  - %@: %@",
            [[NSString alloc] initWithData:e.key encoding:NSUTF8StringEncoding],
            [[NSString alloc] initWithData:e.value encoding:NSUTF8StringEncoding]);
    }
    // clamped snapshot contents:
    //   - bar: BAR
    //   - baz: BAZ
}
```

[LevelDB]: https://github.com/google/leveldb
