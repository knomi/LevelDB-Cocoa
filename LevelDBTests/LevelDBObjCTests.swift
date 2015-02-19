//
//  LevelDBObjCTests.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 19.02.2015.
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

extension LDBIterator : GeneratorType {
    public typealias Element = (NSData, NSData)
    public func next() -> Element? {
        if let k = key {
            if let v = value {
                self.step()
                return (k, v)
            }
        }
        return nil
    }
}

extension LDBSnapshot : SequenceType {
    public typealias Generator = LDBIterator
    public func generate() -> Generator {
        return iterate()
    }
    
    var keys: LazySequence<MapSequenceView<LDBSnapshot, NSData>> {
        return lazy(self).map {k, _ in k}
    }

    var vals: LazySequence<MapSequenceView<LDBSnapshot, NSData>> {
        return lazy(self).map {_, v in v}
    }
}

class LevelDBObjCTests: XCTestCase {

    func testExample() {
        let db = LDBDatabase()
        
        if true {
            db["a".utf8Data] = "A".utf8Data
        
            let snap = db.snapshot()

            XCTAssertEqual(db["a".utf8Data], "A".utf8Data)
            XCTAssertEqual(snap["a".utf8Data].utf8String!, "A")
            XCTAssertEqual(snap.keys.map{$0.utf8String!}.array, ["a"])
            XCTAssertEqual(snap.vals.map{$0.utf8String!}.array, ["A"])
        }
        
        if true {
            db["".utf8Data] = "".utf8Data
            db["b".utf8Data] = "B".utf8Data
            db["c".utf8Data] = "C".utf8Data
            db["z".utf8Data] = "Z".utf8Data
            db["zzz".utf8Data] = "ZZZ".utf8Data
            
            let snap = db.snapshot()
            
            XCTAssertEqual(snap.keys.map{$0.utf8String!}.array, ["", "a", "b", "c", "z", "zzz"])
            XCTAssertEqual(snap.vals.map{$0.utf8String!}.array, ["", "A", "B", "C", "Z", "ZZZ"])
        }
        
        if true {
            let snap = db.snapshot().reversed
            
            XCTAssertEqual(snap.keys.map{$0.utf8String!}.array, ["zzz", "z", "c", "b", "a", ""])
            XCTAssertEqual(snap.vals.map{$0.utf8String!}.array, ["ZZZ", "Z", "C", "B", "A", ""])
        }
        
        if true {
            let snap = db.snapshot().clampStart("a".utf8Data, end: "c!".utf8Data)
            
            XCTAssertEqual(snap.keys.map{$0.utf8String!}.array, ["a", "b", "c"])
            XCTAssertEqual(snap.vals.map{$0.utf8String!}.array, ["A", "B", "C"])
        }
        
        if true {
            let snap = db.snapshot().clampStart(NSData(), end: "c".utf8Data)
            
            XCTAssertEqual(snap.keys.map{$0.utf8String!}.array, ["", "a", "b"])
            XCTAssertEqual(snap.vals.map{$0.utf8String!}.array, ["", "A", "B"])
        }
        
        if true {
            let snap = db.snapshot().after("a".utf8Data).clampStart(NSData(), end: "zz".utf8Data)
            
            XCTAssertEqual(snap.keys.map{$0.utf8String!}.array, ["b", "c", "z"])
            XCTAssertEqual(snap.vals.map{$0.utf8String!}.array, ["B", "C", "Z"])
        }
        
        if true {
            let snap = db.snapshot().prefix("z".utf8Data)
            
            XCTAssertEqual(snap.keys.map{$0.utf8String!}.array, ["z", "zzz"])
            XCTAssertEqual(snap.vals.map{$0.utf8String!}.array, ["Z", "ZZZ"])
        }
        
        if true {
            let snap = db.snapshot().prefix("z".utf8Data).reversed
            
            XCTAssertEqual(snap.keys.map{$0.utf8String!}.array, ["zzz", "z"])
            XCTAssertEqual(snap.vals.map{$0.utf8String!}.array, ["ZZZ", "Z"])
        }
        
        if true {
            db["a".utf8Data] = nil
        
            let snap = db.snapshot()

            XCTAssertEqual(snap.keys.map{$0.utf8String!}.array, ["", "b", "c", "z", "zzz"])
            XCTAssertEqual(snap.vals.map{$0.utf8String!}.array, ["", "B", "C", "Z", "ZZZ"])
        }
        
        if true {
            let batch = LDBWriteBatch()
            batch["b".utf8Data] = nil
            batch["".utf8Data] = "empty".utf8Data
            batch["c".utf8Data] = "!".utf8Data
            batch["a".utf8Data] = "?".utf8Data
            batch["c".utf8Data] = nil
            var error: NSError?
            let ok = db.write(batch, sync: false, error: &error)

            let snap = db.snapshot()
            
            XCTAssert(ok, "\(error?.description)")
            XCTAssertEqual(snap.keys.map{$0.utf8String!}.array, ["",      "a", "z", "zzz"])
            XCTAssertEqual(snap.vals.map{$0.utf8String!}.array, ["empty", "?", "Z", "ZZZ"])
        }
        
    }

}
