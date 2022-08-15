//
//  IntPoint.swift
//  QRGen
//
//  Created by Max-Joseph on 15.08.22.
//

import Foundation


struct IntPoint: Equatable {
	var x: Int
	var y: Int
}

extension IntPoint {
	static let zero = Self(x: 0, y: 0)
}
