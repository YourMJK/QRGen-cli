//
//  QRCodeProtocol.swift
//  QRGen
//
//  Created by Max-Joseph on 15.08.22.
//

import Foundation


protocol QRCodeProtocol {
	/// The width and height of this QR Code, measured in modules, between 21 and 177 (inclusive). This is equal to version * 4 + 17.
	var size: Int { get }
	
	/// The modules of this QR Code (false = white, true = black).
	subscript(_ x: Int, _ y: Int) -> Bool { get }
}

extension QRCodeProtocol {
	/// The modules of this QR Code (false = white, true = black).
	subscript(_ point: IntPoint) -> Bool { 
		self[point.x, point.y]
	}
}
