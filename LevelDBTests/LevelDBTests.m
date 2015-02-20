//
//  LevelDBTests.m
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

#import <XCTest/XCTest.h>
#import <LevelDB/LevelDB.h>

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
        for (LDBIterator *it = empty.iterate; it.isValid; [it step]) {
            XCTFail(@"expected empty snapshot, got (%@, %@)", it.key, it.value);
        }
    }
    
    if (YES) {
        db[[@"b" dataUsingEncoding:NSUTF8StringEncoding]] = [@"B" dataUsingEncoding:NSUTF8StringEncoding];
        db[[@"d" dataUsingEncoding:NSUTF8StringEncoding]] = [@"D" dataUsingEncoding:NSUTF8StringEncoding];
        db[[@"e" dataUsingEncoding:NSUTF8StringEncoding]] = [@"E" dataUsingEncoding:NSUTF8StringEncoding];
        db[[@"d" dataUsingEncoding:NSUTF8StringEncoding]] = nil;

        LDBSnapshot *snap = [db snapshot];
        LDBIterator *it = snap.iterate;
        XCTAssert(it.isValid);
        XCTAssertEqualObjects(it.key,   [@"b" dataUsingEncoding:NSUTF8StringEncoding]);
        XCTAssertEqualObjects(it.value, [@"B" dataUsingEncoding:NSUTF8StringEncoding]);
        [it step];
        XCTAssert(it.isValid);
        XCTAssertEqualObjects(it.key,   [@"e" dataUsingEncoding:NSUTF8StringEncoding]);
        XCTAssertEqualObjects(it.value, [@"E" dataUsingEncoding:NSUTF8StringEncoding]);
        [it step];
        XCTAssertFalse(it.isValid);
    }
        
    if (YES) {
        LDBWriteBatch *batch = [LDBWriteBatch new];
        batch[[@"b" dataUsingEncoding:NSUTF8StringEncoding]] = [@"!" dataUsingEncoding:NSUTF8StringEncoding];
        batch[[@"a" dataUsingEncoding:NSUTF8StringEncoding]] = [@"A" dataUsingEncoding:NSUTF8StringEncoding];
        batch[[@"e" dataUsingEncoding:NSUTF8StringEncoding]] = nil;
        batch[[@"c" dataUsingEncoding:NSUTF8StringEncoding]] = [@"C" dataUsingEncoding:NSUTF8StringEncoding];
        NSError *error;
        BOOL ok = [db write:batch sync:NO error:&error];
        XCTAssert(ok);
        XCTAssertNil(error);
    }
    
    if (YES) {
        LDBSnapshot *snap = [db snapshot];
        LDBIterator *it = snap.iterate;
        XCTAssert(it.isValid);
        XCTAssertEqualObjects(it.key,   [@"a" dataUsingEncoding:NSUTF8StringEncoding]);
        XCTAssertEqualObjects(it.value, [@"A" dataUsingEncoding:NSUTF8StringEncoding]);
        [it step];
        XCTAssert(it.isValid);
        XCTAssertEqualObjects(it.key,   [@"b" dataUsingEncoding:NSUTF8StringEncoding]);
        XCTAssertEqualObjects(it.value, [@"!" dataUsingEncoding:NSUTF8StringEncoding]);
        [it step];
        XCTAssert(it.isValid);
        XCTAssertEqualObjects(it.key,   [@"c" dataUsingEncoding:NSUTF8StringEncoding]);
        XCTAssertEqualObjects(it.value, [@"C" dataUsingEncoding:NSUTF8StringEncoding]);
        [it step];
        XCTAssertFalse(it.isValid);
    }
}

- (void)testDemo
{
    LDBDatabase *database = [[LDBDatabase alloc] initWithPath:self.path];

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
        for (LDBIterator *it = snapshot.iterate; it.isValid; [it step]) {
            NSLog(@"  - %@: %@",
                [[NSString alloc] initWithData:it.key encoding:NSUTF8StringEncoding],
                [[NSString alloc] initWithData:it.value encoding:NSUTF8StringEncoding]);
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
        for (LDBIterator *it = clamped.iterate; it.isValid; [it step]) {
            NSLog(@"  - %@: %@",
                [[NSString alloc] initWithData:it.key encoding:NSUTF8StringEncoding],
                [[NSString alloc] initWithData:it.value encoding:NSUTF8StringEncoding]);
        }
        // clamped snapshot contents:
        //   - bar: BAR
        //   - baz: BAZ
    }
}

@end
