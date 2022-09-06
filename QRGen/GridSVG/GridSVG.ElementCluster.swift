//
//  GridSVG.ElementCluster.swift
//  QRGen
//
//  Created by Max-Joseph on 28.08.22.
//

import Foundation


extension GridSVG {
	/// A cluster of connected `Element`s
	struct ElementCluster {
		/// A mutable collection of elements with O(1) access to elements by their grid position
		class GridDictionary {
			let keys: [IntPoint: [Int]]
			var dict: [Int: Element]
			
			init (from elements: [Element]) {
				var keys = [IntPoint: [Int]]()
				var dict = [Int: Element]()
				for (index, element) in elements.enumerated() {
					dict[index] = element
					keys[element.position, default: []].append(index)
				}
				self.keys = keys
				self.dict = dict
			}
			
			func forEachElement(at position: IntPoint, _ closure: (Int, Element) throws -> Void) rethrows {
				try keys[position]?.forEach { key in
					guard let element = dict[key] else { return }
					try closure(key, element)
				}
			}
			func forEachNeighbor(of element: Element, _ closure: (Corners, Edges, Int, Element) throws -> Void) rethrows {
				for quandrant in element.connectingQuadrants {
					// Check neighboring positions of quadrant
					for direction in quandrant.neighbors {
						let offset = direction.offset
						let position = element.position.offsetBy(dx: offset.x, dy: offset.y)
						// Check all elements at neighboring position
						try forEachElement(at: position) { neighborKey, neighborElement in
							try closure(quandrant, direction, neighborKey, neighborElement)
						}
					}
				}
			}
			func forEachMutualNeighbor(of element: Element, _ closure: (Corners, Edges, Int, Element) throws -> Void) rethrows {
				try forEachNeighbor(of: element) { quandrant, direction, neighborKey, neighborElement in
					// Check if neighborhood is mutual
					let mirroredQuadrant = quandrant.mirror(in: direction)
					guard neighborElement.connectingQuadrants.contains(mirroredQuadrant) else { return }
					try closure(quandrant, direction, neighborKey, neighborElement)
				}
			}
		}
		
		
		let elements: [Element]
		
		init (from elements: inout GridDictionary, containing element: Element) {
			var clusterElements = [Element]()
			
			func addNeighbors(of element: Element) {
				// Add element to cluster
				clusterElements.append(element)
				// Find mutual neighbors
				var neighborKeys = Set<Int>()
				elements.forEachMutualNeighbor(of: element) { _, _, neighborKey, _ in
					neighborKeys.insert(neighborKey)
				}
				// Remove neighbors from search pool
				let neighborElements = neighborKeys.sorted().map { elements.dict.removeValue(forKey: $0)! }
				// Call recursively for each neighbor
				for neighborElement in neighborElements {
					addNeighbors(of: neighborElement)
				}
			}
			addNeighbors(of: element)
			
			self.elements = clusterElements
		}
		
		static func findClusters(in elements: [Element]) -> [ElementCluster] {
			var clusters = [ElementCluster]()
			var elementsDict = GridDictionary(from: elements)
			
			// Create clusters until search pool is empty, each time starting at first most element
			while let key = elementsDict.dict.keys.min() {
				let element = elementsDict.dict.removeValue(forKey: key)!
				clusters.append(ElementCluster(from: &elementsDict, containing: element))
			}
			
			return clusters
		}
	}
}

extension GridSVG.ElementCluster {
	/// The SVG paths making up the combined shape of the cluster's elements
	func combinedPaths() -> [GridSVG.Path] {
		// TODO: Implement with algorithm finding enclosing path and subtracting holes
		// FIXME: Placeholder (seems to work great for squares but not for inner corners):
		return elements.map(\.path)
	}
	
	var formatted: String {
		"<path d=\"\(combinedPaths().map(\.formatted).joined())\"/>"
	}
}
