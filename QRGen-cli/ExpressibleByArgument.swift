//
//  ExpressibleByArgument.swift
//  QRGen-cli
//
//  Created by Max-Joseph on 17.01.23.
//

import Foundation
import ArgumentParser
import QRGen


typealias ArgumentEnum = ExpressibleByArgument & CaseIterable


extension Date: ExpressibleByArgument {
	public init?(argument: String) {
		guard let date = ISO8601DateFormatter().date(from: argument) else { return nil }
		self = date
	}
}

extension QRGenCode.GeneratorType: ExpressibleByArgument { }
extension QRGenCode.Style: ExpressibleByArgument { }

extension QRGenContent.WifiEncryption: ExpressibleByArgument { }
extension QRGenContent.GeoCoordinates: ExpressibleByArgument {
	public init?(argument: String) {
		let components = argument.components(separatedBy: ",")
		guard components.count == 2, let latitude = Double(components[0]), let longitude = Double(components[1]) else {
			return nil
		}
		self.init(latitude: latitude, longitude: longitude)
	}
}

extension CorrectionLevel: ExpressibleByArgument { }
