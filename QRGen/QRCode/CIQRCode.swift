//
//  CIQRCode.swift
//  QRGen
//
//  Created by Max-Joseph on 15.08.22.
//

import Foundation
import CoreImage


/// A wrapper for `CoreImage`'s built-in "CIQRCodeGenerator" `CIFilter`
struct CIQRCode: QRCodeProtocol {
	let ciimage: CIImage
	let cgimage: CGImage
	let size: Int
	private let bytesPerRow: Int
	private let imageData: CFData
	private let imageDataPointer: UnsafePointer<UInt8>
	
	init?(ciimage: CIImage) {
		let cicontext = CIContext()
		guard
			let cgimage = cicontext.createCGImage(ciimage, from: ciimage.extent, format: .RGBA8, colorSpace: ciimage.colorSpace!),
			let cfdata = cgimage.dataProvider?.data,
			let cfdataPointer = CFDataGetBytePtr(cfdata),
			cgimage.bitsPerPixel == 32 else {
				return nil
		}
		self.ciimage = ciimage
		self.cgimage = cgimage
		self.size = cgimage.width
		self.bytesPerRow = cgimage.bytesPerRow
		self.imageData = cfdata
		self.imageDataPointer = cfdataPointer
	}
	
	
	subscript(x: Int, y: Int) -> Bool {
		get {
			imageDataPointer[bytesPerRow*y + x*4] == 0
		}
	}
}
