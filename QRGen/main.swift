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
	var level: QRGen.CorrectionLevel = .M
	
	@Option(name: .shortAndLong, help: "The QR code's style")
	var style: QRGen.Style = .standard
	
	@Argument(help: ArgumentHelp("File containing the QR code's data", valueName: "input data file"), transform: URL.init(fileURLWithPath:))
	var inputFile: URL
	
	@Argument(help: ArgumentHelp("Directory to write output files to (default: directory of input file)", valueName: "output directory"))
	var outputDirPath: String?
}

// Parse arguments
let arguments = Arguments.parseOrExit()

// Generate QR
let qrGen = QRGen(
	inputFile: arguments.inputFile,
	outputDir: arguments.outputDirPath.map(URL.init(fileURLWithPath:)) ?? arguments.inputFile.deletingLastPathComponent(),
	correctionLevel: arguments.level,
	style: arguments.style
)
try qrGen.run()
