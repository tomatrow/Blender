//
//  GPUImageBlender.swift
//  Pods
//
//  Created by AJ Caldwell on 1/1/15.
//
//
//

import Foundation
import GPUImage
//import HanekeSwift
import CryptoSwift

public class GPUImageBlender: Blender {
	
	private lazy var queue: NSOperationQueue = ({
		() -> NSOperationQueue in
		var queue =  NSOperationQueue()
		queue.name = "BLNGPUImageBlender"
		queue.maxConcurrentOperationCount = 1
		return queue
	})()
	// http://stackoverflow.com/questions/24006234/what-is-the-purpose-of-willset-and-didset-in-swift
	
	private var firstIngredient: BlendIngredient?
	private var secondIngredient: BlendIngredient?
	
	init(name: String) {
		self.name = name
	}
	
	
	// MARK: BLNBlender
	
	public var firstImage: UIImage? {
		get {
			return self.firstIngredient?.image
		}
		set {
			if newValue != self.firstIngredient?.image {
				self.stop()
				self.firstIngredient = BlendIngredient(image: newValue)
			}
		}
	}
	public var secondImage: UIImage? {
		get {
			return self.secondIngredient?.image
		}
		set {
			if newValue != self.secondIngredient?.image {
				self.stop()
				self.secondIngredient = BlendIngredient(image: newValue)
			}
		}
	}
	
	public var paused: Bool {
		get {
			return self.queue.suspended
		}
		set {
			self.queue.suspended = newValue
		}
	}
	public var name: String
	
	public var avalableFilters: [BLNFilter] {
		return [BLNFilter]()
	}
	public var currentlyBlending: [BLNFilter] {
		var operations:[GPUImageBlendOperation] =  self.queue.operations as [GPUImageBlendOperation]
		return operations.map({
			(op:GPUImageBlendOperation) -> BLNFilter in
			op.filter
		})
	}
	
	public func blend(filter: BLNFilter, failure fail:((NSError?) -> ())?, success succeed:((blend: BLNBlend) -> ())) {
		if self.firstIngredient != nil && self.secondIngredient != nil {
			let op = GPUImageBlendOperation(firstPicture: self.firstIngredient!.picture, secondPicture: self.secondIngredient!.picture, filter: filter)
			
			weak var weakOp = op
			weak var weakSelf = self
			let firstKey = self.firstIngredient!.hash
			let secondKey = self.secondIngredient!.hash
			
			op.completionBlock = {
				()->() in
				if let blendedImage = op.blendedImage { // Success
					let blend = BLNBlend(image: blendedImage, filter: filter, firstParentKey: firstKey, secondParentKey: secondKey, blenderName: weakSelf!.name)
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						succeed(blend: blend)
					})
				} else if (fail != nil){ // Failure
					let error = NSError(domain: "Blending failed", code: 1, userInfo: nil)
					dispatch_async(dispatch_get_main_queue(), { () -> Void in
						fail!(error)
					})
				}
			}
			self.queue.addOperation(op)
		}
	}
	public func stop() {
		self.queue.cancelAllOperations()
	}
	public func cancel(filters: [BLNFilter]) {
		var operations: [GPUImageBlendOperation] = self.queue.operations as [GPUImageBlendOperation]
		operations.filter({
			(op: GPUImageBlendOperation) -> Bool in
			return contains(filters, (op as GPUImageBlendOperation).filter)
		}).map({$0.cancel()})
	}
}

private struct BlendIngredient {
	let image: UIImage
	lazy var picture : GPUImagePicture = GPUImagePicture(image: self.image)
	lazy var hash : Int = UIImagePNGRepresentation(self.image).md5Hash()
	init?(image: UIImage?) {
		if image == nil {
			return nil
		}
		self.image = image!
	}
}

private class GPUImageBlendOperation: NSOperation {
	private(set) var firstPicture: GPUImagePicture
	private(set) var secondPicture: GPUImagePicture
	private(set) var filter: BLNFilter
	private(set) var blendedImage: UIImage?
	
	init(firstPicture: GPUImagePicture, secondPicture: GPUImagePicture, filter:BLNFilter) {
		self.firstPicture = firstPicture
		self.secondPicture = secondPicture
		self.filter = filter
		super.init()
	}
	
