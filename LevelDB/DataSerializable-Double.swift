//
//  DataSerializable-Double.swift
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

extension Double : DataSerializable {
    public static func fromSerializedData(_ data: Data) -> Double? {
        return OrderPreservingValue.fromSerializedData(data).map {value in
            Double(orderPreservingValue: value)
        }
    }

    public var serializedData: Data {
        return orderPreservingValue.serializedData as Data
    }
}

extension Double {
    public typealias OrderPreservingValue = UInt64

    public init(orderPreservingValue value: UInt64) {
        typealias U = UInt64
        let zeroValue: U = ~(~0 / 2) // = 0b1000...000
        let isNegative = value < zeroValue
        let sign = isNegative ? -1.0 : 1.0
        let bits = isNegative ? zeroValue - value
                              : value - zeroValue
        let expBits = (bits >> U(Double.significandBitCount))
        let mantBits = bits & ~(U.max << U(Double.significandBitCount))
        if expBits == 0 {
            self = sign * Double.leastNonzeroMagnitude * Double(mantBits)
        } else if expBits < 2047 {
            self = sign * (1 + Double.ulpOfOne * Double(mantBits)) * pow(2.0, Double(expBits) - 1023)
        } else if mantBits == 0 {
            self = sign * Double.infinity
        } else {
            self = Double.nan
        }
    }

    public var orderPreservingValue: UInt64 {
        typealias U = UInt64
        let zeroValue: U = ~(~0 / 2) // = 0b1000...000
        let isNegative = self.sign == .minus
        let fixSign: (U) -> U = {u in isNegative ? ~u + 1 : u}
        if isNaN {
            return U.max
        } else if !isFinite {
            return fixSign(U.max << U(Double.significandBitCount))
        } else {
            var exponent32: Int32 = 0
            let significand = frexp(abs(self), &exponent32)
            let exponent = Int(exponent32)
            let expo = exponent - Double.leastNormalMagnitude.exponent
            if significand == 0 {
                return fixSign(zeroValue)
            } else if expo < 1 {
                let mant = U(scalbln(significand, Int(Double.significandBitCount + expo)))
                return fixSign(zeroValue | mant)
            } else {
                let mant = U(scalbln(significand - 0.5, Int(Double.significandBitCount + 1)))
                return fixSign(zeroValue | mant | U(expo) << U(Double.significandBitCount))
            }
        }
    }
}
