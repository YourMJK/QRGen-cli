//
//  PixelSVG.swift
//  QRGen
//
//  Created by Max-Joseph on 08.08.22.
//

import Foundation

class BinaryPixelSVG {
	
	enum PixelShape {
		case square
		case circle
	}
	
	struct PixelStyle {
		let shape: PixelShape
		let margin: Double
		
		init(_ shape: PixelShape, margin: Double = 0) {
			self.shape = shape
			self.margin = min(max(margin, 0), 1)
		}
		
		static let standard = Self(.square)
	}
	
	
	let size: IntSize
	private var contentBuilerString: String
	private let floatFormatter: NumberFormatter
	
	init(size: IntSize) {
		self.size = size
		self.contentBuilerString =
		"""
		<?xml version="1.0" encoding="UTF-8" standalone="no"?>
		<svg width="100%" height="100%" viewBox="0 0 \(size.width) \(size.height)" version="1.1" xmlns="http://www.w3.org/2000/svg" xmlns:xlink="http://www.w3.org/1999/xlink">
		
		"""
		self.floatFormatter = {
			let formatter = NumberFormatter()
			formatter.locale = Locale(identifier: "en_US_POSIX")
			formatter.maximumFractionDigits = 2
			formatter.minimumIntegerDigits = 1
			return formatter
		}()
	}
	
	
	private func format(_ number: Double) -> String {
		floatFormatter.string(from: number as NSNumber)!
	}
	
	
	var content: String {
		contentBuilerString + "</svg>\n"
	}
	
	func addPixel(at point: IntPoint, style: PixelStyle = .standard) {
		let margin = style.margin
		let scale = 1 - margin
		switch style.shape {
			case .square:
				let size = format(scale)
				let xPos = format(Double(point.x) + margin/2)
				let yPos = format(Double(point.y) + margin/2)
				contentBuilerString += "\t<rect x=\"\(xPos)\" y=\"\(yPos)\" width=\"\(size)\" height=\"\(size)\"/>\n"
			case .circle:
				let radius = format(scale * 0.5)
				contentBuilerString += "\t<circle cx=\"\(point.x).5\" cy=\"\(point.y).5\" r=\"\(radius)\"/>\n"
		}
	}
	
	func addPixels(isPixel: (IntPoint) -> PixelStyle?) {
		IntRect(origin: .zero, size: size).forEach { point in
			if let pixelStyle = isPixel(point) {
				addPixel(at: point, style: pixelStyle)
			}
		}
	}
}
