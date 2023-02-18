//
//  Command.Code.swift
//  QRGen-cli
//
//  Created by Max-Joseph on 17.01.23.
//

import Foundation
import ArgumentParser
import QRGen
#if canImport(AppKit)
import CoreImage
#endif


extension Command {
	struct Code: ParsableCommand {
		static var configuration: CommandConfiguration {
			CommandConfiguration(
				abstract: "Generate an (optionally stylized) QR code image from a given input.",
				helpMessageLabelColumnWidth: 40,
				alwaysCompactUsageOptions: true,
				examples: [
					.example(arguments: "text \"http://example.org\" example"),
					.example(arguments: "-l Q textFile data.txt"),
					.example(arguments: "--level L -s liquidDots -r 80 -a bytes event.ics"),
				]
			)
		}
		
		enum ParsingError: LocalizedError {
			case stdinEncoding
			var errorDescription: String? {
				switch self {
					case .stdinEncoding: return "Couldn't decode data from stdin as UTF-8 text"
				}
			}
		}
		
		enum InputType: String, ArgumentEnum {
			case text
			case textFile
			case bytes
		}
		
		struct GeneratorOptions: ParsableCommand {
			@Option(name: .shortAndLong, help: ArgumentHelp("The QR code's correction level (parity).", valueName: "correction level"))
			var level: CorrectionLevel = .M
			
			@Option(name: .customLong("min"), help: ArgumentHelp("Minimum QR code version (i.e. size) to use. Not supported with \"--coreimage\" flag.", valueName: "version 1-40"))
			var minVersion = 1
			
			@Option(name: .customLong("max"), help: ArgumentHelp("Maximum QR code version (i.e. size) to use. Error is thrown if the supplied input and correction level would produce a larger QR code.", valueName: "version 1-40"))
			var maxVersion = 40
			
			@Flag(name: .shortAndLong, help: ArgumentHelp("Try to reduce length of QR code data by splitting text input into segments of different encodings. Not supported with \"--coreimage\" flag."))
			var optimize = false
			
			@Flag(name: .long, help: ArgumentHelp("Strictly conform to the QR code specification when encoding text. Might increase length of QR code data. No effect with \"--coreimage\" flag."))
			var strict = false
			
			mutating func validate() throws {
				guard 1 <= minVersion && minVersion <= 40, 1 <= maxVersion && maxVersion <= 40 else {
					throw ValidationError("Please specify a 'version' value between 1 and 40.")
				}
			}
		}
		
		struct StyleOptions: ParsableCommand {
			@Option(name: .shortAndLong, help: "The QR code's style.")
			var style: QRGenCode.Style = .standard
			
			@Option(name: [.customShort("m"), .long], help: ArgumentHelp("Shrink the QR code's individual pixels by the specified percentage. Values >50 may produce unreadable results.", valueName: "percentage"))
			var pixelMargin: UInt = 0
			
			@Option(name: [.customShort("r"), .long], help: ArgumentHelp("Specify corner radius as a percentage of half pixel size. Ignored for \"standard\" style.", valueName: "percentage"))
			var cornerRadius: UInt = 100
			
			@Flag(name: [.customShort("a"), .long], help: "Apply styling to all pixels, including the QR code's position markers.")
			var styleAll = false
			
			mutating func validate() throws {
				guard 0 <= pixelMargin && pixelMargin <= 100 else {
					throw ValidationError("Please specify a 'pixel margin' percentage between 0 and 100.")
				}
				guard 0 <= cornerRadius && cornerRadius <= 100 else {
					throw ValidationError("Please specify a 'corner radius' percentage between 0 and 100.")
				}
			}
		}
		
		struct GeneralOptions: ParsableCommand {
			#if canImport(AppKit)
			@Flag(name: .shortAndLong, help: "Additionally to the SVG output file, also create an unstyled PNG file.")
			var png = false
			#endif
			
			#if canImport(CoreImage)
			@Flag(name: .customLong("coreimage"), help: "Use built-in \"CIQRCodeGenerator\" filter from CoreImage to generate QR code instead of Nayuki implementation.")
			var coreImage = false
			#endif
			
