//
//  Command.Content.Geo.swift
//  QRGen
//
//  Created by Max-Joseph on 17.01.23.
//

import Foundation
import ArgumentParser


extension Command.Content {
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
			QRGenContent.geo(coordinates: .init(latitude: latitude, longitude: longitude), altitude: altitude)
		}
	}
}
