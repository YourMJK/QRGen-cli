//
//  main.swift
//  QRGen
//
//  Created by Max-Joseph on 08.08.22.
//

import Foundation
import CoreImage


let correctionLevels = ["L","M","Q","H"]

guard CommandLine.arguments.count > 3 else {
	exit(error: "Usage:  \(ProgramName) <input data file> (\(correctionLevels.joined(separator: " | "))) <output directory>", noPrefix: true)
}


// Read data from file
let inputFile = URL(fileURLWithPath: CommandLine.arguments[1])
let inputData = try Data(contentsOf: inputFile)

// Parse correction level argument
let correctionLevel = CommandLine.arguments[2]
guard correctionLevels.contains(correctionLevel) else { exit(error: "Invalid correction level \"\(correctionLevel)\"") }

// Check output directory exists
let outputDir = URL(fileURLWithPath: CommandLine.arguments[3])
var isDirectory: ObjCBool = false
guard FileManager.default.fileExists(atPath: outputDir.path, isDirectory: &isDirectory) && isDirectory.boolValue else {
	exit(error: "No such output directory \"\(outputDir.path)\"")
}


// Create CoreImage filter
let filter = CIFilter(name: "CIQRCodeGenerator")!
filter.setValue(inputData, forKey: "inputMessage")
filter.setValue(correctionLevel, forKey: "inputCorrectionLevel")

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
	dataPointer[cgimage.bytesPerRow*y + x*4] == 0
}
try svg.content.write(to: outputFileSVG, atomically: true, encoding: .utf8)
