//
//  ByteInterval.swift
//  LevelDB
//
//  Created by Pyry Jahkola on 28.01.2015.
//  Copyright (c) 2015 Pyrtsa. All rights reserved.
//

import Foundation

public typealias CappedData = AddBounds<NSData>
public typealias ByteInterval = RealInterval<CappedData>

/// TODO
public func nextAfter(data: CappedData) -> CappedData {
    switch data {
    case .MinBound:
        return .NoBound(NSData())
    case let .NoBound(x):
        let copy = x.mutableCopy() as NSMutableData
        let bytes = UnsafeMutableBufferPointer<UInt8>(start: UnsafeMutablePointer<UInt8>(copy.mutableBytes), count: copy.length)
        for i in reverse(indices(bytes)) {
            if bytes[i] < UInt8.max {
                bytes[i]++
                for j in i + 1 ..< bytes.count {
                    bytes[j] = 0
                }
                return .NoBound(copy.copy() as NSData)
            }
        }
        return .MaxBound
    case let .MaxBound:
        return .MaxBound
    }
}

/// TODO
public func asHalfOpen(interval: ByteInterval) -> HalfOpenInterval<CappedData> {
    let start = interval.closedStart ? interval.start : nextAfter(interval.start)
    let end   = !interval.closedEnd  ? interval.end   : nextAfter(interval.end)
    return start ..< end
}