			@Flag(name: .long, help: "Add one shape per pixel to the SVG instead of combining touching shapes. This may result in anti-aliasing artifacts (thin lines) between neighboring pixels when viewing the SVG!")
			var noShapeOptimization = false
		}
		
		
		@OptionGroup(title: "Generator Options")
		var generatorOptions: GeneratorOptions
		
		@OptionGroup(title: "Style Options")
		var styleOptions: StyleOptions
		
		@OptionGroup
		var generalOptions: GeneralOptions
		
		@Argument(help: ArgumentHelp("The type of input used in the <input> argument. (values: \(InputType.allCases.map(\.rawValue).joined(separator: " | ")))", valueName: "input type"))
		var inputType: InputType
		
		@Argument(help: ArgumentHelp("The input used to build the QR code's data. For input type \"\(InputType.text)\" specify a string, for \"\(InputType.textFile)\" and \"\(InputType.bytes)\" a file path or \"-\" for stdin.", valueName: "input"))
		var input: String
		
		@Argument(help: ArgumentHelp("Directory or file path where to write output files to. (default: directory of input file or working directory)", valueName: "output path"))
		var outputPath: String?
		
		
		func run() throws {
			#if canImport(CoreImage)
			let generatorType: QRGenCode.GeneratorType = generalOptions.coreImage ? .coreImage : .nayuki
			#else
			let generatorType: QRGenCode.GeneratorType = .nayuki
			#endif
			#if canImport(AppKit)
			let writePNG = generalOptions.png
			#else
			let writePNG = false
			#endif
			
			
			// Determine input
			let (inputFile, inputText): (URL?, String?) = {
				switch inputType {
					case .bytes, .textFile:
						let url = (self.input == "-") ? nil : URL(fileURLWithPath: self.input)
						return (url, nil)
					case .text:
						return (nil, self.input)
				}
			}()
			
			let input: QRGenCode.Input = try {
				switch inputType {
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
								throw ParsingError.stdinEncoding
							}
							return .text(stdinText)
						}
						return .text(try String(contentsOf: inputFile))
						
					case .text:
						return .text(inputText!)
				}
			}()
			
			
			// Generate output file URLs
			let outputURL =
				outputPath.map(URL.init(fileURLWithPath:)) ??
				inputFile?.deletingPathExtension() ??
				URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
			
			let suffix = "QR-\(generatorOptions.level)"
			var suffixStyled = suffix
			
			func addNameTag(_ tag: String, _ condition: Bool) {
				guard condition else { return }
				suffixStyled += "-" + tag
			}
			addNameTag("\(styleOptions.style)", styleOptions.style != .standard)
			addNameTag("m\(styleOptions.pixelMargin)", styleOptions.pixelMargin != 0)
			addNameTag("r\(styleOptions.cornerRadius)", styleOptions.cornerRadius != 100 && styleOptions.style != .standard)
			addNameTag("all", styleOptions.styleAll)
			#if canImport(CoreImage)
			addNameTag("CI", generalOptions.coreImage)
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
			let pngURL = baseURL.appendingPathComponent(name).appendingPathExtension("png")
			let svgURL = baseURL.appendingPathComponent(nameStyled).appendingPathExtension("svg")
			
			
			// Generate QR code
			let qrGenCode = QRGenCode(
				generatorType: generatorType,
				correctionLevel: generatorOptions.level,
				minVersion: generatorOptions.minVersion,
				maxVersion: generatorOptions.maxVersion,
				optimize: generatorOptions.optimize,
				strict: generatorOptions.strict,
				style: styleOptions.style,
				pixelMargin: styleOptions.pixelMargin,
				cornerRadius: styleOptions.cornerRadius,
				ignoreSafeAreas: styleOptions.styleAll,
				noShapeOptimization: generalOptions.noShapeOptimization
			)
			let qrCode = try qrGenCode.generate(with: input)
			
			
			// Create PNG file (1px scale)
			#if canImport(AppKit)
			if writePNG {
				let cicontext = CIContext()
				let ciimage = qrGenCode.createRasterImage(qrCode: qrCode)
				try cicontext.writePNGRepresentation(of: ciimage, to: pngURL, format: .RGBA8, colorSpace: ciimage.colorSpace!)
			}
			#endif
			
			// Create SVG file
			let svg = qrGenCode.createSVG(qrCode: qrCode)
			try svg.write(to: svgURL, atomically: true, encoding: .utf8)
		}
	}
}
