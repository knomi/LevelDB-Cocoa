//
//  SnapshotTests.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import XCTest
import LevelDB

class SnapshotTests : XCTestCase {

    var path = ""
    
    override func setUp() {
        super.setUp()
        path = tempDbPath()
    }
    
    override func tearDown() {
        destroyTempDb(path)
        super.tearDown()
    }
    
    func testSnapshot() {
        let db: LDBDatabase
        do {
            db = try LDBDatabase(path: path)
        } catch let error as NSError {
            return XCTFail(error.description)
        }
        for (k, v) in db.snapshot() {
            XCTFail("Expected empty database, found \(k): \(v)")
        }
        
        db[Data()]  = Data()
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

        AssertEqual(pairs, [("",  ""),
                            ("1",  "one"),
                            ("a",  "foo"),
                            ("ab", "qux"),
                            ("b",  "bar")])
        
        if true {
            XCTAssertEqual(snapshot["".UTF8], "".UTF8)
            XCTAssertEqual(snapshot["1".UTF8], "one".UTF8)
            XCTAssertNil(snapshot["2".UTF8])
        }
        
        let revPairs = Array(snapshot.reversed).map {(k, v) -> (String, String) in
            return (k.UTF8String, v.UTF8String)
        }
        AssertEqual(revPairs, [("b",  "bar"),
                               ("ab", "qux"),
                               ("a",  "foo"),
                               ("1",  "one"),
                               ("",  "")])
        
        let clampPairs = Array(snapshot.clampFrom("aa".UTF8, to: "c".UTF8)).map {
            (k, v) -> (String, String) in
            return (k.UTF8String, v.UTF8String)
        }

        AssertEqual(clampPairs, [("ab", "qux"),
                                 ("b",  "bar")])

        let clampRevPairs = Array(snapshot.reversed.clampFrom("1".UTF8, to: "a ".UTF8)).map {
            (k, v) -> (String, String) in
            return (k.UTF8String, v.UTF8String)
        }
        NSLog("%@", clampRevPairs.description)
        AssertEqual(clampRevPairs, [("a",  "foo"),
                                    ("1",  "one")])

    }

    func testPrefix() {
        let db: Database<String, String>
        do {
            db = try Database<String, String>(path: path)
        } catch let error as NSError {
            return XCTFail(error.description)
        }
        
        db["/z"]          = "End"
        db["/people/foo"] = "Foo"
        db["/people/bar"] = "Bar"
        db["/pets/cat"]   = "Meow"
        db["/pets/dog"]   = "Barf"
        db["/other"]      = "Other"

        let snapshot = db.snapshot()
        
        XCTAssertEqual(Array(snapshot.values), ["Other", "Bar", "Foo", "Meow", "Barf", "End"])
        
        let bardogs = snapshot["/people/bar" ... "/pets/dog"]
        
        XCTAssertEqual(Array(bardogs.values), ["Bar", "Foo", "Meow", "Barf"])
        XCTAssertEqual(bardogs.raw.start,              "/people/bar".utf8Data)
        XCTAssertEqual(bardogs.prefixed("/pe").raw.start, "ople/bar".utf8Data)
        XCTAssertEqual(bardogs.prefixed("/people").raw.start, "/bar".utf8Data)
        XCTAssertEqual(bardogs.prefixed("/people/bar").raw.start, "".utf8Data)
        XCTAssertEqual(bardogs.prefixed("/people/bart").raw.start, "".utf8Data)
        XCTAssertEqual(bardogs.prefixed("/pets").raw.start,        "".utf8Data)
        XCTAssertEqual(bardogs.raw.end,                 ("/pets/dog".utf8Data as NSData).ldb_lexicographicalFirstChild())
        XCTAssertEqual(bardogs.prefixed("/pets").raw.end,    ("/dog".utf8Data as NSData).ldb_lexicographicalFirstChild())
        XCTAssertEqual(bardogs.prefixed("/people").raw.end,        nil)
        
        let people = snapshot.prefixed("/people/")
        let pets   = snapshot.prefixed("/pets/")
        let peh    = snapshot.prefixed("/pe")

        XCTAssertEqual(Array(people.keys), ["bar", "foo"])
        XCTAssertEqual(Array(pets.keys), ["cat", "dog"])
        XCTAssertEqual(Array(peh.keys), ["ople/bar", "ople/foo", "ts/cat", "ts/dog"])

        XCTAssertEqual(Array(people.values), ["Bar", "Foo"])
        XCTAssertEqual(Array(pets.values), ["Meow", "Barf"])
        XCTAssertEqual(Array(peh.values), ["Bar", "Foo", "Meow", "Barf"])
        
        XCTAssertEqual(Array(peh.clampFrom("ople/e", to: "ts/d").values), ["Foo", "Meow"])
        XCTAssertEqual(Array(peh.reversed.clampFrom("ople/e", to: "ts/d").values), ["Meow", "Foo"])
        
        let dehcat0 = snapshot["/people/deh" ..< "/pets/cat"]
        let dehcat1 = snapshot["/people/deh" ..< "/pets/cat "]
        let dehcat2 = snapshot["/people/deh" ... "/pets/cat"]
        let dehdog  = snapshot["/people/deh" ... "/pets/dog"]
        let postcat = snapshot.clampAfter("/pets/cat", to: nil)
        
        XCTAssertEqual(Array(dehcat0.values), ["Foo"])
        XCTAssertEqual(Array(dehcat1.values), ["Foo", "Meow"])
        XCTAssertEqual(Array(dehcat2.values), ["Foo", "Meow"])
        XCTAssertEqual(Array(dehdog.values), ["Foo", "Meow", "Barf"])
        XCTAssertEqual(Array(postcat.values), ["Barf", "End"])
        
    }
    
