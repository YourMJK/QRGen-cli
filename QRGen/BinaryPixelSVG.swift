//
//  PixelSVG.swift
//  QRGen
//
//  Created by Max-Joseph on 08.08.22.
//

import Foundation

class BinaryPixelSVG {
	
	enum PixelStyle {
		case square
		case circle
	}
	
	
	let width: Int
	let height: Int
	private var contentBuilerString: String
	
	init(width: Int, height: Int) {
		self.width = width
		self.height = height
		self.contentBuilerString =
		"""
		<?xml version="1.0" encoding="UTF-8" standalone="no"?>
		<svg width="100%" height="100%" viewBox="0 0 \(width) \(height)" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
		
		"""
	}
	
	
	var content: String {
		contentBuilerString + "</svg>\n"
	}
	
	func addPixel(x: Int, y: Int, style: PixelStyle = .square) {
		switch style {
			case .square:
				contentBuilerString += "\t<rect x=\"\(x)\" y=\"\(y)\" width=\"1\" height=\"1\"/>\n"
			case .circle:
				contentBuilerString += "\t<circle cx=\"\(x).5\" cy=\"\(y).5\" r=\"0.5\"/>\n"
		}
	}
	
	func addPixels(isPixel: (_ x: Int, _ y: Int) -> PixelStyle?) {
		for y in 0..<height {
			for x in 0..<width {
				if let style = isPixel(x, y) {
					addPixel(x: x, y: y, style: style)
				}
			}
		}
	}
}


extension BinaryPixelSVG {
	struct Point: Comparable {
		let x: Int
		let y: Int
		
		/// NOTE: Not a strict total order (like `Comparable` actually implies) but a strict partial order (no totality)
		static func < (lhs: Self, rhs: Self) -> Bool {
			(lhs <= rhs) && lhs != rhs
		}
		static func > (lhs: Point, rhs: Point) -> Bool { rhs < lhs }
		
		/// NOTE: Non-strict partial order (no totality)
		static func <= (lhs: Point, rhs: Point) -> Bool {
			lhs.x <= rhs.x && lhs.y <= rhs.y
		}
		static func >= (lhs: Point, rhs: Point) -> Bool { rhs <= lhs }
	}
	
	func addPixel(at point: Point, style: PixelStyle = .square) {
		addPixel(x: point.x, y: point.y, style: style)
	}
	
	func addPixels(isPixel: (Point) -> PixelStyle?) {
		addPixels { x, y in
			isPixel(Point(x: x, y: y))
		}
	}
}
