//
//  GridSVG.Path.swift
//  QRGen
//
//  Created by Max-Joseph on 28.08.22.
//

import Foundation


extension GridSVG {
	/// A connected string of `Curve`s forming a closed path
	struct Path {
		var curves: [Curve]
		var commands: [CurveCommand] {
			guard !curves.isEmpty else { return [] }
			var commands = [CurveCommand.moveTo(curves.first!.start)]
			commands.append(contentsOf: curves.map(\.command))
			commands.append(.close)
			return commands
		}
		var formatted: String {
			commands.map(\.formatted).joined()
		}
	}
}

extension GridSVG {
	class PathBuilder {
		let start: DecimalPoint
		private(set) var curves: [Curve] = []
		var cursor: DecimalPoint {
			curves.last?.end ?? start
		}
		
		init(start: DecimalPoint) {
			self.start = start
		}
		
		func line(to end: DecimalPoint) {
			curves.append(GridSVG.Line(start: cursor, end: end))
		}
		func arc(to end: DecimalPoint, radius: Decimal, negativeCurvature: Bool) {
			curves.append(GridSVG.Arc(start: cursor, end: end, radius: radius, negativeCurvature: negativeCurvature))
		}
		func endPath(close: Bool) -> Path {
			if close {
				line(to: start)
			}
			return Path(curves: curves)
		}
	}
}


extension GridSVG.Path {
	/// A new square shape
	static func square(origin: DecimalPoint, size: Decimal) -> Self {
		let p0 = origin
		let p1 = origin.offsetBy(dx: size, dy: 0)
		let p2 = origin.offsetBy(dx: size, dy: size)
		let p3 = origin.offsetBy(dx: 0, dy: size)
		let curves = [
			GridSVG.Line(start: p0, end: p1),
			GridSVG.Line(start: p1, end: p2),
			GridSVG.Line(start: p2, end: p3),
			GridSVG.Line(start: p3, end: p0)
		]
		return Self(curves: curves)
	}
}

extension GridSVG.Path {
	/// A new square shape with rounded corners
	static func roundedSquare(origin: DecimalPoint, size: Decimal, roundedCorners: GridSVG.Corners, cornerRadius: Decimal) -> Self {
		let roundedSquareCoordinates = Self.roundedSquareCoordinates(origin: origin, size: size, roundedCorners: roundedCorners, cornerRadius: cornerRadius)
		let needsEdgeLine = cornerRadius != 1
		var pathBuilder: GridSVG.PathBuilder?
		
		for coordinates in roundedSquareCoordinates {
			if pathBuilder == nil {
				pathBuilder = GridSVG.PathBuilder(start: coordinates.startPos)
			} else if needsEdgeLine {
				pathBuilder!.line(to: coordinates.startPos)
			}
			if roundedCorners.contains(coordinates.corner) {
				pathBuilder!.arc(to: coordinates.endPos, radius: coordinates.radius, negativeCurvature: true)
			} else {
				pathBuilder!.line(to: coordinates.cornerPos)
				pathBuilder!.line(to: coordinates.endPos)
			}
		}
		
		return pathBuilder!.endPath(close: needsEdgeLine)
	}
	
	/// Shapes for the corners of an inverted rounded square
	static func invertedRoundedSquare(origin: DecimalPoint, size: Decimal, roundedCorners: GridSVG.Corners, cornerRadius: Decimal) -> [(path: Self, corner: GridSVG.Corners)] {
		guard !roundedCorners.isEmpty else {
			return []
		}
		let roundedSquareCoordinates = Self.roundedSquareCoordinates(origin: origin, size: size, roundedCorners: roundedCorners, cornerRadius: cornerRadius)
		var paths = [(Self, GridSVG.Corners)]()
		
		for coordinates in roundedSquareCoordinates {
			guard roundedCorners.contains(coordinates.corner) else { continue }
			let pathBuilder = GridSVG.PathBuilder(start: coordinates.startPos)
			pathBuilder.arc(to: coordinates.endPos, radius: coordinates.radius, negativeCurvature: true)
			pathBuilder.line(to: coordinates.cornerPos)
			paths.append((pathBuilder.endPath(close: true), coordinates.corner))
		}
		
		return paths
	}
	
	private typealias CornerCoordinates = (corner: GridSVG.Corners, radius: Decimal, cornerPos: DecimalPoint, startPos: DecimalPoint, endPos: DecimalPoint)
	private static func roundedSquareCoordinates(origin: DecimalPoint, size: Decimal, roundedCorners: GridSVG.Corners, cornerRadius: Decimal) -> [CornerCoordinates] {
		let radius = cornerRadius * size / 2
		var result = [CornerCoordinates]()
		typealias DecimalVector = (x: Decimal, y: Decimal)
		func cornerPath(for corner: GridSVG.Corners, at pointOffset: DecimalVector, from start: DecimalVector, to end: DecimalVector) {
			let cornerPos = origin.offsetBy(dx: size*pointOffset.x, dy: size*pointOffset.y)
			let startPos = cornerPos.offsetBy(dx: radius*start.x, dy: radius*start.y)
			let endPos = cornerPos.offsetBy(dx: radius*end.x, dy: radius*end.y)
			result.append((corner: corner, radius: radius, cornerPos: cornerPos, startPos: startPos, endPos: endPos))
		}
		cornerPath(for: .topLeft,     at: (0,0), from: ( 0,+1), to: (+1, 0))
		cornerPath(for: .topRight,    at: (1,0), from: (-1, 0), to: ( 0,+1))
		cornerPath(for: .bottomRight, at: (1,1), from: ( 0,-1), to: (-1, 0))
		cornerPath(for: .bottomLeft,  at: (0,1), from: (+1, 0), to: ( 0,-1))
		return result
	}
}
