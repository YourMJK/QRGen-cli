//
//  QRCodeGeneratorProtocol.swift
//  QRGen
//
//  Created by Max-Joseph on 14.08.22.
//

import Foundation


protocol QRCodeGeneratorProtocol {
	associatedtype Product: QRCodeProtocol
	
	init(correctionLevel: CorrectionLevel, minVersion: Int, maxVersion: Int)
	
	func generate(for data: Data) throws -> Product
	func generate(for text: String, optimize: Bool) throws -> Product
}
