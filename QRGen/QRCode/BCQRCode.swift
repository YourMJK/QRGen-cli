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
		let nsimage = self.makeImage(border: 0)
		return nsimage.cgImage(forProposedRect: nil, context: nil, hints: nil)!
	}
}
