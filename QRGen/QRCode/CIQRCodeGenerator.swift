//
//  CIQRCodeGenerator.swift
//  QRGen
//
//  Created by Max-Joseph on 14.08.22.
//

#if canImport(CoreImage)
import Foundation
import CoreImage


/// A wrapper for `CoreImage`'s built-in "CIQRCodeGenerator" `CIFilter`
struct CIQRCodeGenerator: QRCodeGeneratorProtocol {
	typealias Product = CIQRCode
	
	let correctionLevel: CorrectionLevel
	let minVersion: Int
	let maxVersion: Int
	
	func generate(for data: Data) throws -> CIQRCode {
		precondition(1 <= maxVersion && maxVersion <= 40, "\(maxVersion) is not a valid QR code version")
		guard minVersion == 1 else {
			throw Error.unsupported(property: "minVersion")
		}
		
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
		guard ciQRCode.version <= maxVersion else {
			throw Error.maxVersionTooLow
		}
		
		return ciQRCode
	}
	
	func generate(for text: String, optimize: Bool = false, strictEncoding: Bool = true) throws -> CIQRCode {
		guard !optimize else {
			throw Error.unsupported(property: "optimize")
		}
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
		case maxVersionTooLow
		case unsupported(property: String)
		
		var errorDescription: String? {
			switch self {
				case .unavailable: return "CoreImage filter \"CIQRCodeGenerator\" is not available"
				case .unknown: return "Couldn't generate QR code"
				case .bitmapData: return "Couldn't read bitmap data"
				case .textEncoding: return "Couldn't encode supplied text using Latin-1 encoding"
				case .maxVersionTooLow: return "Couldn't encode input within a QR code that doesn't exceed the supplied maximum version"
				case .unsupported(let property): return "Property \"\(property)\" is not supported by CoreImage QR code generator"
			}
		}
	}
}
#endif
