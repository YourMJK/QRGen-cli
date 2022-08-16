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
	let minVersion: Int
	let maxVersion: Int
	
	init(correctionLevel: CorrectionLevel, minVersion: Int, maxVersion: Int) {
		self.correctionLevel = {
			switch correctionLevel {
				case .L: return .low
				case .M: return .medium
				case .Q: return .quartile
				case .H: return .high
			}
		}()
		self.minVersion = minVersion
		self.maxVersion = maxVersion
	}
	
	func generate(for data: Data) throws -> QRCode {
		try QRCode.encode(data: Array(data), correctionLevel: correctionLevel, minVersion: minVersion, maxVersion: maxVersion)
	}
	
	func generate(for text: String, optimize: Bool = false) throws -> QRCode {
		try QRCode.encode(text: text, correctionLevel: correctionLevel, minVersion: minVersion, maxVersion: maxVersion, optimize: optimize)
	}
}
