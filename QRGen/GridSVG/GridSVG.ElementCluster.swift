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
		let elements: [Element]
		
		init (from elements: inout (dict: [Int: Element], keys: [IntPoint: [Int]]), containing element: Element) {
			func neighbors(of element: Element) -> [Element] {
				var neighborElements = [Element]()
				for quandrant in element.connectingQuadrants {
					// Check neighboring positions of quadrant
					for direction in quandrant.neighbors {
						let offset = direction.offset
						let position = element.position.offsetBy(dx: offset.x, dy: offset.y)
						// Check all elements at neighboring position
						guard let keys = elements.keys[position] else { continue }
						for key in keys {
							guard let neighborElement = elements.dict[key] else { continue }
							// Check if neighborhood is mutual
							let mirroredQuadrant = quandrant.mirror(in: direction)
							if neighborElement.connectingQuadrants.contains(mirroredQuadrant) {
								elements.dict.removeValue(forKey: key)
								neighborElements.append(neighborElement)
							}
						}
					}
				}
				return neighborElements
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
			var elementsDict = (dict: [Int: Element](), keys: [IntPoint: [Int]]())
			for (index, element) in elements.enumerated() {
				elementsDict.dict[index] = element
				elementsDict.keys[element.position, default: []].append(index)
			}
			
			while let element = elementsDict.dict.popFirst()?.value {
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
