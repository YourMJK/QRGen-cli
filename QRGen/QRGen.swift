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
	let pixelMargin: UInt
	let ignoreSafeAreas: Bool
	let writePNG: Bool
	
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
		
		
		// Prepare output files
		let outputFileName = "\(inputFile.deletingPathExtension().lastPathComponent)_QR-\(correctionLevel)"
		var outputFileNameStyled = outputFileName
		func addNameTag(_ tag: String, _ condition: Bool) {
			guard condition else { return }
			outputFileNameStyled += "-" + tag
		}
		addNameTag("\(style)", style != .standard)
		addNameTag("m\(pixelMargin)", pixelMargin != 0)
		addNameTag("all", ignoreSafeAreas)
		
		let outputFile = outputDir.appendingPathComponent(outputFileName)
		let outputFileStyled = outputDir.appendingPathComponent(outputFileNameStyled)
		let cicontext = CIContext()
		
		
		// Create PNG (1px scale)
		if writePNG {
			try createPNG(cicontext: cicontext, ciimage: ciimage, outputFile: outputFile)
		}
		
		// Create SVG
		try createSVG(cicontext: cicontext, ciimage: ciimage, outputFile: outputFileStyled)
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
		
		// Create safe areas where not to apply styling
		var safeAreas = [ClosedRange<BinaryPixelSVG.Point>]()
		func addSafeArea(x: Int, y: Int, width: Int, height: Int) {
			safeAreas.append(BinaryPixelSVG.Point(x: x, y: y)...BinaryPixelSVG.Point(x: x+width, y: y+height))
		}
		func isInSafeArea(_ point: BinaryPixelSVG.Point) -> Bool {
			safeAreas.contains { $0.contains(point) }
		}
		let positionMarkerSize = 7
		addSafeArea(x: 1, y: 1, width: positionMarkerSize, height: positionMarkerSize)
		addSafeArea(x: 1, y: svg.height-positionMarkerSize-1, width: positionMarkerSize, height: positionMarkerSize)
		addSafeArea(x: svg.width-positionMarkerSize-1, y: 1, width: positionMarkerSize, height: positionMarkerSize)
		
		// Add pixels
		let pixelShape: BinaryPixelSVG.PixelShape = {
			switch style {
				case .standard: return .square
				case .dots: return .circle
			}
		}()
		let pixelStyle = BinaryPixelSVG.PixelStyle(pixelShape, margin: Double(pixelMargin)/100)
		svg.addPixels { point in
			let isPixel = dataPointer[cgimage.bytesPerRow*point.y + point.x*4] == 0
			guard isPixel else { return nil }
			return !ignoreSafeAreas && isInSafeArea(point) ? .standard : pixelStyle
		}
		
		// Write file
		let outputFileSVG = outputFile.appendingPathExtension("svg")
		try svg.content.write(to: outputFileSVG, atomically: true, encoding: .utf8)
	}
}
