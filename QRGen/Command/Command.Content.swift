//
//  Command.Content.swift
//  QRGen
//
//  Created by Max-Joseph on 17.01.23.
//

import Foundation
import ArgumentParser


extension Command {
	struct Content: ParsableCommand { 
		static var configuration: CommandConfiguration {
			CommandConfiguration(
				abstract: "Generate different kinds of content for a QR code.",
				subcommands: [Wifi.self, Event.self, Geo.self]
			)
		}
	}
}