    func testClamping() {
        let db: Database<String, String>
        do {
            db = try Database<String, String>(path: path)
        } catch let error as NSError {
            return XCTFail(error.description)
        }
        let keys = (0 ..< 100).map {i in "\(i / 10)\(i % 10)"}
        let batch = WriteBatch<String, String>()
        for k in keys {
            batch[k] = ""
        }
        do {
            try db.write(batch, sync: false)
        } catch let error as NSError {
            XCTFail(error.description)
        }
        
        let snap = db.snapshot()

        XCTAssertEqual(Array(snap.keys),                                   keys)
        
        XCTAssertEqual(snap["20" ..< "33"]["10" ..< "15"].raw.start, "20".utf8Data)
        XCTAssertEqual(snap["20" ..< "33"]["10" ..< "15"].raw.end,   "20".utf8Data)
        XCTAssertEqual(snap["20" ..< "33"].raw.start,                "20".utf8Data)
        XCTAssertEqual(snap["20" ..< "33"].raw.end,                  "33".utf8Data)
        XCTAssertEqual(snap["20" ..< "33"]["40" ..< "45"].raw.start, "33".utf8Data)
        XCTAssertEqual(snap["20" ..< "33"]["40" ..< "45"].raw.end,   "33".utf8Data)

        XCTAssertEqual(Array(snap["20" ..< "33"].keys),                    Array(keys[20 ..< 33]))
        XCTAssertEqual(Array(snap["10" ... "20"].keys),                    Array(keys[10 ... 20]))

        XCTAssertEqual(Array(snap.clampTo(      "3"  ).keys),             Array(keys[ 0 ... 29]))
        XCTAssertEqual(Array(snap.clampTo(      "31" ).keys),             Array(keys[ 0 ... 30]))
        XCTAssertEqual(Array(snap.clampThrough( "3"  ).keys),             Array(keys[ 0 ... 29]))
        XCTAssertEqual(Array(snap.clampThrough( "31" ).keys),             Array(keys[ 0 ... 31]))
        XCTAssertEqual(Array(snap.clampFrom(    "31" ).keys),             Array(keys[31 ... 99]))
        XCTAssertEqual(Array(snap.clampFrom(    "311").keys),             Array(keys[32 ... 99]))
        XCTAssertEqual(Array(snap.clampAfter(   "5"  ).keys),             Array(keys[50 ... 99]))
        XCTAssertEqual(Array(snap.clampAfter(   "50" ).keys),             Array(keys[51 ... 99]))

        XCTAssertEqual(Array(snap.clampFrom(  "50", to:      "55").keys), Array(keys[50 ... 54]))
        XCTAssertEqual(Array(snap.clampFrom(  "50", through: "55").keys), Array(keys[50 ... 55]))
        XCTAssertEqual(Array(snap.clampAfter( "50", to:      "55").keys), Array(keys[51 ... 54]))
        XCTAssertEqual(Array(snap.clampAfter( "50", through: "55").keys), Array(keys[51 ... 55]))

        XCTAssertEqual(Array(snap.clampFrom(   "" , to:      "55").keys), Array(keys[ 0 ... 54]))
        XCTAssertEqual(Array(snap.clampFrom(   "" , through: "55").keys), Array(keys[ 0 ... 55]))
        XCTAssertEqual(Array(snap.clampAfter(  "" , to:      "55").keys), Array(keys[ 0 ... 54]))
        XCTAssertEqual(Array(snap.clampAfter(  "" , through: "55").keys), Array(keys[ 0 ... 55]))

        XCTAssertEqual(Array(snap.clampFrom(  "50", to:       nil).keys), Array(keys[50 ... 99]))
        XCTAssertEqual(Array(snap.clampFrom(  "50", through:  nil).keys), Array(keys[50 ... 99]))
        XCTAssertEqual(Array(snap.clampAfter( "50", to:       nil).keys), Array(keys[51 ... 99]))
        XCTAssertEqual(Array(snap.clampAfter( "50", through:  nil).keys), Array(keys[51 ... 99]))

        XCTAssertEqual(Array(snap.clampFrom(   "" , to:       nil).keys), keys)
        XCTAssertEqual(Array(snap.clampFrom(   "" , through:  nil).keys), keys)
        XCTAssertEqual(Array(snap.clampAfter(  "" , to:       nil).keys), keys)
        XCTAssertEqual(Array(snap.clampAfter(  "" , through:  nil).keys), keys)
    }
    
