//
//  IntSize.swift
//  QRGen
//
//  Created by Max-Joseph on 15.08.22.
//

import Foundation


struct IntSize: Equatable {
	var width: Int {
		willSet { precondition(newValue >= 0, "Width of IntSize must be positive") }
	}
	var height: Int {
		willSet { precondition(newValue >= 0, "Height of IntSize must be positive") }
	}
	
	init(width: Int, height: Int) {
		precondition(width >= 0 && height >= 0, "Width and height of IntSize must be positive")
		self.width = width
		self.height = height
	}
}

extension IntSize {
	static let zero = Self(width: 0, height: 0)
}

extension IntSize {
	var isEmpty: Bool {
		width == 0 || height == 0
	}
}
