// swift-tools-version:6.0
import PackageDescription

let package = Package(
	name: "ParseAPI",
	platforms: [
		.iOS(.v15),
		.macOS(.v12),
		.watchOS(.v8),
		.tvOS(.v15),
	],
	products: [
		.library(name: "ParseAPI", targets: ["ParseAPI"]),
	],
	targets: [
		.target(name: "ParseAPI", path: "Sources/ParseAPI"),
		.executableTarget(name: "smoke", dependencies: ["ParseAPI"], path: "smoke"),
		.testTarget(name: "ParseAPITests", dependencies: ["ParseAPI"], path: "Tests/ParseAPITests"),
	]
)
