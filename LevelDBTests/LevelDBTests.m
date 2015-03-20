//
//  LevelDBTests.m
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <LevelDB/LevelDB.h>

@implementation NSString (LevelDBTests)
- (NSData *)ldb_UTF8Data
{
    return [self dataUsingEncoding:NSUTF8StringEncoding];
}
@end

@implementation NSData (LevelDBTests)
- (NSString *)ldb_UTF8String
{
    return [[NSString alloc] initWithData:self encoding:NSUTF8StringEncoding];
}
@end

@interface LevelDBTests : XCTestCase
@property NSString *path;
@end

@implementation LevelDBTests

- (void)setUp {
    [super setUp];
    NSString *unique = [NSProcessInfo processInfo].globallyUniqueString;
    self.path = [NSTemporaryDirectory() stringByAppendingPathComponent:unique];
}

- (void)tearDown {
    [LDBDatabase destroyDatabaseAtPath:self.path error:nil];
    NSAssert(![[NSFileManager defaultManager] fileExistsAtPath:self.path], @"");
    [super tearDown];
}

- (void)testExample {
    // This is an example of a functional test case.
    LDBDatabase *db = [LDBDatabase new];
    
    if (YES) {
        LDBSnapshot *empty = [db snapshot];
        for (LDBEnumerator *e = empty.enumerator; e.isValid; [e step]) {
            XCTFail(@"expected empty snapshot, got (%@, %@)", e.key, e.value);
        }
    }
    
    if (YES) {
        db[@"b".ldb_UTF8Data] = @"B".ldb_UTF8Data;
        db[@"d".ldb_UTF8Data] = @"D".ldb_UTF8Data;
        db[@"e".ldb_UTF8Data] = @"E".ldb_UTF8Data;
        db[@"d".ldb_UTF8Data] = nil;

        LDBSnapshot *snap = [db snapshot];
        XCTAssertEqualObjects(snap.enumerator.allObjects, (@[
            @[@"b".ldb_UTF8Data, @"B".ldb_UTF8Data],
            @[@"e".ldb_UTF8Data, @"E".ldb_UTF8Data],
        ]));
    }
        
    if (YES) {
        LDBWriteBatch *batch = [LDBWriteBatch new];
        batch[@"b".ldb_UTF8Data] = @"!".ldb_UTF8Data;
        batch[@"a".ldb_UTF8Data] = @"A".ldb_UTF8Data;
        batch[@"e".ldb_UTF8Data] = nil;
        batch[@"c".ldb_UTF8Data] = @"C".ldb_UTF8Data;
        NSError *error;
        BOOL ok = [db write:batch sync:NO error:&error];
        XCTAssert(ok);
        XCTAssertNil(error);
    }
    
    if (YES) {
        LDBSnapshot *snap = [db snapshot];
        XCTAssertEqualObjects(snap.enumerator.allObjects, (@[
            @[@"a".ldb_UTF8Data, @"A".ldb_UTF8Data],
            @[@"b".ldb_UTF8Data, @"!".ldb_UTF8Data],
            @[@"c".ldb_UTF8Data, @"C".ldb_UTF8Data],
        ]));
    }
}

- (void)testDemo
{
    LDBDatabase *database = [[LDBDatabase alloc] initWithPath:self.path];

    NSData *key1 = @"foo".ldb_UTF8Data;
    NSData *val1 = @"FOO".ldb_UTF8Data;
    database[key1] = val1;

    NSCAssert([database[key1] isEqual:val1], @"");

    LDBWriteBatch *batch = [LDBWriteBatch new];
    for (NSString *k in @[@"aha", @"bar", @"baz", @"boo", @"xyz"]) {
        batch[k.ldb_UTF8Data] =
            [k uppercaseString].ldb_UTF8Data;
    }
    NSError *error;
    if (![database write:batch sync:NO error:&error]) {
        NSLog(@"batch write failed: %@", error);
    } else {
        LDBSnapshot *snapshot = database.snapshot;

        NSLog(@"snapshot contents:");
        for (LDBEnumerator *e = snapshot.enumerator; e.isValid; [e step]) {
            NSLog(@"  - %@: %@", e.key.ldb_UTF8String, e.value.ldb_UTF8String);
        }
        XCTAssertEqualObjects(snapshot.enumerator.allObjects, (@[
            @[@"aha".ldb_UTF8Data, @"AHA".ldb_UTF8Data],
            @[@"bar".ldb_UTF8Data, @"BAR".ldb_UTF8Data],
            @[@"baz".ldb_UTF8Data, @"BAZ".ldb_UTF8Data],
            @[@"boo".ldb_UTF8Data, @"BOO".ldb_UTF8Data],
            @[@"foo".ldb_UTF8Data, @"FOO".ldb_UTF8Data],
            @[@"xyz".ldb_UTF8Data, @"XYZ".ldb_UTF8Data],
        ]));

        LDBSnapshot *clamped = [snapshot prefixed:@"ba".ldb_UTF8Data];
        NSLog(@"clamped snapshot contents:");
        for (NSArray *pair in clamped.enumerator) {
            NSLog(@"  - %@: %@", [pair[0] ldb_UTF8String], [pair[1] ldb_UTF8String]);
        }
        XCTAssertEqualObjects(clamped.enumerator.allObjects, (@[
            @[@"r".ldb_UTF8Data, @"BAR".ldb_UTF8Data],
            @[@"z".ldb_UTF8Data, @"BAZ".ldb_UTF8Data],
        ]));
    }
}

@end
