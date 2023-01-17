//
//  Command.Content.Event.swift
//  QRGen
//
//  Created by Max-Joseph on 17.01.23.
//

import Foundation
import ArgumentParser


extension Command.Content {
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
}
