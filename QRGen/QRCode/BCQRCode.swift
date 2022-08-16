//
//  BCQRCode.swift
//  QRGen
//
//  Created by Max-Joseph on 15.08.22.
//

import Foundation
import AppKit
import struct QRCodeGenerator.QRCode

typealias BCQRCode = QRCode

extension BCQRCode: QRCodeProtocol {
	var cgimage: CGImage {
		let black = NSColor(red: 0, green: 0, blue: 0, alpha: 1.0)
		let white = NSColor(red: 1, green: 1, blue: 1, alpha: 1.0)
		let nsimage = self.makeImage(border: 0, foregroundColor: black, backgroundColor: white)
		return nsimage.cgImage(forProposedRect: nil, context: nil, hints: nil)!
	}
}