    func testRounding() {
        let db: Database<String, String>
        do {
            db = try Database<String, String>(path: path)
        } catch let error as NSError {
            return XCTFail(error.description)
        }
        let keys = (0 ..< 100).map {i in "\(i / 10)\(i % 10)"}
        let batch = WriteBatch<String, String>()
        for k in keys {
            batch[k] = ""
        }
        do {
            try db.write(batch, sync: false)
        } catch let error as NSError {
            XCTFail(error.description)
        }
        
        let snap = db.snapshot()
        
        XCTAssertEqual(snap.raw.floorKey("0".utf8Data),   "".utf8Data)
        XCTAssertEqual(snap.raw.floorKey("00".utf8Data),  "00".utf8Data)
        XCTAssertEqual(snap.raw.floorKey("3".utf8Data),   "29".utf8Data)
        XCTAssertEqual(snap.raw.floorKey("30".utf8Data),  "30".utf8Data)
        XCTAssertEqual(snap.raw.floorKey("300".utf8Data), "30".utf8Data)
        XCTAssertEqual(snap.raw.floorKey("31a".utf8Data), "31".utf8Data)
        XCTAssertEqual(snap.raw.floorKey("99".utf8Data),  "99".utf8Data)
        XCTAssertEqual(snap.raw.floorKey(nil),            "99".utf8Data)

        XCTAssertEqual(snap.raw.ceilKey("".utf8Data),    "00".utf8Data)
        XCTAssertEqual(snap.raw.ceilKey("0".utf8Data),   "00".utf8Data)
        XCTAssertEqual(snap.raw.ceilKey("00".utf8Data),  "00".utf8Data)
        XCTAssertEqual(snap.raw.ceilKey("000".utf8Data), "01".utf8Data)
        XCTAssertEqual(snap.raw.ceilKey("30".utf8Data),  "30".utf8Data)
        XCTAssertEqual(snap.raw.ceilKey("300".utf8Data), "31".utf8Data)
        XCTAssertEqual(snap.raw.ceilKey("31a".utf8Data), "32".utf8Data)
        XCTAssertEqual(snap.raw.ceilKey("99".utf8Data),  "99".utf8Data)
        XCTAssertEqual(snap.raw.ceilKey("999".utf8Data), nil)
        XCTAssertEqual(snap.raw.ceilKey(nil),            nil)
    }
    
    func testReadOptions() {
        let db: Database<String, String>
        do {
            db = try Database<String, String>(path: path)
        } catch let error as NSError {
            return XCTFail(error.description)
        }
        
        db["foo"] = "FOO"
        db["bar"] = "BAR"
        
        let snapshot = db.snapshot()
        
        let foo = snapshot.checksummed["foo"]
        let bar = snapshot.noncaching["bar"]
        let all = Array(snapshot.noncaching.values)
        XCTAssertEqual(foo, "FOO")
        XCTAssertEqual(bar, "BAR")
        XCTAssertEqual(all, ["BAR", "FOO"])
    }
    
}
