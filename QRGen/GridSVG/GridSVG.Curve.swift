//
//  GridSVG.Curve.swift
//  QRGen
//
//  Created by Max-Joseph on 28.08.22.
//

import Foundation


extension GridSVG {
	/// A command within an SVG path node's value
	struct CurveCommand {
		let type: Character
		let parameters: [Decimal]
		
		static let close = Self(type: "Z", parameters: [])
		static func moveTo(_ point: DecimalPoint) -> Self {
			Self(type: "M", parameters: [point.x, point.y])
		}
		
		var formatted: String {
			"\(type)" + parameters.map({ "\($0)" }).joined(separator: " ")
		}
	}
}

extension GridSVG {
	/// A curve segment corresponding to an SVG path command
	typealias Curve = GridSVGCurve
}
protocol GridSVGCurve {
	var command: GridSVG.CurveCommand { get }
	var start: DecimalPoint { get }
	var end: DecimalPoint { get }
	func reverse() -> Self
}


extension GridSVG {
	/// An SVG line curve
	struct Line: Curve {
		let start: DecimalPoint
		let end: DecimalPoint
		let command: CurveCommand
		
		init(start: DecimalPoint, end: DecimalPoint) {
			self.start = start
			self.end = end
			self.command = CurveCommand(type: "L", parameters: [end.x, end.y])
		}
		
		func reverse() -> Line {
			Self.init(start: end, end: start)
		}
	}
	
	/// An SVG arc curve 
	struct Arc: Curve {
		let start: DecimalPoint
		let end: DecimalPoint
		let radius: Decimal
		let negativeCurvature: Bool
		let command: CurveCommand
		
		init(start: DecimalPoint, end: DecimalPoint, radius: Decimal, negativeCurvature: Bool) {
			self.start = start
			self.end = end
			self.radius = radius
			self.negativeCurvature = negativeCurvature
			self.command = CurveCommand(type: "A", parameters: [
				radius,
				radius,
				0,
				0,
				(negativeCurvature ? 1 : 0),
				end.x,
				end.y,
			])
		}
		
		func reverse() -> Arc {
			Self.init(start: end, end: start, radius: radius, negativeCurvature: !negativeCurvature)
		}
	}
}
