//
//  DatabaseTests.swift
//  DatabaseTests
//
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation
import XCTest
import LevelDB

class DatabaseTests : XCTestCase {

    var path = ""
    
    override func setUp() {
        super.setUp()
        path = tempDbPath()
    }
    
    override func tearDown() {
        destroyTempDb(path)
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
        let db: LDBDatabase
        do {
            db = try LDBDatabase(path: path)
        } catch let error as NSError {
            return XCTFail(error.description)
        }
        
        XCTAssertNil(db[NSData()])
        
        db[NSData()] = NSData()
        XCTAssertNotNil(db[NSData()])

        NSLog("approximate size: %u", db.approximateSizesForIntervals([
            LDBInterval(start: NSData(), end: nil)
        ]))
        
        db[NSData()] = nil
        XCTAssertNil(db[NSData()])
    }
    
    func testOptions() {
        var log: [String] = []
        defer {
            NSLog("log: %@", log.description)
        }
        let options = LDBDatabase.options(
            createIfMissing: true,
            errorIfExists: false,
            paranoidChecks: true,
            infoLog: {log.append($0)},
            writeBufferSize: 64 << 10,
            maxOpenFiles: 100,
            cacheCapacity: 4 << 20,
            blockSize: 2048,
            blockRestartInterval: 8,
            compression: .SnappyCompression,
            reuseLogs: true,
            bloomFilterBits: 16)
        let rawDb: LDBDatabase
        do {
            rawDb = try LDBDatabase(path: path, options: options)
        } catch let error as NSError {
            return XCTFail(error.description)
        }
        let db = Database<String, String>(rawDb)
        db["x"] = "X"
        NSLog("contents at 'x': %@", db["x"]?.debugDescription ?? "nil")
        rawDb.pruneCache()
        XCTAssertEqual(db["x"], "X")
    }
    
    func testStringDatabase() {
    
        let db = Database<String, String>()
        
        db["foo"] = "bar"
        
        let rawDb = db.raw

        XCTAssertEqual(db["foo"],         Optional("bar"))
        XCTAssertEqual(rawDb["foo".UTF8], Optional("bar".UTF8))

        db["foo"] = nil
    
        XCTAssertNil(db["foo"])

    }
    
    func testWriteBatch() {
    
        let batch = WriteBatch<String, String>()
        
        batch["foo"] = "bar"
        batch["foo"] = nil
        
        AssertEqual(batch.diff, [("foo", nil)])

        batch["qux"] = "abcd"
        batch["def"] = nil
        batch["bar"] = nil
        batch["foo"] = "def"

        AssertEqual(batch.diff, [("bar", nil),
                                 ("def", nil),
                                 ("foo", "def"),
                                 ("qux", "abcd")])
    
        let db1 = Database<String, String>()
        
        db1["bar"] = "ghi"
        db1["baz"] = "jkl"
        
        XCTAssertEqual(db1["bar"], "ghi")
        XCTAssertEqual(db1["baz"], "jkl")
        
        do {
            try db1.write(batch, sync: false)
        } catch let e as NSError {
            XCTFail(e.description)
        }
        
        XCTAssertEqual(db1["bar"], nil)
        XCTAssertEqual(db1["baz"], "jkl")
        XCTAssertEqual(db1["def"], nil)
        XCTAssertEqual(db1["foo"], "def")
        XCTAssertEqual(db1["qux"], "abcd")

        let db2 = try! Database<String, String>(path: path)
        
        db2["def"] = "ghi"
        db2["baz"] = "jkl"
        
        XCTAssertEqual(db2["def"], "ghi")
        XCTAssertEqual(db2["baz"], "jkl")
        
        do {
            try db2.write(batch, sync: false)
        } catch let e as NSError {
            XCTFail(e.description)
        }
        
        XCTAssertEqual(db2["bar"], nil)
        XCTAssertEqual(db2["baz"], "jkl")
        XCTAssertEqual(db2["def"], nil)
        XCTAssertEqual(db2["foo"], "def")
        XCTAssertEqual(db2["qux"], "abcd")
        
    }
    
    func testOpenFailures() {
        do {
            let _ = try LDBDatabase(path: path, options: LDBDatabase.options(createIfMissing: false))
            XCTFail("should fail with `createIfMissing: false`")
        } catch {}
        do {
            let _ = try LDBDatabase(path: path, options: LDBDatabase.options(createIfMissing: true))
        } catch {
            XCTFail("should succeed with `createIfMissing: true`")
        }
        do {
            let _ = try LDBDatabase(path: path, options: LDBDatabase.options(errorIfExists: true))
            XCTFail("should fail with `errorIfExists: true`")
        } catch {}
    }
    
    func testFilterPolicyOption() {
        let db: LDBDatabase
        do {
            db = try LDBDatabase(path: path, options: LDBDatabase.options(
                createIfMissing: true,
                bloomFilterBits: 10))
        } catch let error as NSError {
            return XCTFail("Database.open failed with error: \(error)")
        }
        
        db["foo".UTF8] = "bar".UTF8
        
        XCTAssertEqual(db["foo".UTF8], "bar".UTF8)
    }
    
    func testCacheOption() {
        let db: LDBDatabase
        do {
            db = try LDBDatabase(path: path, options: LDBDatabase.options(
                createIfMissing: true,
                cacheCapacity: 2 << 20))
        } catch let error as NSError {
            return XCTFail("Database.open failed with error: \(error)")
        }
        
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
