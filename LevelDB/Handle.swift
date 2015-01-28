//
//  Handle.swift
//  LevelDB
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

internal final class Handle {
    internal let pointer: COpaquePointer
    private let destroy: COpaquePointer -> ()
    internal init() {
        self.pointer = nil
        self.destroy = {_ in ()}
    }
    internal init(_ pointer: COpaquePointer, _ destroy: COpaquePointer -> ()) {
        self.pointer = pointer
        self.destroy = destroy
    }
    deinit {
        if pointer != nil {
            destroy(pointer)
        }
    }
}
