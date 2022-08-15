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
	let correctionLevel: String
	
	func generate(for data: Data) throws -> CIImage {
		guard let filter = CIFilter(name: "CIQRCodeGenerator") else {
			throw Error.unavailable
		}
		filter.setValue(data, forKey: "inputMessage")
		filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")
		
		guard let ciimage = filter.outputImage else {
			throw Error.unknownError
		}
		let cropRect = ciimage.extent.insetBy(dx: 1, dy: 1)  // Remove empty 1px border around QR code
		let croppedCIImage = ciimage.cropped(to: cropRect)
		
		return croppedCIImage
	}
}


extension CIQRCodeGenerator {
	enum Error: LocalizedError {
		case unavailable
		case unknownError
		
		var errorDescription: String? {
			switch self {
				case .unavailable: return "CoreImage filter \"CIQRCodeGenerator\" is not available"
				case .unknownError: return "Couldn't generate QR code"
			}
		}
	}
}
