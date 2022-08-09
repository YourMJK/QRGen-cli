//
//  PixelSVG.swift
//  QRGen
//
//  Created by Max-Joseph on 08.08.22.
//

import Foundation

class BinaryPixelSVG {
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
	
	func addPixel(x: Int, y: Int) {
		contentBuilerString += "\t<rect x=\"\(x)\" y=\"\(y)\" width=\"1\" height=\"1\"/>\n"
	}
	
	func addPixels(isPixel: (_ x: Int, _ y: Int) -> Bool) {
		for y in 0..<height {
			for x in 0..<width {
				if isPixel(x,y) {
					addPixel(x: x, y: y)
				}
			}
		}
	}
}
