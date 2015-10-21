//
//  LevelDBObjCTests.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import XCTest
import Foundation
import LevelDB

extension NSData {
    var utf8String: String? {
        return NSString(data: self, encoding: NSUTF8StringEncoding) as String?
    }
}

extension String {
    var utf8Data: NSData {
        return dataUsingEncoding(NSUTF8StringEncoding)!
    }
}

class LevelDBObjCTests: XCTestCase {

    var path = ""
    
    override func setUp() {
        super.setUp()
        path = tempDbPath()
    }
    
    override func tearDown() {
        destroyTempDb(path)
        super.tearDown()
    }
    
    func useDatabase(db: LDBDatabase) {
        if true {
            db["a".utf8Data] = "A".utf8Data
        
            let snap = db.snapshot()

            XCTAssertEqual(db["a".utf8Data], "A".utf8Data)
            XCTAssertEqual(snap["a".utf8Data]?.utf8String, "A")
            XCTAssertEqual(Array(snap.keys.map{$0.utf8String!}), ["a"])
            XCTAssertEqual(Array(snap.values.map{$0.utf8String!}), ["A"])
        }
        
        if true {
            db["".utf8Data] = "".utf8Data
            db["b".utf8Data] = "B".utf8Data
            db["c".utf8Data] = "C".utf8Data
            db["z".utf8Data] = "Z".utf8Data
            db["zzz".utf8Data] = "ZZZ".utf8Data
            
            let snap = db.snapshot()
            
            XCTAssertEqual(Array(snap.keys.map{$0.utf8String!}), ["", "a", "b", "c", "z", "zzz"])
            XCTAssertEqual(Array(snap.values.map{$0.utf8String!}), ["", "A", "B", "C", "Z", "ZZZ"])
        }
        
        if true {
            let snap = db.snapshot().reversed
            
            XCTAssertEqual(Array(snap.keys.map{$0.utf8String!}), ["zzz", "z", "c", "b", "a", ""])
            XCTAssertEqual(Array(snap.values.map{$0.utf8String!}), ["ZZZ", "Z", "C", "B", "A", ""])
        }
        
        if true {
            let snap = db.snapshot().clampStart("a".utf8Data, end: "c!".utf8Data)
            
            XCTAssertEqual(Array(snap.keys.map{$0.utf8String!}), ["a", "b", "c"])
            XCTAssertEqual(Array(snap.values.map{$0.utf8String!}), ["A", "B", "C"])
        }
        
        if true {
            let snap = db.snapshot().clampStart(NSData(), end: "c".utf8Data)
            
            XCTAssertEqual(Array(snap.keys.map{$0.utf8String!}), ["", "a", "b"])
            XCTAssertEqual(Array(snap.values.map{$0.utf8String!}), ["", "A", "B"])
        }
        
        if true {
            let snap = db.snapshot().after("a".utf8Data).clampStart(NSData(), end: "zz".utf8Data)
            
            XCTAssertEqual(Array(snap.keys.map{$0.utf8String!}), ["b", "c", "z"])
            XCTAssertEqual(Array(snap.values.map{$0.utf8String!}), ["B", "C", "Z"])
        }
        
        if true {
            let snap = db.snapshot().prefixed("z".utf8Data)
            
            XCTAssertEqual(Array(snap.keys.map{$0.utf8String!}), ["", "zz"])
            XCTAssertEqual(Array(snap.values.map{$0.utf8String!}), ["Z", "ZZZ"])
        }
        
        if true {
            let snap = db.snapshot().prefixed("z".utf8Data).reversed
            
            XCTAssertEqual(Array(snap.keys.map{$0.utf8String!}), ["zz", ""])
            XCTAssertEqual(Array(snap.values.map{$0.utf8String!}), ["ZZZ", "Z"])
        }
        
        if true {
            db["a".utf8Data] = nil
        
            let snap = db.snapshot()

            XCTAssertEqual(Array(snap.keys.map{$0.utf8String!}), ["", "b", "c", "z", "zzz"])
            XCTAssertEqual(Array(snap.values.map{$0.utf8String!}), ["", "B", "C", "Z", "ZZZ"])
        }
        
        if true {
            let batch = LDBWriteBatch()
            batch["b".utf8Data] = nil
            batch["".utf8Data] = "empty".utf8Data
            batch["c".utf8Data] = "!".utf8Data
            batch["a".utf8Data] = "?".utf8Data
            batch["c".utf8Data] = nil
            
            let root = batch.prefixed("/".utf8Data)
            root[".".utf8Data] = "..".utf8Data
            root["a".utf8Data] = "A".utf8Data
            
            let ahs = root.prefixed("a/".utf8Data)
            ahs["a".utf8Data] = "aa".utf8Data
            ahs["b".utf8Data] = "bb".utf8Data
            
            do {
                try db.write(batch, sync: false)
            } catch let error as NSError {
                XCTFail(error.description)
            }

            let snap = db.snapshot()
            
            XCTAssertEqual(Array(snap.keys.map{$0.utf8String!}),   ["",      "/.", "/a", "/a/a", "/a/b", "a", "z", "zzz"])
            XCTAssertEqual(Array(snap.values.map{$0.utf8String!}), ["empty", "..", "A",  "aa",   "bb",   "?", "Z", "ZZZ"])
        }
        
    }

    func testInMemory() {
        let db = LDBDatabase()
        useDatabase(db)
    }

    func testOnDisk() {
        var logMessages = [String]()
        let db: LDBDatabase
        do {
            db = try LDBDatabase(path: path, options: LDBDatabase.options(
                createIfMissing: true,
                infoLog: { message in logMessages.append(message) }))
        } catch let error as NSError {
            return XCTFail(error.description)
        }
        useDatabase(db)
        NSLog("LevelDB log contents:\n%@",
            logMessages.map {m in ">>> \(m)"}.joinWithSeparator("\n"))
    }

}
