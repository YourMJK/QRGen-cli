//
//  BCQRCode.swift
//  QRGen
//
//  Created by Max-Joseph on 15.08.22.
//

import Foundation
import struct QRCodeGenerator.QRCode

typealias BCQRCode = QRCode

extension BCQRCode: QRCodeProtocol {
	var cgimage: CGImage {
		self.makeImage(border: 0).cgImage(forProposedRect: nil, context: nil, hints: nil)!
	}
}
