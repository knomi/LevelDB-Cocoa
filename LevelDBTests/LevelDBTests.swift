//
//  LevelDBTests.swift
//  LevelDBTests
//
//  Created by Pyry Jahkola on 26.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation
import XCTest
import LevelDB

class LevelDBTests: XCTestCase {

    var path = ""
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        path = NSTemporaryDirectory().stringByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
        // NSLog("using temp path: %@", path)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        LDBDatabase.destroyDatabaseAtPath(path, error: nil)
        assert(!NSFileManager.defaultManager().fileExistsAtPath(path))
        super.tearDown()
    }
    
    func testInMemory() {
        let db: LDBDatabase = LDBDatabase()
        XCTAssertNil(db[NSData()])
        db[NSData()] = NSData()
        XCTAssertNotNil(db[NSData()])
        db[NSData()] = nil
        XCTAssertNil(db[NSData()])
    }
    
    func testOnDisk() {
        let maybeDb: LDBDatabase? = LDBDatabase(path)
        XCTAssertNotNil(maybeDb)
        
        if maybeDb == nil { return }
        let db = maybeDb!
        XCTAssertNil(db[NSData()])
        
        db[NSData()] = NSData()
        XCTAssertNotNil(db[NSData()])
        
        db[NSData()] = nil
        XCTAssertNil(db[NSData()])
    }
    
//    func testStringDatabase() {
//    
//        let db = Database<String, String>()
//        
//        db["foo"] = "bar"
//        
//        let byteValued = db.cast() as Database<String, NSData>
//        let byteKeyed = db.cast() as Database<NSData, String>
//        let byteDb = db.cast() as Database<NSData, NSData>
//
//        XCTAssertEqual(db["foo"],             Optional("bar"))
//        XCTAssertEqual(byteValued["foo"],     Optional("bar".UTF8))
//        XCTAssertEqual(byteKeyed["foo".UTF8], Optional("bar"))
//        XCTAssertEqual(byteDb["foo".UTF8],    Optional("bar".UTF8))
//
//        db["foo"] = nil
//    
//        XCTAssertNil(db["foo"])
//
//    }
//    
//    func testWriteBatch() {
//    
//        let batch = WriteBatch<String, String>()
//        
//        batch.put("foo", "bar")
//        batch.delete("foo")
//        
//        XCTAssertEqual(batch.diff, [("foo", nil)])
//
//        batch.put("qux", "abc")
//        batch.delete("def")
//        batch.delete("bar")
//        batch.put("foo", "def")
//
//        XCTAssertEqual(batch.diff, [("bar", nil),
//                                    ("def", nil),
//                                    ("foo", "def"),
//                                    ("qux", "abc")])
//    
//        let db1 = Database<String, String>()
//        
//        db1["bar"] = "ghi"
//        db1["baz"] = "jkl"
//        
//        XCTAssertEqual(db1["bar"], "ghi")
//        XCTAssertEqual(db1["baz"], "jkl")
//        
//        XCTAssertNil(db1.write(batch).error)
//        
//        XCTAssertEqual(db1["bar"], nil)
//        XCTAssertEqual(db1["baz"], "jkl")
//        XCTAssertEqual(db1["def"], nil)
//        XCTAssertEqual(db1["foo"], "def")
//        XCTAssertEqual(db1["qux"], "abc")
//
//        let db2 = Database<String, String>(path)!
//        
//        db2["def"] = "ghi"
//        db2["baz"] = "jkl"
//        
//        XCTAssertEqual(db2["def"], "ghi")
//        XCTAssertEqual(db2["baz"], "jkl")
//        
//        XCTAssertNil(db2.write(batch).error)
//        
//        XCTAssertEqual(db2["bar"], nil)
//        XCTAssertEqual(db2["baz"], "jkl")
//        XCTAssertEqual(db2["def"], nil)
//        XCTAssertEqual(db2["foo"], "def")
//        XCTAssertEqual(db2["qux"], "abc")
//        
//    }
    
    func testOpenFailures() {
//        XCTAssertNotNil(Database<String, String>.open(path).error, "should fail with `createIfMissing: false`")
//        XCTAssertNotNil(Database<String, String>.open(path, createIfMissing: true).value, "should succeed with `createIfMissing: true`")
//        XCTAssertNotNil(Database<String, String>.open(path, errorIfExists: true).error, "should fail with `errorIfExists: true`")

        if true {
            var error: NSError?
            XCTAssertNil(LDBDatabase(path: path, error: &error))
            XCTAssertNotNil(error, "should fail with `createIfMissing: false`")
        }
        if true {
            var error: NSError?
            XCTAssertNotNil(LDBDatabase(path: path, error: &error, createIfMissing: true))
            XCTAssertNil(error, "should succeed with `createIfMissing: true`")
        }
        if true {
            var error: NSError?
            XCTAssertNil(LDBDatabase(path: path, error: &error, errorIfExists: true))
            XCTAssertNotNil(error, "should fail with `errorIfExists: true`")
        }
    }
    
    func testFilterPolicyOption() {
        var error: NSError?
        let maybeDb = LDBDatabase(path: path, error: &error,
            createIfMissing: true,
            bloomFilterBits: 10)
        if let error = error {
            XCTFail("Database.open failed with error: \(error)")
            return
        }
        let db = maybeDb!
        
        db["foo".UTF8] = "bar".UTF8
        
        XCTAssertEqual(db["foo".UTF8], "bar".UTF8)
    }
    
    func testCacheOption() {
        var error: NSError?
        let maybeDb = LDBDatabase(path: path, error: &error,
            createIfMissing: true,
            cacheCapacity: 2 << 20)
        if let error = error {
            XCTFail("Database.open failed with error: \(error)")
            return
        }
        let db = maybeDb!
        
        db["foo".UTF8] = "bar".UTF8
        
        XCTAssertEqual(db["foo".UTF8], "bar".UTF8)
    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
