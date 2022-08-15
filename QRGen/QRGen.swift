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
	let correctionLevel: CorrectionLevel
	let style: Style
	let pixelMargin: UInt
	let ignoreSafeAreas: Bool
	let writePNG: Bool
	
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
		
		
		// Create basic QR Code
		let generator = CIQRCodeGenerator(correctionLevel: correctionLevel)
		let qrCode = try generator.generate(for: inputData)
		
		
		// Prepare output files
		let outputFileName = generateOutputFileNames()
		let outputFile = outputDir.appendingPathComponent(outputFileName.unstyled)
		let outputFileStyled = outputDir.appendingPathComponent(outputFileName.styled)
		
		
		// Create PNG (1px scale)
		if writePNG {
			//try createPNG(cicontext: cicontext, ciimage: ciimage, outputFile: outputFile)
		}
		
		// Create SVG
		try createSVG(qrCode: qrCode, outputFile: outputFileStyled)
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
	
	
//	private func createPNG(cicontext: CIContext, ciimage: CIImage, outputFile: URL) throws {
//		let outputFilePNG = outputFile.appendingPathExtension("png")
//		try cicontext.writePNGRepresentation(of: ciimage, to: outputFilePNG, format: .RGBA8, colorSpace: ciimage.colorSpace!)
//	}
	
	
	private func createSVG<T: QRCodeProtocol>(qrCode: T, outputFile: URL) throws {
		let border = 1
		let size = qrCode.size
		let sizeWithBorder = size + border*2
		let svg = BinaryPixelSVG(size: IntSize(width: sizeWithBorder, height: sizeWithBorder))
		
		// Create safe areas where not to apply styling
		let safeAreas = Self.safeAreas(for: size)
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
	
	
	private static func safeAreas(for size: Int) -> [IntRect] {
		let (version, remainder) = (size - 17).quotientAndRemainder(dividingBy: 4)
		precondition(remainder == 0 && version >= 1, "\(size) is not a valid QR code version size")
		
		var safeAreas = [IntRect]()
		func addSafeArea(x: Int, y: Int, width: Int, height: Int) {
			safeAreas.append(IntRect(x: x, y: y, width: width, height: height))
		}
		
		// Position markers
		let positionMarkerSize = 7
		func addPositionMarker(x: Int, y: Int) {
			addSafeArea(x: x, y: y, width: positionMarkerSize, height: positionMarkerSize)
		}
		addPositionMarker(x: 0, y: 0)
		addPositionMarker(x: 0, y: size-positionMarkerSize)
		addPositionMarker(x: size-positionMarkerSize, y: 0)
		
		// Alignment markers
		if version > 1 {
			let alignmentMarkerCount = (version / 7) + 1
			let alignmentMarkerOffset = positionMarkerSize - 1
			let alignmentMarkerDistance = (size - alignmentMarkerOffset*2) - 1
			let alignmentMarkerSpacing: Int = {
				// Equal spacing rounded first to nearest integer, then to next even integer
				let roundedEqualSpacing = lround(Double(alignmentMarkerDistance) / Double(alignmentMarkerCount))
				return roundedEqualSpacing + (roundedEqualSpacing & 0b1)
			}()
			let alignmentMarkerPositions = ([0] + (1...alignmentMarkerCount).map {
				alignmentMarkerDistance - alignmentMarkerSpacing * (alignmentMarkerCount - $0)
			}).map { $0 + alignmentMarkerOffset }
			
			let alignmentMarkerSize = 5
			func addAlignmentMarker(cx: Int, cy: Int) {
				addSafeArea(x: cx-alignmentMarkerSize/2, y: cy-alignmentMarkerSize/2, width: alignmentMarkerSize, height: alignmentMarkerSize)
			}
			for j in 0...alignmentMarkerCount {
				for i in 0...alignmentMarkerCount {
					switch (i, j) {
						case (0, 0): continue
						case (0, alignmentMarkerCount): continue
						case (alignmentMarkerCount, 0): continue
						default: addAlignmentMarker(cx: alignmentMarkerPositions[i], cy: alignmentMarkerPositions[j])
					}
				}
			}
		}
		
		return safeAreas
	}
}
