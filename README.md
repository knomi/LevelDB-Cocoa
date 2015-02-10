LevelDB.swift
=============

LevelDB.swift is a simple but non-straightforward wrapper around the [LevelDB][] key-value storage library written at Google.

The base building block is a `Database<Key, Value>` of serialisable key-value pairs ordered by the serialised representation of `Key`. The database can be either in-memory or persisted on disk, and snapshots are used to make reads consistent.

Quick example:

```swift
import LevelDB
if let db = Database<String, String>("strings.ldb") {
    db.write
}

[LevelDB]: https://github.com/google/leveldb
