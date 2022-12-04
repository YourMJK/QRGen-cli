//
//  QRGen.swift
//  QRGen
//
//  Created by Max-Joseph on 11.08.22.
//

import Foundation
#if canImport(AppKit)
import CoreImage
#endif

struct QRGen {
	let outputURL: URL
	let generatorType: GeneratorType
	let correctionLevel: CorrectionLevel
	let minVersion: Int
	let maxVersion: Int
	let optimize: Bool
	let strict: Bool
	let style: Style
	let pixelMargin: UInt
	let cornerRadius: UInt
	let ignoreSafeAreas: Bool
	let writePNG: Bool
	let noShapeOptimization: Bool
	
	enum Input {
		case data(Data)
		case text(String)
	}
	enum GeneratorType: String, ArgumentEnum {
		#if canImport(CoreImage)
		case coreImage
		#endif
		case nayuki
	}
	enum Style: String, ArgumentEnum {
		case standard
		case dots
		case holes
		case liquidDots
		case liquidHoles
	}
	
	
	/// Generate QR code from input and write output files
	func generate(with input: Input) throws {
		// Prepare output files
		let outputFile = generateOutputURLs()
		
		// Check output directory exists
		var isDirectory: ObjCBool = false
		guard FileManager.default.fileExists(atPath: outputFile.dir.path, isDirectory: &isDirectory) && isDirectory.boolValue else {
			exit(error: "No such output directory \"\(outputFile.dir.path)\"")
		}
		
		// Generate QR code and write output files
		func generate<T: QRCodeGeneratorProtocol>(using generatorType: T.Type) throws {
			// Generate basic QR Code
			let generator = T(correctionLevel: correctionLevel, minVersion: minVersion, maxVersion: maxVersion)
			let qrCode: T.Product = try {
				switch input {
					case .data(let data):
						return try generator.generate(for: data)
					case .text(let string):
						return try generator.generate(for: string, optimize: optimize, strictEncoding: strict)
				}
			}()
			
			// Create PNG (1px scale)
			if writePNG {
				#if canImport(AppKit)
				try createPNG(qrCode: qrCode, outputFile: outputFile.unstyled)
				#endif
			}
			
			// Create SVG
			try createSVG(qrCode: qrCode, outputFile: outputFile.styled)
		}
		switch generatorType {
			#if canImport(CoreImage)
			case .coreImage: try generate(using: CIQRCodeGenerator.self)
			#endif
			case .nayuki:    try generate(using: BCQRCodeGenerator.self)
		}
	}
	
	
	private func generateOutputURLs() -> (dir: URL, unstyled: URL, styled: URL) {
		let suffix = "QR-\(correctionLevel)"
		var suffixStyled = suffix
		
		func addNameTag(_ tag: String, _ condition: Bool) {
			guard condition else { return }
			suffixStyled += "-" + tag
		}
		addNameTag("\(style)", style != .standard)
		addNameTag("m\(pixelMargin)", pixelMargin != 0)
		addNameTag("r\(cornerRadius)", cornerRadius != 100 && style != .standard)
		addNameTag("all", ignoreSafeAreas)
		#if canImport(CoreImage)
		addNameTag("CI", generatorType == .coreImage)
		#endif
		
		let baseName = !outputURL.hasDirectoryPath ? outputURL.lastPathComponent : {
			let formatter = DateFormatter()
			formatter.locale = Locale(identifier: "en_US_POSIX")
			formatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
			return formatter.string(from: Date())
		}()
		let name = "\(baseName)_\(suffix)"
		let nameStyled = "\(baseName)_\(suffixStyled)"
		
		let baseURL = outputURL.hasDirectoryPath ? outputURL : outputURL.deletingLastPathComponent()
		let url = baseURL.appendingPathComponent(name)
		let urlStyled = baseURL.appendingPathComponent(nameStyled)
		
		return (baseURL, url, urlStyled)
	}
	
	
	#if canImport(AppKit)
	private func createPNG<T: QRCodeProtocol>(qrCode: T, outputFile: URL) throws {
		let outputFilePNG = outputFile.appendingPathExtension("png")
		let cicontext = CIContext()
		let ciimage = CIImage(cgImage: qrCode.cgimage)
		try cicontext.writePNGRepresentation(of: ciimage, to: outputFilePNG, format: .RGBA8, colorSpace: ciimage.colorSpace!)
	}
	#endif
	
	
	private func createSVG<T: QRCodeProtocol>(qrCode: T, outputFile: URL) throws {
		let border = 1
		let size = qrCode.size
		let sizeWithBorder = size + border*2
		let svg = GridSVG(size: IntSize(width: sizeWithBorder, height: sizeWithBorder))
		
		// Create safe areas where not to apply styling
		let safeAreas = qrCode.safeAreas()
		func isInSafeArea(_ point: IntPoint) -> Bool {
			safeAreas.contains { $0.contains(point) }
		}
		
		// Add pixels
		let rect = IntRect(origin: .zero, size: IntSize(width: size, height: size))
		let pixelMargin = Decimal(pixelMargin)/100
		let cornerRadius = Decimal(cornerRadius)/100
		func addPixel(at point: IntPoint, shape pixelShape: GridSVG.PixelShape, isPixel: Bool = true) {
			let pixelStyle: GridSVG.PixelStyle
			if ignoreSafeAreas || !isInSafeArea(point) {
				pixelStyle = GridSVG.PixelStyle(pixelShape, margin: pixelMargin, cornerRadius: cornerRadius)
			} else if isPixel {
				switch pixelShape {
					case .square: pixelStyle = .standard
					default: pixelStyle = GridSVG.PixelStyle(.roundedCorners([], inverted: false), margin: 0, cornerRadius: cornerRadius)
				}
			} else {
				return
			}
			let pointInImageCoordinates = point.offsetBy(dx: border, dy: border)
			svg.addPixel(at: pointInImageCoordinates, style: pixelStyle)
		}
		var bridgeLiquidDiagonally = false
		
		switch style {
			// Static pixel shape
			case .standard, .dots:
				let pixelShape: GridSVG.PixelShape
				switch (style, cornerRadius) {
					case (.standard, _): pixelShape = .square
					case (.dots,   0): pixelShape = .square
					case (.dots, 100): pixelShape = .circle
					case (.dots,   _): pixelShape = .roundedCorners(.all, inverted: false)
					default: preconditionFailure("Invalid pixel shape for static style")
				}
				rect.forEach { point in
					let isPixel = qrCode[point]
					guard isPixel else { return }
					addPixel(at: point, shape: pixelShape)
				}
			
			// Dynamic pixel shape
			case .holes:
				rect.forEach { point in
					let isPixel = qrCode[point]
					let pixelShape: GridSVG.PixelShape
					if isPixel {
						pixelShape = .roundedCorners([], inverted: false)
					} else if cornerRadius != 0 {
						pixelShape = .roundedCorners(.all, inverted: true)
					} else {
						return
					}
					addPixel(at: point, shape: pixelShape, isPixel: isPixel)
				}
			
			case .liquidHoles:
				bridgeLiquidDiagonally = true
				fallthrough
			case .liquidDots:
				rect.forEach { point in
					let isPixel = qrCode[point]
					var corners: GridSVG.Corners = []
					func isNeighborPixel(dx: Int, dy: Int) -> Bool {
						let neighborPoint = point.offsetBy(dx: dx, dy: dy)
						return rect.contains(neighborPoint) && qrCode[neighborPoint]
					}
					for corner in GridSVG.Corners.all {
						let (dx, dy) = corner.offset
						let shouldRound = 
							isNeighborPixel(dx: dx, dy: 0) != isPixel &&
							isNeighborPixel(dx: 0, dy: dy) != isPixel &&
							(isNeighborPixel(dx: dx, dy: dy) != isPixel || isPixel != bridgeLiquidDiagonally)
						if shouldRound {
							corners.insert(corner)
						}
					}
					let pixelShape: GridSVG.PixelShape = .roundedCorners(corners, inverted: !isPixel)
					addPixel(at: point, shape: pixelShape, isPixel: isPixel)
				}
		}
		
		// Write file
		let outputFileSVG = outputFile.appendingPathExtension("svg")
		try svg.content(combineClusters: !noShapeOptimization).write(to: outputFileSVG, atomically: true, encoding: .utf8)
	}
}
