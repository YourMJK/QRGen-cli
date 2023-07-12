//
//  Command.swift
//  QRGen-cli
//
//  Created by Max-Joseph on 17.01.23.
//

import Foundation
import CommandLineTool
import ArgumentParser


@main
struct Command: ParsableCommand {
	static var configuration: CommandConfiguration {
		CommandConfiguration(
			commandName: executableName,
			version: "1.3.3",
			subcommands: [Code.self, Content.self],
			//defaultSubcommand: Code.self,
			alwaysCompactUsageOptions: true
		)
	}
}
