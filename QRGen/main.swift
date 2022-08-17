//
//  main.swift
//  QRGen
//
//  Created by Max-Joseph on 08.08.22.
//

import Foundation
import ArgumentParser


typealias ArgumentEnum = ExpressibleByArgument & CaseIterable

struct Arguments: ParsableCommand {
	static var configuration: CommandConfiguration {
		CommandConfiguration(commandName: ProgramName, alwaysCompactUsageOptions: true)
	}
	
	@Option(name: .shortAndLong, help: ArgumentHelp("The QR code's correction level (parity)", valueName: "correction level"))
	var level: CorrectionLevel = .M
	
	@Option(name: .customLong("min"), help: ArgumentHelp("Minimum QR code version (i.e. size) to use. Not supported with \"--coreimage\" flag", valueName: "version 1-40"))
	var minVersion = 1
	
	@Option(name: .customLong("max"), help: ArgumentHelp("Maximum QR code version (i.e. size) to use. Error is thrown if the supplied input and correction level would produce a larger QR code", valueName: "version 1-40"))
	var maxVersion = 40
	
	@Option(name: .shortAndLong, help: "The QR code's style")
	var style: QRGen.Style = .standard
	
	@Option(name: [.customShort("m"), .long], help: ArgumentHelp("Shrink the QR code's individual pixels by the specified percentage. Values >50 may produce unreadable results", valueName: "percentage"))
	var pixelMargin: UInt = 0
	
	@Flag(name: [.customShort("a"), .long], help: "Apply styling to all pixels, including the QR code's position markers")
	var styleAll = false
	
	@Flag(name: .shortAndLong, help: "Additionally to the SVG output file, also create an unstyled PNG file")
	var png = false
	
	@Flag(name: .customLong("coreimage"), help: "Use built-in \"CIQRCodeGenerator\" filter from CoreImage to generate QR code instead of Nayuki implementation")
	var coreImage = false
	
	@Argument(help: ArgumentHelp("Path to file containing the QR code's data", valueName: "input file path"), transform: URL.init(fileURLWithPath:))
	var inputFile: URL
	
	@Argument(help: ArgumentHelp("Directory or file path where to write output files to (default: directory of input file)", valueName: "output path"))
	var outputPath: String?
	
	mutating func validate() throws {
		guard 0 <= pixelMargin && pixelMargin <= 100 else {
			throw ValidationError("Please specify a 'pixel margin' percentage between 0 and 100.")
		}
		guard 1 <= minVersion && minVersion <= 40, 1 <= maxVersion && maxVersion <= 40 else {
			throw ValidationError("Please specify a 'version' value between 1 and 40.")
		}
	}
}

// Parse arguments
let arguments = Arguments.parseOrExit()

let outputURL = arguments.outputPath.map(URL.init(fileURLWithPath:))

// Run program
let qrGen = QRGen(
	outputURL: outputURL ?? arguments.inputFile.deletingPathExtension(),
	generatorType: arguments.coreImage ? .coreImage : .nayuki,
	correctionLevel: arguments.level,
	minVersion: arguments.minVersion,
	maxVersion: arguments.maxVersion,
	style: arguments.style,
	pixelMargin: arguments.pixelMargin,
	ignoreSafeAreas: arguments.styleAll,
	writePNG: arguments.png
)
do {
	try qrGen.generate(withDataFrom: arguments.inputFile)
}
catch {
	exit(error: error.localizedDescription)
}
