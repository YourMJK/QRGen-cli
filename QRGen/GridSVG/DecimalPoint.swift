//
//  DecimalPoint.swift
//  QRGen
//
//  Created by Max-Joseph on 28.08.22.
//

import Foundation


struct DecimalPoint: Equatable, Hashable {
	var x: Decimal
	var y: Decimal
}

extension DecimalPoint {
	static let zero = Self(x: 0, y: 0)
}

extension DecimalPoint {
	func offsetBy(dx: Decimal, dy: Decimal) -> DecimalPoint {
		DecimalPoint(x: x+dx, y: y+dy)
	}
}
