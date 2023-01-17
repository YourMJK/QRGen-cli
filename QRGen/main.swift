//
//  main.swift
//  QRGen
//
//  Created by Max-Joseph on 08.08.22.
//

import Foundation
import ArgumentParser


typealias ArgumentEnum = ExpressibleByArgument & CaseIterable


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
			let (inputFile, inputText): (URL?, String?) = {
				switch inputType {
					case .bytes, .textFile:
						let url = (self.input == "-") ? nil : URL(fileURLWithPath: self.input)
						return (url, nil)
					case .text:
						return (nil, self.input)
				}
			}()
			let outputURL =
				outputPath.map(URL.init(fileURLWithPath:)) ??
				inputFile?.deletingPathExtension() ??
				URL(fileURLWithPath: FileManager.default.currentDirectoryPath)
			
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
			
			
			// Run program
			let qrGenCode = QRGenCode(
				outputURL: outputURL,
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
				writePNG: writePNG,
				noShapeOptimization: generalOptions.noShapeOptimization
			)
			
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
			try qrGenCode.generate(with: input)
		}
	}
}


extension Command {
	struct Content: ParsableCommand {
		static var configuration: CommandConfiguration {
			CommandConfiguration(
				abstract: "Generate different kinds of content for a QR code.",
				subcommands: [Wifi.self, Event.self, Geo.self]
			)
		}
		
		struct Wifi: ParsableCommand {
			static var configuration: CommandConfiguration {
				CommandConfiguration(
					abstract: "QR code content for WiFi network information.",
					examples: [
						.example(arguments: "\"Free Hotspot\""),
						.example(arguments: "\"Personal WiFi\" SecretPassword123 wpa"),
					]
				)
			}
			@Argument(help: ArgumentHelp("The SSID (name) of the WiFi network."))
			var ssid: String
			@Argument(help: ArgumentHelp("The password of the WiFi network."))
			var password: String?
			@Argument(help: ArgumentHelp("The encryption method used by the WiFi network. (values: \(QRGenContent.WifiEncryption.allCases.map(\.rawValue).joined(separator: " | ")))"))
			var encryption: QRGenContent.WifiEncryption = .wpa
			
			func run() throws {
				QRGenContent.wifi(ssid: ssid, password: password, encryption: encryption)
			}
		}
		
		struct Event: ParsableCommand {
			static var configuration: CommandConfiguration {
				CommandConfiguration(
					abstract: "QR code content for a calendar event in the vEvent format.",
					helpMessageLabelColumnWidth: 40,
					examples: [
						.example(arguments: "\"Birthday party\" 2023-01-01T19:00:00Z"),
						.example(arguments: "\"Birthday party\" 2023-01-01T19:00:00Z --end 2023-01-02T02:00:00Z --coordinates 45.67890,12.34567"),
						.example(arguments: "\"Birthday party\" 2023-01-01T19:00:00Z --end 2023-01-02T02:00:00Z --coordinates=-45.67890,12.34567"),
						.example(arguments: "\"Birthday party\" 2023-01-01T19:00:00Z --end 2023-01-02T02:00:00Z --location \"Via Bagnon 12\\nSan Biagio di Callalta TV\\, Italia\""),
					]
				)
			}
			
			enum ParsingError: LocalizedError {
				case dateTime(value: String)
				case coordinates(value: String)
				var errorDescription: String? {
					switch self {
						case .dateTime(let value): return "Couldn't parse time & date from \"\(value)\". Make sure it is a valid ISO-8601 date with timezone, e.g. \"2023-01-01T01:23:45Z\""
						case .coordinates(let value): return "Couldn't parse coordinates from \"\(value)\". Make sure it is in the right format (latitude,longitude), e.g. \"45.67890,12.34567\""
					}
				}
			}
			
			@Argument(help: ArgumentHelp("The name of the event."))
			var name: String
			@Argument(help: ArgumentHelp("The start time & date of the event in ISO-8601 format."))
			var start: String
			
			@Option(name: .long, help: ArgumentHelp("The end time & date of the event in ISO-8601 format."))
			var end: String?
			@Option(name: .long, help: ArgumentHelp("The location of the event, e.g. a street address."))
			var location: String?
			@Option(name: .long, help: ArgumentHelp("Geographical coordinates (latitude and longitude) of the event's location. If latitude is negative, provide the value using \"=\", e.g. \"--coordinates=-45.67890,12.34567\"", valueName: "latitude,longitude"))
			var coordinates: String?
			
			func run() throws {
				func parseDateTime(_ value: String) throws -> Date {
					let formatter = ISO8601DateFormatter()
					formatter.formatOptions = .withInternetDateTime
					guard let date = formatter.date(from: value) else {
						throw ParsingError.dateTime(value: value)
					}
					return date
				}
				func parseCoordinates(_ value: String) throws -> QRGenContent.GeoCoordinates {
					let components = value.components(separatedBy: ",")
					guard components.count == 2, let latitude = Double(components[0]), let longitude = Double(components[1]) else {
						throw ParsingError.coordinates(value: value)
					}
					return .init(latitude: latitude, longitude: longitude)
				}
				
				QRGenContent.event(
					name: name,
					start: try parseDateTime(start),
					end: try end.map { try parseDateTime($0) },
					location: location,
					coordinates: try coordinates.map { try parseCoordinates($0) }
				)
			}
		}
		
		struct Geo: ParsableCommand {
			static var configuration: CommandConfiguration {
				CommandConfiguration(
					abstract: "QR code content for geographical coordinates.",
					discussion: "To provide negative numbers, add \"--\" as the first argument.",
					examples: [
						.example(arguments: "45.67890 12.3456"),
						.example(arguments: "-- 40.71872 -73.98905 100"),
					]
				)
			}
			@Argument(help: ArgumentHelp("Latitude coordinate of the location in decimal format. If negative, add \"--\" as first argument."))
			var latitude: Double
			@Argument(help: ArgumentHelp("Longitude coordinate of the location in decimal format. If negative, add \"--\" as first argument."))
			var longitude: Double
			@Argument(help: ArgumentHelp("Altitude coordinate of the location in meters. If negative, add \"--\" as first argument."))
			var altitude: Int?
			
			func run() throws {
				//print(latitude, longitude)
				QRGenContent.geo(coordinates: .init(latitude: latitude, longitude: longitude), altitude: altitude)
			}
		}
	}
}


struct Command: ParsableCommand {
	static var configuration: CommandConfiguration {
		CommandConfiguration(
			commandName: ProgramName,
			subcommands: [Code.self, Content.self],
			//defaultSubcommand: Code.self,
			alwaysCompactUsageOptions: true
		)
	}
}

Command.main()
