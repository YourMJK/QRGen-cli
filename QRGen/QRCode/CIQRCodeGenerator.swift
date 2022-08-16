//
//  CIQRCodeGenerator.swift
//  QRGen
//
//  Created by Max-Joseph on 14.08.22.
//

import Foundation
import CoreImage


/// A wrapper for `CoreImage`'s built-in "CIQRCodeGenerator" `CIFilter`
struct CIQRCodeGenerator: QRCodeGeneratorProtocol {
	typealias Product = CIQRCode
	
	let correctionLevel: CorrectionLevel
	
	func generate(for data: Data) throws -> CIQRCode {
		guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
			throw Error.unavailable
		}
		filter.setValue(data, forKey: "inputMessage")
		filter.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")
		
		guard let ciimage = filter.outputImage else {
			throw Error.unknown
		}
		let cropRect = ciimage.extent.insetBy(dx: 1, dy: 1)  // Remove empty 1px border around QR code
		let croppedCIImage = ciimage.cropped(to: cropRect)
		guard let ciQRCode = CIQRCode(ciimage: croppedCIImage) else {
			throw Error.bitmapData
		}
		
		return ciQRCode
	}
	
	func generate(for text: String, optimize: Bool) throws -> CIQRCode {
		guard let data = text.data(using: .isoLatin1) else {
			throw Error.textEncoding
		}
		return try generate(for: data)
	}
}


extension CIQRCodeGenerator {
	enum Error: LocalizedError {
		case unavailable
		case unknown
		case bitmapData
		case textEncoding
		
		var errorDescription: String? {
			switch self {
				case .unavailable: return "CoreImage filter \"CIQRCodeGenerator\" is not available"
				case .unknown: return "Couldn't generate QR code"
				case .bitmapData: return "Couldn't read bitmap data"
				case .textEncoding: return "Couldn't encode supplied text using Latin-1 encoding"
			}
		}
	}
}
