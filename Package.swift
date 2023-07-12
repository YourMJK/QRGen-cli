// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "QRGen-cli",
	products: [
		.executable(name: "QRGen-cli", targets: ["QRGen-cli"]),
	],
	dependencies: [
		.package(url: "https://github.com/YourMJK/CommandLineTool", from: "1.0.0"),
		.package(url: "https://github.com/YourMJK/QRGen", from: "1.0.0"),
	],
	targets: [
		.executableTarget(
			name: "QRGen-cli",
			dependencies: [
				"CommandLineTool",
				"QRGen",
			],
			path: "QRGen-cli"
		),
	]
)
