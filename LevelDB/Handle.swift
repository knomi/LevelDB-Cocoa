//
//  Handle.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 27.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

internal final class Handle {
    internal let pointer: COpaquePointer
    internal let destroy: COpaquePointer -> ()
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
