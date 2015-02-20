//
//  SnapshotTests.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 11.02.2015.
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import XCTest
import LevelDB

extension LevelDBTests {

//    func testSnapshot() {
//        let db = ByteDatabase(path)!
//        for (k, v) in db.snapshot() {
//            XCTFail("Expected empty database")
//        }
//        
//        db[NSData()]  = NSData()
//        db["a".UTF8]  = "foo".UTF8
//        db["b".UTF8]  = "bar".UTF8
//        db["ab".UTF8] = "qux".UTF8
//        db["1".UTF8]  = "one".UTF8
//        
//        let snapshot = db.snapshot()
//        db["2".UTF8]  = "two".UTF8
//        let pairs = Array(snapshot).map {(k, v) -> (String, String) in
//            db[k] = k
//            return (k.UTF8String, v.UTF8String)
//        }
//
//        XCTAssertEqual(pairs, [("",  ""),
//                               ("1",  "one"),
//                               ("a",  "foo"),
//                               ("ab", "qux"),
//                               ("b",  "bar")])
//        
//        if true {
//            XCTAssertEqual(snapshot["".UTF8], "".UTF8)
//            XCTAssertEqual(snapshot["1".UTF8], "one".UTF8)
//            XCTAssertNil(snapshot["2".UTF8])
//        }
//        
//        let revPairs = Array(snapshot.reverse).map {(k, v) -> (String, String) in
//            return (k.UTF8String, v.UTF8String)
//        }
//        XCTAssertEqual(revPairs, [("b",  "bar"),
//                                  ("ab", "qux"),
//                                  ("a",  "foo"),
//                                  ("1",  "one"),
//                                  ("",  "")])
//        
//        let clampPairs = Array(snapshot["aa".UTF8 ..< "c".UTF8]).map {(k, v) -> (String, String) in
//            return (k.UTF8String, v.UTF8String)
//        }
//
//        XCTAssertEqual(clampPairs, [("ab", "qux"),
//                                    ("b",  "bar")])
//
//        let clampRevPairs = Array(snapshot.reverse["1".UTF8 ..< "a ".UTF8]).map {(k, v) -> (String, String) in
//            return (k.UTF8String, v.UTF8String)
//        }
//        println(clampRevPairs)
//        XCTAssertEqual(clampRevPairs, [("a",  "foo"),
//                                       ("1",  "one")])
//
//    }
//
//    func testPrefix() {
//        let db = Database<String, String>(path)!
//        
//        db["/z"]          = "end"
//        db["/people/foo"] = "foo"
//        db["/people/bar"] = "bar"
//        db["/pets/cat"]   = "meow"
//        db["/pets/dog"]   = "barf"
//        db["/other"]      = "other"
//
//        let snapshot = db.snapshot()
//        
//        XCTAssertEqual(snapshot.values.array, ["other", "bar", "foo", "meow", "barf", "end"])
//        
//        let people = snapshot.prefix("/people/")
//        let pets   = snapshot.prefix("/pets/")
//        let peh    = snapshot.prefix("/pe")
//        let dehcat0 = snapshot["/people/deh" ..< "/pets/cat"]
//        let dehcat1 = snapshot["/people/deh" ..< "/pets/cat "]
//        let dehcat2 = snapshot["/people/deh" ... "/pets/cat"]
//        let dehdog  = snapshot["/people/deh" ... "/pets/dog"]
//        let postcat = snapshot.after("/pets/cat")
//        
//        XCTAssertEqual(people.values.array, ["bar", "foo"])
//        XCTAssertEqual(pets.values.array, ["meow", "barf"])
//        XCTAssertEqual(peh.values.array, ["bar", "foo", "meow", "barf"])
//        XCTAssertEqual(dehcat0.values.array, ["foo"])
//        XCTAssertEqual(dehcat1.values.array, ["foo", "meow"])
//        XCTAssertEqual(dehcat2.values.array, ["foo", "meow"])
//        XCTAssertEqual(dehdog.values.array, ["foo", "meow", "barf"])
//        XCTAssertEqual(postcat.values.array, ["barf", "end"])
//        
//    }
//    
//    func testReadOptions() {
//        let db = Database<String, String>(path)!
//        
//        db["foo"] = "FOO"
//        db["bar"] = "BAR"
//        
//        let snapshot = db.snapshot()
//        
//        let foo = snapshot.verifyingChecksums {snap in snap["foo"]}
//        let bar = snapshot.keepingCache {snap in snap["bar"]}
//        let all = snapshot.keepingCache {snap in snap.values.array}
//        XCTAssertEqual(foo, "FOO")
//        XCTAssertEqual(bar, "BAR")
//        XCTAssertEqual(all, ["BAR", "FOO"])
//    }
    
}