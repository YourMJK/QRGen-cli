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
						try forEachElement(at: position) { key, neighborElement in
							try closure(quandrant, direction, key, neighborElement)
						}
					}
				}
			}
		}
		
		
		let elements: [Element]
		
		init (from elements: inout GridDictionary, containing element: Element) {
			func neighbors(of element: Element) -> [Element] {
				var neighborElementsKeys = Set<Int>()
				elements.forEachNeighbor(of: element) { quandrant, direction, key, neighborElement in
					// Check if neighborhood is mutual
					let mirroredQuadrant = quandrant.mirror(in: direction)
					guard neighborElement.connectingQuadrants.contains(mirroredQuadrant) else { return }
					neighborElementsKeys.insert(key)
				}
				return neighborElementsKeys.sorted().map { elements.dict.removeValue(forKey: $0)! }
			}
			func addNeighbors(of element: Element, to clusterElements: inout [Element]) {
				clusterElements.append(element)
				for neighborElement in neighbors(of: element) {
					addNeighbors(of: neighborElement, to: &clusterElements)
				}
			}
			
			var elements = [Element]()
			addNeighbors(of: element, to: &elements)
			self.elements = elements
		}
		
		static func findClusters(in elements: [Element]) -> [ElementCluster] {
			var clusters = [ElementCluster]()
			var elementsDict = GridDictionary(from: elements)
			
			while let key = elementsDict.dict.keys.sorted().first {
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
