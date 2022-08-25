//
//  PixelSVG.swift
//  QRGen
//
//  Created by Max-Joseph on 08.08.22.
//

import Foundation

class BinaryPixelSVG {
	
	struct PixelCorners: OptionSet {
		let rawValue: UInt8
		
		static let topLeft     = Self(rawValue: 1 << 0)
		static let topRight    = Self(rawValue: 1 << 1)
		static let bottomLeft  = Self(rawValue: 1 << 2)
		static let bottomRight = Self(rawValue: 1 << 3)
	}
	
	enum PixelShape {
		case square
		case circle
		case roundedCorners(_ corners: PixelCorners, inverted: Bool)
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
			
			case .roundedCorners(let corners, let inverted):
				if corners.isEmpty {
					if inverted { break }
					else { addPixel(at: point) }
				}
				let radiusValue = scale * 0.5
				let radius = format(radiusValue)
				contentBuilerString += "\t<path d=\""
				
				func cornerPath(for corner: PixelCorners, at point: IntPoint, from start: (x: Double, y: Double), to end: (x: Double, y: Double), first: Bool = false) {
					if inverted && !corners.contains(corner) { return }
					let xPosValue = Double(point.x)
					let yPosValue = Double(point.y)
					let xPos = String(point.x)
					let yPos = String(point.y)
					let xStart = format(xPosValue + radiusValue*start.x)
					let yStart = format(yPosValue + radiusValue*start.y)
					let xEnd = format(xPosValue + radiusValue*end.x)
					let yEnd = format(yPosValue + radiusValue*end.y)
					if inverted || first {
						contentBuilerString += "M\(xStart) \(yStart)"
					} else if scale != 1 {
						contentBuilerString += "L\(xStart) \(yStart)"
					}
					if corners.contains(corner) {
						contentBuilerString += "A\(radius) \(radius) 0 0 1 \(xEnd) \(yEnd)"
						if inverted {
							contentBuilerString += "L\(xPos) \(yPos)Z"
						}
					} else if !inverted {
						contentBuilerString += "L\(xPos) \(yPos)"
						contentBuilerString += "L\(xEnd) \(yEnd)"
					}
				}
				cornerPath(for: .topLeft,     at: point.offsetBy(dx: 0, dy: 0), from: ( 0,+1), to: (+1, 0), first: true)
				cornerPath(for: .topRight,    at: point.offsetBy(dx: 1, dy: 0), from: (-1, 0), to: ( 0,+1))
				cornerPath(for: .bottomRight, at: point.offsetBy(dx: 1, dy: 1), from: ( 0,-1), to: (-1, 0))
				cornerPath(for: .bottomLeft,  at: point.offsetBy(dx: 0, dy: 1), from: (+1, 0), to: ( 0,-1))
				
				if !inverted {
					contentBuilerString += "Z"
				}
				contentBuilerString += "\"/>\n"
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
