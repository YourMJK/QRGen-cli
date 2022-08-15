//
//  QRCodeGeneratorProtocol.swift
//  QRGen
//
//  Created by Max-Joseph on 14.08.22.
//

import Foundation


protocol QRCodeGeneratorProtocol {
	associatedtype Product
	
	func generate(for data: Data) throws -> Product
	func generate(for text: String) throws -> Product
}
