//
//  QRGen.swift
//  QRGen
//
//  Created by Max-Joseph on 11.08.22.
//

import Foundation
import CoreImage


struct QRGen {
	let outputDir: URL
	let outputFileName: String?
	let generatorType: GeneratorType
	let correctionLevel: CorrectionLevel
	let style: Style
	let pixelMargin: UInt
	let ignoreSafeAreas: Bool
	let writePNG: Bool
	
	enum GeneratorType: String, ArgumentEnum {
		case coreImage
		case nayuki
	}
	enum Style: String, ArgumentEnum {
		case standard
		case dots
	}
	
	
	/// Generate QR code with byte encoding from data in file and write output files
	func generate(withDataFrom inputFile: URL) throws {
		let inputData = try Data(contentsOf: inputFile)
		try generate(withData: inputData)
	}
	
	/// Generate QR code with byte encoding from data and write output files
	func generate(withData inputData: Data) throws {
		// Check output directory exists
		var isDirectory: ObjCBool = false
		guard FileManager.default.fileExists(atPath: outputDir.path, isDirectory: &isDirectory) && isDirectory.boolValue else {
			exit(error: "No such output directory \"\(outputDir.path)\"")
		}
		
		// Prepare output files
		let outputFileName = generateOutputFileNames()
		let outputFile = outputDir.appendingPathComponent(outputFileName.unstyled)
		let outputFileStyled = outputDir.appendingPathComponent(outputFileName.styled)
		
		// Generate QR code and write output files
		func generate<T: QRCodeGeneratorProtocol>(using generatorType: T.Type) throws {
			// Generate basic QR Code
			let generator = T(correctionLevel: correctionLevel)
			let qrCode = try generator.generate(for: inputData)
			
			// Create PNG (1px scale)
			if writePNG {
				try createPNG(qrCode: qrCode, outputFile: outputFile)
			}
			
			// Create SVG
			try createSVG(qrCode: qrCode, outputFile: outputFileStyled)
		}
		switch generatorType {
			case .coreImage: try generate(using: CIQRCodeGenerator.self)
			case .nayuki:    try generate(using: BCQRCodeGenerator.self)
		}
	}
	
	
	private func generateOutputFileNames() -> (unstyled: String, styled: String) {
		let suffix = "QR-\(correctionLevel)"
		var suffixStyled = suffix
		
		func addNameTag(_ tag: String, _ condition: Bool) {
			guard condition else { return }
			suffixStyled += "-" + tag
		}
		addNameTag("\(style)", style != .standard)
		addNameTag("m\(pixelMargin)", pixelMargin != 0)
		addNameTag("all", ignoreSafeAreas)
		addNameTag("CI", generatorType == .coreImage)
		
		let baseName = outputFileName ?? {
			let formatter = DateFormatter()
			formatter.locale = Locale(identifier: "en_US_POSIX")
			formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
			return formatter.string(from: Date())
		}()
		let name = "\(baseName)_\(suffix)"
		let nameStyled = "\(baseName)_\(suffixStyled)"
		
		return (name, nameStyled)
	}
	
	
	private func createPNG<T: QRCodeProtocol>(qrCode: T, outputFile: URL) throws {
		let outputFilePNG = outputFile.appendingPathExtension("png")
		let cicontext = CIContext()
		let ciimage = CIImage(cgImage: qrCode.cgimage)
		try cicontext.writePNGRepresentation(of: ciimage, to: outputFilePNG, format: .RGBA8, colorSpace: ciimage.colorSpace!)
	}
	
	
	private func createSVG<T: QRCodeProtocol>(qrCode: T, outputFile: URL) throws {
		let border = 1
		let size = qrCode.size
		let sizeWithBorder = size + border*2
		let svg = BinaryPixelSVG(size: IntSize(width: sizeWithBorder, height: sizeWithBorder))
		
		// Create safe areas where not to apply styling
		let safeAreas = qrCode.safeAreas()
		func isInSafeArea(_ point: IntPoint) -> Bool {
			safeAreas.contains { $0.contains(point) }
		}
		
		// Add pixels
		let pixelShape: BinaryPixelSVG.PixelShape = {
			switch style {
				case .standard: return .square
				case .dots: return .circle
			}
		}()
		let pixelStyle = BinaryPixelSVG.PixelStyle(pixelShape, margin: Double(pixelMargin)/100)
		IntRect(origin: .zero, size: IntSize(width: size, height: size)).forEach { point in
			let isPixel = qrCode[point]
			guard isPixel else { return }
			let pixelStyle = !ignoreSafeAreas && isInSafeArea(point) ? .standard : pixelStyle
			let pointInImageCoordinates = point.offsetBy(dx: border, dy: border)
			svg.addPixel(at: pointInImageCoordinates, style: pixelStyle)
		}
		
		// Write file
		let outputFileSVG = outputFile.appendingPathExtension("svg")
		try svg.content.write(to: outputFileSVG, atomically: true, encoding: .utf8)
	}
}
