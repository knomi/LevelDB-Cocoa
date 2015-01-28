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

extension String {
    var UTF8: NSData {
        return dataUsingEncoding(NSUTF8StringEncoding)!
    }
}

extension NSData {
    var UTF8String: String {
        return NSString(data: self, encoding: NSUTF8StringEncoding)!
    }
}

func XCTAssertEqual<A : Equatable>(x: A?, y: A?, _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssert(x == y, "\(x) is not equal to \(y) -- \(message)", file: file, line: line)
}

func XCTAssertEqual<A : Equatable, B : Equatable>(xs: [(A, B)], ys: [(A, B)], _ message: String = "", file: String = __FILE__, line: UInt = __LINE__) {
    XCTAssertEqual(xs.count, ys.count, message, file: file, line: line)
    for (x, y) in Zip2(xs, ys) {
        XCTAssertEqual(x.0, y.0, message, file: file, line: line)
        XCTAssertEqual(x.1, y.1, message, file: file, line: line)
    }
}

class LevelDBTests: XCTestCase {

    var path = ""
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        path = NSTemporaryDirectory().stringByAppendingPathComponent(NSProcessInfo.processInfo().globallyUniqueString)
        
        NSLog("using temp path: %@", path)
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        destroyDatabase(path)
        assert(!NSFileManager.defaultManager().fileExistsAtPath(path))
        super.tearDown()
    }
    
    func testInMemory() {
        let db = ByteDatabase()
        XCTAssertNil(db[NSData()])
        db[NSData()] = NSData()
        XCTAssertNotNil(db[NSData()])
        db[NSData()] = nil
        XCTAssertNil(db[NSData()])
    }
    
    func testOnDisk() {
        let maybeDb = ByteDatabase(path)
        XCTAssertNotNil(maybeDb)
        
        if maybeDb == nil { return }
        let db = maybeDb!
        XCTAssertNil(db[NSData()])
        
        db[NSData()] = NSData()
        XCTAssertNotNil(db[NSData()])
        
        db[NSData()] = nil
        XCTAssertNil(db[NSData()])
    }
    
    func testSnapshot() {
        let db = ByteDatabase(path)!
        for (k, v) in db.snapshot() {
            XCTFail("Expected empty database")
        }
        
        db[NSData()]  = NSData()
        db["a".UTF8]  = "foo".UTF8
        db["b".UTF8]  = "bar".UTF8
        db["ab".UTF8] = "qux".UTF8
        db["1".UTF8]  = "one".UTF8
        
        let snapshot = db.snapshot()
        db["2".UTF8]  = "two".UTF8
        let pairs = Array(snapshot).map {(k, v) -> (String, String) in
            db[k] = k
            return (k.UTF8String, v.UTF8String)
        }

        XCTAssertEqual(pairs, [("",  ""),
                               ("1",  "one"),
                               ("a",  "foo"),
                               ("ab", "qux"),
                               ("b",  "bar")])
        
        let revPairs = Array(snapshot.reverse).map {(k, v) -> (String, String) in
            return (k.UTF8String, v.UTF8String)
        }
        XCTAssertEqual(revPairs, [("b",  "bar"),
                                  ("ab", "qux"),
                                  ("a",  "foo"),
                                  ("1",  "one"),
                                  ("",  "")])
        
        let clampPairs = Array(snapshot["aa".UTF8 ... "c".UTF8]).map {(k, v) -> (String, String) in
            return (k.UTF8String, v.UTF8String)
        }

        XCTAssertEqual(clampPairs, [("ab", "qux"),
                                    ("b",  "bar")])

        let clampRevPairs = Array(snapshot.reverse["1".UTF8 ... "a".UTF8]).map {(k, v) -> (String, String) in
            return (k.UTF8String, v.UTF8String)
        }

        XCTAssertEqual(clampRevPairs, [("a",  "foo"),
                                       ("1",  "one")])

    }
    
    func testStringDatabase() {
    
        let db = Database<String, String>()
        
        db["foo"] = "bar"
        
        XCTAssertEqual(db["foo"], Optional("bar"))

        db["foo"] = nil
    
        XCTAssertNil(db["foo"])

    }
    
    func testPerformanceExample() {
        // This is an example of a performance test case.
        self.measureBlock() {
            // Put the code you want to measure the time of here.
        }
    }
    
}
