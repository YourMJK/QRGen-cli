//
//  IntPoint.swift
//  QRGen
//
//  Created by Max-Joseph on 15.08.22.
//

import Foundation


struct IntPoint: Equatable, Hashable {
	var x: Int
	var y: Int
}

extension IntPoint {
	static let zero = Self(x: 0, y: 0)
}

extension IntPoint {
	func offsetBy(dx: Int, dy: Int) -> IntPoint {
		IntPoint(x: x+dx, y: y+dy)
	}
}
