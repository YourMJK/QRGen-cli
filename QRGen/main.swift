//
//  main.swift
//  QRGen
//
//  Created by Max-Joseph on 08.08.22.
//

import Foundation
import ArgumentParser


typealias ArgumentEnum = ExpressibleByArgument & CaseIterable

enum InputType: String, ArgumentEnum {
	case bytes
	case text
	case textFile
}


struct Options: ParsableCommand {
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
	
	mutating func validate() throws {
		guard 0 <= pixelMargin && pixelMargin <= 100 else {
			throw ValidationError("Please specify a 'pixel margin' percentage between 0 and 100.")
		}
		guard 1 <= minVersion && minVersion <= 40, 1 <= maxVersion && maxVersion <= 40 else {
			throw ValidationError("Please specify a 'version' value between 1 and 40.")
		}
	}
}

struct Arguments: ParsableCommand {
	static var configuration: CommandConfiguration {
		CommandConfiguration(commandName: ProgramName, alwaysCompactUsageOptions: true)
	}
	
	@OptionGroup
	var options: Options
	
	@Argument(help: ArgumentHelp("The type of input used in the <input> argument", valueName: "input type"))
	var inputType: InputType
	
	@Argument(help: ArgumentHelp("The input used to build the QR code's data. For input type \"text\" specify a string, for \"bytes\" and \"textFile\" a file path or \"-\" for stdin", valueName: "input"))
	var input: String
	
	@Argument(help: ArgumentHelp("Directory or file path where to write output files to (default: directory of input file or working directory)", valueName: "output path"))
	var outputPath: String?
}

// Parse arguments
let arguments = Arguments.parseOrExit()

let (inputFile, inputText): (URL?, String?) = {
	switch arguments.inputType {
		case .bytes, .textFile:
			let url = (arguments.input == "-") ? nil : URL(fileURLWithPath: arguments.input)
			return (url, nil)
		case .text:
			return (nil, arguments.input)
	}
}()
let outputURL =
	arguments.outputPath.map(URL.init(fileURLWithPath:)) ??
	inputFile?.deletingPathExtension() ??
	URL(fileURLWithPath: FileManager.default.currentDirectoryPath)


// Run program
let qrGen = QRGen(
	outputURL: outputURL,
	generatorType: arguments.options.coreImage ? .coreImage : .nayuki,
	correctionLevel: arguments.options.level,
	minVersion: arguments.options.minVersion,
	maxVersion: arguments.options.maxVersion,
	style: arguments.options.style,
	pixelMargin: arguments.options.pixelMargin,
	ignoreSafeAreas: arguments.options.styleAll,
	writePNG: arguments.options.png
)

do {
	let input: QRGen.Input = try {
		switch arguments.inputType {
			case .bytes:
				guard let inputFile = inputFile else {
					let stdinData = FileHandle.standardInput.availableData
					return .data(stdinData)
				}
				return .data(try Data(contentsOf: inputFile))
				
			case .textFile:
				guard let inputFile = inputFile else {
					let stdinData = FileHandle.standardInput.availableData
					guard let stdinText = String(data: stdinData, encoding: .utf8) else {
						exit(error: "Couldn't decode data from stdin as UTF-8 text")
					}
					return .text(stdinText)
				}
				return .text(try String(contentsOf: inputFile))
				
			case .text:
				return .text(inputText!)
		}
	}()
	try qrGen.generate(with: input)
}
catch {
	exit(error: error.localizedDescription)
}