	private override func main() {
		// Clarity with local vars
		if (self.cancelled) {
			return
		}
		let intensity = self.filter.intensity
		let pictures = (self.firstPicture,self.secondPicture)
		let generalFilter = self.filter.gpuImageFilter
		struct Holder {
			static var alphaFilter = GPUImageAlphaBlendFilter()
		}
		let alphaFilter = Holder.alphaFilter
		
		if (self.cancelled) {
			return
		}
		
		// Prepare filters for reuse
		let outputs:[GPUImageOutput] = [pictures.0, pictures.1, generalFilter, alphaFilter]
		outputs.map({$0.removeAllTargets()})
		
		// set intensity
		alphaFilter.mix = intensity
		
		// first pass
		if (self.cancelled) {
			return
		}
		pictures.0.addTarget(generalFilter)
		pictures.1.addTarget(generalFilter)
		pictures.1.processImage()
		
		// second pass
		if (self.cancelled) {
			return
		}
		generalFilter.addTarget(alphaFilter)
		pictures.1.addTarget(alphaFilter)
		pictures.1.processImage()
		// Final process
		if (self.cancelled) {
			return
		}
		pictures.0.processImage()
		// Save the image to be used in the completion block
		if (self.cancelled) {
			return
		}
		self.blendedImage = alphaFilter.imageFromCurrentFramebuffer()
	}
}

private extension BLNFilter {
	var gpuImageFilter: GPUImageTwoInputFilter {
		struct Holder {
			static var library = LazyFilterLibrary()
		}
		let library = Holder.library
		var filter:GPUImageTwoInputFilter
		
		switch(self) {
		case .Dissolve: filter = library.dissolve
		case .Darken: filter = library.darken
		case .Multiply: filter = library.multiply
		case .ColorBurn: filter = library.colorBurn
		case .LinearBurn: filter = library.linearBurn
		case .Lighten: filter = library.lighten
		case .Screen: filter = library.screen
		case .ColorDodge: filter = library.colordodge
		case .Add: filter = library.add
		case .Overlay: filter = library.overlay
		case .SoftLight: filter = library.softLight
		case .HardLight: filter = library.hardLight
		case .Difference: filter = library.difference
		case .Exclusion: filter = library.exclusion
		case .Subtract: filter = library.subtract
		case .Divide: filter = library.divide
		case .Hue: filter = library.hue
		case .Saturation: filter = library.saturation
		case .Color: filter = library.color
		case .Luminosity: filter = library.luminosity
		}
		return filter
	}
}

private extension NSData {
	func md5Hash() -> Int {
		let MD5Calculator = Hash.md5(self)
		let MD5Data = MD5Calculator.calculate()! // This can't be nil, I'm using self.
		let resultBytes = UnsafeMutablePointer<CUnsignedChar>(MD5Data.bytes)
		let resultEnumerator = UnsafeBufferPointer<CUnsignedChar>(start: resultBytes, count: MD5Data.length)
		let MD5String = NSMutableString()
		for c in resultEnumerator {
			MD5String.appendFormat("%02x", c)
		}
		return MD5String.integerValue
	}
}

private class LazyFilterLibrary {
	lazy var dissolve = GPUImageDissolveBlendFilter()
	lazy var darken = GPUImageDarkenBlendFilter()
	lazy var multiply = GPUImageMultiplyBlendFilter()
	lazy var colorBurn = GPUImageColorBurnBlendFilter()
	lazy var linearBurn = GPUImageLinearBurnBlendFilter()
	lazy var lighten = GPUImageLightenBlendFilter()
	lazy var screen = GPUImageScreenBlendFilter()
	lazy var colordodge = GPUImageColorDodgeBlendFilter()
	lazy var add = GPUImageAddBlendFilter()
	lazy var overlay = GPUImageOverlayBlendFilter()
	lazy var softLight = GPUImageSoftLightBlendFilter()
	lazy var hardLight = GPUImageHardLightBlendFilter()
	lazy var difference = GPUImageDifferenceBlendFilter()
	lazy var exclusion = GPUImageExclusionBlendFilter()
	lazy var subtract = GPUImageSubtractBlendFilter()
	lazy var divide = GPUImageDivideBlendFilter()
	lazy var hue = GPUImageHueBlendFilter()
	lazy var saturation = GPUImageSaturationBlendFilter()
	lazy var color = GPUImageColorBlendFilter()
	lazy var luminosity = GPUImageLuminosityBlendFilter()
}