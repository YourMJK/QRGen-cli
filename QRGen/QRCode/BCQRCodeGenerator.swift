//
//  BCQRCodeGenerator.swift
//  QRGen
//
//  Created by Max-Joseph on 16.08.22.
//

import Foundation
import QRCodeGenerator


struct BCQRCodeGenerator: QRCodeGeneratorProtocol {
	typealias Product = QRCode
	
	let correctionLevel: BCCorrectionLevel
	
	init(correctionLevel: CorrectionLevel) {
		self.correctionLevel = {
			switch correctionLevel {
				case .L: return .low
				case .M: return .medium
				case .Q: return .quartile
				case .H: return .high
			}
		}()
	}
	
	func generate(for data: Data) throws -> QRCode {
		try QRCode.encode(data: Array(data), correctionLevel: correctionLevel)
	}
	
	func generate(for text: String, optimize: Bool = false) throws -> QRCode {
		try QRCode.encode(text: text, correctionLevel: correctionLevel, optimize: optimize)
	}
}
