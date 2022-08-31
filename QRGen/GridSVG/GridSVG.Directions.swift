//
//  GridSVG.Directions.swift
//  QRGen
//
//  Created by Max-Joseph on 28.08.22.
//

import Foundation


extension GridSVG {
	typealias DirectionsOptionSet = GridSVGDirectionsOptionSet
	
	/// Directions in a grid with +x == right and +y == bottom
	struct Directions: DirectionsOptionSet {
		typealias Neighbors = Self
		let rawValue: UInt8
		
		static let top         = Self(rawValue: 1 << 0)
		static let topRight    = Self(rawValue: 1 << 1)
		static let right       = Self(rawValue: 1 << 2)
		static let bottomRight = Self(rawValue: 1 << 3)
		static let bottom      = Self(rawValue: 1 << 4)
		static let bottomLeft  = Self(rawValue: 1 << 5)
		static let left        = Self(rawValue: 1 << 6)
		static let topLeft     = Self(rawValue: 1 << 7)
		
		static let all: Self = [.allCardinal, .allOrdinal]
		static let allCardinal: Self = [.top, .right, .bottom, .left]
		static let allOrdinal: Self = [.topRight, .bottomRight, .bottomLeft, .topLeft]
	}
	
	struct Edges: DirectionsOptionSet {
		typealias Neighbors = Corners
		let rawValue: UInt8
		
		static let top    = Self(.top)
		static let right  = Self(.right)
		static let bottom = Self(.bottom)
		static let left   = Self(.left)
		
		static let all = Self(.allCardinal)
	}
	struct Corners: DirectionsOptionSet {
		typealias Neighbors = Edges
		let rawValue: UInt8
		
		static let topRight    = Self(.topRight)
		static let bottomRight = Self(.bottomRight)
		static let bottomLeft  = Self(.bottomLeft)
		static let topLeft     = Self(.topLeft)
		
		static let all = Self(.allOrdinal)
	}
}


protocol GridSVGDirectionsOptionSet: Sequence, OptionSet where RawValue == UInt8 {
	associatedtype Neighbors: GridSVGDirectionsOptionSet
	static var all: Self { get }
	
	init(_ directions: GridSVG.Directions)
	var directions: GridSVG.Directions { get }
	
	/// All directions rotated clockwise by the specified number of 45° steps
	func rotate(eights: Int) -> Self
	
	/// All directions rotated by 180°
	var opposite: Self { get }
	
	/// All the directions to the right and left of the current directions
	var neighbors: Neighbors { get }
	
	/// The offset to the grid coordinate this direction points to
	var offset: (x: Int, y: Int) { get }
}
extension GridSVGDirectionsOptionSet {
	init(_ directions: GridSVG.Directions) {
		self.init(rawValue: directions.rawValue)
	}
	var directions: GridSVG.Directions {
		GridSVG.Directions(rawValue: rawValue)
	}
	
	func rotate(eights: Int) -> Self {
		let shift = eights & 0b111
		return Self(rawValue: rawValue << shift | rawValue >> (8-shift))
	}
	
	var opposite: Self {
		rotate(eights: 4)
	}
	
	var neighbors: Neighbors {
		Neighbors(rawValue: rotate(eights: 1).rawValue | rotate(eights: -1).rawValue)
	}
	
	var offset: (x: Int, y: Int) {
		switch directions {
			case .top:         return ( 0,-1)
			case .topRight:    return (+1,-1)
			case .right:       return (+1, 0)
			case .bottomRight: return (+1,+1)
			case .bottom:      return ( 0,+1)
			case .bottomLeft:  return (-1,+1)
			case .left:        return (-1, 0)
			case .topLeft:     return (-1,-1)
			default: preconditionFailure("Offset is unavailable for multiple directions")
		}
	}
}

struct GridSVGDirectionsOptionSetIterator<Element: GridSVGDirectionsOptionSet>: IteratorProtocol {
	private var remainingBits: UInt8
	private var mask: UInt8 = 1
	
	init(_ element: Element) {
		self.remainingBits = element.rawValue
	}
	
	mutating func next() -> Element? {
		while remainingBits != 0 {
			defer { mask <<= 1 }
			if remainingBits & mask != 0 {
				remainingBits ^= mask
				return Element(rawValue: mask)
			}
		}
		return nil
	}
}
extension GridSVGDirectionsOptionSet {
	func makeIterator() -> GridSVGDirectionsOptionSetIterator<Self> {
		return GridSVGDirectionsOptionSetIterator(self)
	}
}
