//
//  Command.Content.Wifi.swift
//  QRGen
//
//  Created by Max-Joseph on 17.01.23.
//

import Foundation
import ArgumentParser
import QRGen


extension Command.Content {
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
			let content = QRGenContent.wifi(ssid: ssid, password: password, encryption: encryption)
			stdout(content, terminator: "")
		}
	}
}
