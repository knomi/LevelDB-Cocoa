//
//  DataSerializable-Double.swift
//  LevelDB-Cocoa
//
//  Copyright (c) 2015 Pyry Jahkola. All rights reserved.
//

import Foundation

extension Double : DataSerializable {
    public static func fromSerializedData(data: NSData) -> Double? {
        return OrderPreservingValue.fromSerializedData(data).map {value in
            Double(orderPreservingValue: value)
        }
    }

    public var serializedData: NSData {
        return orderPreservingValue.serializedData
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
        let expBits = (bits >> U(DBL_MANT_DIG - 1))
        let mantBits = bits & ~(U.max << U(DBL_MANT_DIG - 1))
        if expBits == 0 {
            self = sign * DBL_TRUE_MIN * Double(mantBits)
        } else if expBits < 2047 {
            self = sign * (1 + DBL_EPSILON * Double(mantBits)) * pow(2.0, Double(expBits) - 1023)
        } else if mantBits == 0 {
            self = sign * Double.infinity
        } else {
            self = Double.NaN
        }
    }

    public var orderPreservingValue: UInt64 {
        typealias U = UInt64
        let zeroValue: U = ~(~0 / 2) // = 0b1000...000
        let isNegative = signbit(self) != 0
        let fixSign: U -> U = {u in isNegative ? ~u + 1 : u}
        if isNaN {
            return U.max
        } else if !isFinite {
            return fixSign(U.max << U(DBL_MANT_DIG - 1))
        } else {
            var exponent = Int32(0)
            let significand = frexp(abs(self), &exponent)
            let expo = 1 + exponent - DBL_MIN_EXP
            if significand == 0 {
                return fixSign(zeroValue)
            } else if expo < 1 {
                let mant = U(scalbln(significand, Int(DBL_MANT_DIG + expo - 1)))
                return fixSign(zeroValue | mant)
            } else {
                let mant = U(scalbln(significand - 0.5, Int(DBL_MANT_DIG)))
                return fixSign(zeroValue | mant | U(expo) << U(DBL_MANT_DIG - 1))
            }
        }
    }
}
