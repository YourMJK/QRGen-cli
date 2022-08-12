//
//  QRGen.swift
//  QRGen
//
//  Created by Max-Joseph on 11.08.22.
//

import Foundation
import CoreImage


struct QRGen {
	let inputFile: URL
	let outputDir: URL
	let correctionLevel: CorrectionLevel
	let style: Style
	
	enum CorrectionLevel: String, ArgumentEnum {
		case L, M, Q, H
	}
	enum Style: String, ArgumentEnum {
		case standard
		case dots
	}
	
	
	/// Generate QR code and write output files
	func run() throws {
		// Read data from file
		let inputData = try Data(contentsOf: inputFile)
		
		// Check output directory exists
		var isDirectory: ObjCBool = false
		guard FileManager.default.fileExists(atPath: outputDir.path, isDirectory: &isDirectory) && isDirectory.boolValue else {
			exit(error: "No such output directory \"\(outputDir.path)\"")
		}
		
		
		// Create CoreImage filter
		let filter = CIFilter(name: "CIQRCodeGenerator")!
		filter.setValue(inputData, forKey: "inputMessage")
		filter.setValue(correctionLevel.rawValue, forKey: "inputCorrectionLevel")
		
		guard let ciimage = filter.outputImage else {
			exit(error: "Couldn't generate QR code")
		}
		
		
		// Write output files
		let outputFileName = "\(inputFile.deletingPathExtension().lastPathComponent)_QR-\(correctionLevel)" + (style != .standard ? "-\(style)" : "")
		let outputFile = outputDir.appendingPathComponent(outputFileName)
		let cicontext = CIContext()
		
		// PNG (1px scale)
		if style == .standard {
			try createPNG(cicontext: cicontext, ciimage: ciimage, outputFile: outputFile)
		}
		
		// SVG
		try createSVG(cicontext: cicontext, ciimage: ciimage, outputFile: outputFile)
	}
	
	
	private func createPNG(cicontext: CIContext, ciimage: CIImage, outputFile: URL) throws {
		let outputFilePNG = outputFile.appendingPathExtension("png")
		try cicontext.writePNGRepresentation(of: ciimage, to: outputFilePNG, format: .RGBA8, colorSpace: ciimage.colorSpace!)
	}
	
	
	private func createSVG(cicontext: CIContext, ciimage: CIImage, outputFile: URL) throws {
		guard
			let cgimage = cicontext.createCGImage(ciimage, from: ciimage.extent, format: .RGBA8, colorSpace: ciimage.colorSpace!),
			let cfdata = cgimage.dataProvider?.data,
			let dataPointer = CFDataGetBytePtr(cfdata),
			cgimage.bitsPerPixel == 32 else {
				exit(error: "Couldn't read bitmap data")
		}
		
		let svg = BinaryPixelSVG(width: cgimage.width, height: cgimage.height)
		
		// Add pixels
		let pixelStyle: BinaryPixelSVG.PixelStyle = {
			switch style {
				case .standard: return .square
				case .dots: return .circle
			}
		}()
		svg.addPixels { point in
			let isPixel = dataPointer[cgimage.bytesPerRow*point.y + point.x*4] == 0
			guard isPixel else { return nil }
			return pixelStyle
		}
		
		// Write file
		let outputFileSVG = outputFile.appendingPathExtension("svg")
		try svg.content.write(to: outputFileSVG, atomically: true, encoding: .utf8)
	}
}
