//
//  Command.Content.Event.swift
//  QRGen-cli
//
//  Created by Max-Joseph on 17.01.23.
//

import Foundation
import ArgumentParser
import QRGen


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
		
		@Argument(help: ArgumentHelp("The name of the event."))
		var name: String
		@Argument(help: ArgumentHelp("The start time & date of the event in ISO-8601 format, e.g. \"2023-01-01T01:23:45Z\"."))
		var start: Date
		
		@Option(name: .long, help: ArgumentHelp("The end time & date of the event in ISO-8601 format, e.g. \"2023-01-01T01:23:45Z\"."))
		var end: Date?
		@Option(name: .long, help: ArgumentHelp("The location of the event, e.g. a street address."))
		var location: String?
		@Option(name: .long, help: ArgumentHelp("Geographical coordinates (latitude and longitude) of the event's location. If latitude is negative, provide the value using \"=\", e.g. \"--coordinates=-45.67890,12.34567\"", valueName: "latitude,longitude"))
		var coordinates: QRGenContent.GeoCoordinates?
		
		func run() throws {
			let content = QRGenContent.event(
				name: name,
				start: start,
				end: end,
				location: location,
				coordinates: coordinates
			)
			stdout(content, terminator: "")
		}
	}
}
