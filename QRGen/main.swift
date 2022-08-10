//
//  main.swift
//  QRGen
//
//  Created by Max-Joseph on 08.08.22.
//

import Foundation
import CoreImage
import ArgumentParser


typealias ArgumentEnum = ExpressibleByArgument & CaseIterable

enum CorrectionLevel: String, ArgumentEnum {
	case L, M, Q, H
}

struct Arguments: ParsableCommand {
	static var configuration: CommandConfiguration {
		CommandConfiguration(commandName: ProgramName)
	}
	
	@Option(name: .shortAndLong, help: ArgumentHelp("The QR code's correction level (parity)", valueName: "correction level"))
	var level: CorrectionLevel = .M
	
	@Argument(help: ArgumentHelp("File containing the QR code's data", valueName: "input data file"), transform: URL.init(fileURLWithPath:))
	var inputFile: URL
	
	@Argument(help: ArgumentHelp("Directory to write output files to", valueName: "output directory"), transform: URL.init(fileURLWithPath:))
	var outputDir: URL
}

// Parse arguments
let arguments = Arguments.parseOrExit()
let inputFile = arguments.inputFile
let outputDir = arguments.outputDir
let correctionLevel = arguments.level


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
let outputFileName = "\(inputFile.deletingPathExtension().lastPathComponent)_QR-\(correctionLevel)"
let outputFile = outputDir.appendingPathComponent(outputFileName)

// PNG (1px scale)
let outputFilePNG = outputFile.appendingPathExtension("png")
let context = CIContext()
try context.writePNGRepresentation(of: ciimage, to: outputFilePNG, format: .RGBA8, colorSpace: ciimage.colorSpace!)

// SVG
guard
	let cgimage = context.createCGImage(ciimage, from: ciimage.extent, format: .RGBA8, colorSpace: ciimage.colorSpace!),
	let cfdata = cgimage.dataProvider?.data,
	let dataPointer = CFDataGetBytePtr(cfdata),
	cgimage.bitsPerPixel == 32 else {
		exit(error: "Couldn't read bitmap data")
}
let outputFileSVG = outputFile.appendingPathExtension("svg")
let svg = BinaryPixelSVG(width: cgimage.width, height: cgimage.height)
svg.addPixels { x, y in
	dataPointer[cgimage.bytesPerRow*y + x*4] == 0 ? .square : nil
}
try svg.content.write(to: outputFileSVG, atomically: true, encoding: .utf8)
