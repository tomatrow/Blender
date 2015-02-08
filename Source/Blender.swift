//
//  Blender.swift
//  Pods
//
//  Created by AJ Caldwell on 1/1/15.
//
//

import Foundation
import UIKit

/// A object that blends two images into one.
public protocol Blender : Printable, DebugPrintable  {
	typealias FilterType: Filter
	/// Warning: If this is changed, any currently blends using this image are canceled.
	var firstImage: UIImage? { get set }
	/// Warning: If this is changed, any currently blends using this image are canceled.
	var secondImage: UIImage? { get set }
	/// Identifies this blender.
	var name: String { get }
	/// Whither this blender is currently paused.
	var paused: Bool { get set }
	
	/// All filters this blender is capable of.
	var avalableProcesses: [BlendProcess] { get }
	var currentlyBlending: [FilterType] { get }
	
	/// The Blender blends the two current images using the filter settings.
	/// The success and failure blocks are called on the main thread.
	/// The three forseeable reasons for failure are: 1. Low memory and 2. Changed scource images. 3. Canceled
	/// If the blend is paused and never resumed, these blocks won't be called.
	func blend(#filter: FilterType, failure fail:((error: NSError) -> ())?, success succeed:((blend: Blend<FilterType>) -> ()))
	
	/// Cancels all blending.
	func stop()
	
	/// Cancels these currently blending filters. If these filters are not blending, nothing happens.
	func cancel(filters: [FilterType])
}


/// A blend of two images
public struct Blend<T:Filter>: Hashable {
	
	public var image: UIImage
	
	public var filter: T
	public var firstParentKey: Int
	public var secondParentKey: Int
	public var blenderName: String
	
	public var hashValue: Int {
		// We don't need to hash the image because it's identity is made from it's other values.
		return filter.hashValue ^ firstParentKey ^ secondParentKey ^ blenderName.hashValue
	}
}

public func == <T:Filter>(lhs: Blend<T>, rhs:Blend<T>) -> Bool {
	return lhs.filter == rhs.filter
		&& lhs.firstParentKey == rhs.firstParentKey
		&& lhs.secondParentKey == rhs.secondParentKey
}

public struct Intensity: Hashable {
	static public let range : Range<UInt> = Range<UInt>(start:0, end:100)
	
	public var value: UInt {
		return _value
	}
	
	private var _value : UInt
	
	public var percentage : Float {
		return Float(self.value) / 100.0
	}
	
	public init() {
		self._value = 0
	}
	
	init(_ value: UInt) {
		let tooSmall = value < Intensity.range.startIndex
		let tooBig = value > Intensity.range.endIndex
		
		if !tooSmall && !tooBig {
			self._value = value
		} else if tooSmall {
			self._value = Intensity.range.startIndex
		} else { //tooBig
			self._value = Intensity.range.endIndex
		}
	}
	
	public var hashValue: Int {
		return self.value.hashValue
	}
}

public func == (lhs: Intensity, rhs:Intensity) -> Bool {
	return lhs.value == rhs.value
}

public protocol Filter: Hashable, Printable, DebugPrintable {
	var type: BlendProcess { get }
	var intensity: Intensity { get }
}

public func == <T:Filter>(lhs:T, rhs:T) -> Bool {
	return lhs.type == rhs.type && lhs.intensity == rhs.intensity
}

public enum BlendProcess: String {
	case Dissolve = "Dissolve",
		Darken = "Darken",
		Multiply = "Multiply",
		ColorBurn = "ColorBurn",
		LinearBurn = "LinearBurn",
		Lighten = "Lighten",
		Screen = "Screen",
		ColorDodge = "ColorDodge",
		Add = "Add",
		Overlay = "Overlay",
		SoftLight = "SoftLight",
		HardLight = "HardLight",
		Difference = "Difference",
		Exclusion = "Exclusion",
		Subtract = "Subtract",
		Divide = "Divide",
		Hue = "Hue",
		Saturation = "Saturation",
		Color = "Color",
		Luminosity = "Luminosity"
	
	public static var all: [BlendProcess] {
		return [.Dissolve,
			.Darken,
			.Multiply,
			.ColorBurn,
			.LinearBurn,
			.Lighten,
			.Screen,
			.ColorDodge,
			.Add,
			.Overlay,
			.SoftLight,
			.HardLight,
			.Difference,
			.Exclusion,
			.Subtract,
			.Divide,
			.Hue,
			.Saturation,
			.Color,
			.Luminosity]
	}
}