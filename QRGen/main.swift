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
		CommandConfiguration(commandName: ProgramName)
	}
	
	@Option(name: .shortAndLong, help: ArgumentHelp("The QR code's correction level (parity)", valueName: "correction level"))
	var level: CorrectionLevel = .M
	
	@Option(name: .shortAndLong, help: "The QR code's style")
	var style: QRGen.Style = .standard
	
	@Option(name: [.customShort("m"), .long], help: ArgumentHelp("Shrink the QR code's individual pixels by the specified percentage. Values >50 may produce unreadable results", valueName: "percentage"))
	var pixelMargin: UInt = 0
	
	@Flag(name: [.customShort("a"), .long], help: "Apply styling to all pixels, including the QR code's position markers")
	var styleAll = false
	
	@Flag(name: .shortAndLong, help: "Additionally to the SVG output file, also create an unstyled PNG file")
	var png = false
	
	@Argument(help: ArgumentHelp("File containing the QR code's data", valueName: "input data file"), transform: URL.init(fileURLWithPath:))
	var inputFile: URL
	
	@Argument(help: ArgumentHelp("Directory to write output files to", valueName: "output directory"), transform: URL.init(fileURLWithPath:))
	var outputDir: URL
	
	mutating func validate() throws {
		guard 0 <= pixelMargin && pixelMargin <= 100 else {
			throw ValidationError("Please specify a 'pixel margin' percentage between 0 and 100.")
		}
	}
}

// Parse arguments
let arguments = Arguments.parseOrExit()

// Generate QR
let qrGen = QRGen(
	outputDir: arguments.outputDir,
	outputFileName: arguments.inputFile.deletingPathExtension().lastPathComponent,
	correctionLevel: arguments.level,
	style: arguments.style,
	pixelMargin: arguments.pixelMargin,
	ignoreSafeAreas: arguments.styleAll,
	writePNG: arguments.png
)
try qrGen.generate(withDataFrom: arguments.inputFile)
