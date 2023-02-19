// swift-tools-version: 5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
	name: "QRGen-cli",
	products: [
		.executable(name: "QRGen-cli", targets: ["QRGen-cli"]),
	],
	dependencies: [
		.package(url: "https://github.com/YourMJK/swift-argument-parser", branch: "main"),
		.package(url: "https://github.com/YourMJK/QRGen", branch: "module-cli-separation"),
	],
	targets: [
		.executableTarget(
			name: "QRGen-cli",
			dependencies: [
				.product(name: "ArgumentParser", package: "swift-argument-parser"),
				"QRGen",
			],
			path: "QRGen-cli"
		),
	]
)
