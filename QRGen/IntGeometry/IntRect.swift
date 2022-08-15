//
//  IntRect.swift
//  QRGen
//
//  Created by Max-Joseph on 15.08.22.
//

import Foundation


struct IntRect: Equatable {
	var origin: IntPoint
	var size: IntSize
}

extension IntRect {
	static let zero = Self(origin: .zero, size: .zero)
	
	init(x: Int, y: Int, width: Int, height: Int) {
		self.origin = IntPoint(x: x, y: y)
		self.size = IntSize(width: width, height: height)
	}
	
	init(point1: IntPoint, point2: IntPoint) {
		let minX = min(point1.x, point2.x)
		let minY = min(point1.y, point2.y)
		let maxX = max(point1.x, point2.x)
		let maxY = max(point1.y, point2.y)
		self.origin = IntPoint(x: minX, y: minY)
		self.size = IntSize(width: maxX-minX, height: maxY-minY)
	}
}

extension IntRect {
	var minX: Int {
		origin.x
	}
	var minY: Int {
		origin.y
	}
	var minPoint: IntPoint {
		origin
	}
	var maxX: Int {
		origin.x + size.width
	}
	var maxY: Int {
		origin.y + size.height
	}
	var maxPoint: IntPoint {
		IntPoint(x: maxX, y: maxY)
	}
	
	var width: Int {
		size.width
	}
	var height: Int {
		size.height
	}
	var isEmpty: Bool {
		width == 0 || height == 0
	}
}

extension IntRect {
	func offsetBy(dx: Int, dy: Int) -> IntRect {
		IntRect(origin: IntPoint(x: origin.x+dx, y: origin.y+dy), size: size)
	}
	func insetBy(dx: Int, dy: Int) -> IntRect {
		IntRect(x: origin.x-dx, y: origin.y-dy, width: size.width-dx*2, height: size.height-dy*2)
	}
	
	func union(_ r2: IntRect) -> IntRect {
		let minX = min(self.minX, r2.minX)
		let minY = min(self.minY, r2.minY)
		let maxX = max(self.maxX, r2.maxX)
		let maxY = max(self.maxY, r2.maxY)
		return IntRect(origin: IntPoint(x: minX, y: minY), size: IntSize(width: maxX-minX, height: maxY-minY))
	}
	func intersection(_ r2: IntRect) -> IntRect {
		let minX = max(self.minX, r2.minX)
		let minY = max(self.minY, r2.minY)
		let maxX = min(self.maxX, r2.maxX)
		let maxY = min(self.maxY, r2.maxY)
		let width = maxX-minX
		let height = maxY-minY
		if width < 0 || height < 0 { return .zero }
		return IntRect(origin: IntPoint(x: minX, y: minY), size: IntSize(width: width, height: height))
	}
	
	func contains(_ point: IntPoint) -> Bool {
		minX <= point.x && minY <= point.y && point.x < maxX && point.y < maxY
	}
	func contains(_ rect2: IntRect) -> Bool {
		union(rect2) == self
	}
	func intersects(_ rect2: IntRect) -> Bool {
		!intersection(rect2).isEmpty
	}
}
