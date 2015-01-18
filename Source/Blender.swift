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
public protocol Blender {
	
	/// Warning: If this is changed, any currently blends using this image are canceled.
	var firstImage: UIImage? { get set }
	/// Warning: If this is changed, any currently blends using this image are canceled.
	var secondImage: UIImage? { get set }
	/// Identifies this blender.
	var name: String { get }
	/// Whither this blender is currently paused.
	var paused: Bool { get set }
	
	/// All filters this blender is capable of.
	var avalableFilters: [BLNFilter] { get }
	var currentlyBlending: [BLNFilter] { get }
	
	/// The Blender blends the two current images using the filter settings.
	/// The success and failure blocks are called on the main thread.
	/// The three forseeable reasons for failure are: 1. Low memory and 2. Changed scource images. 3. Canceled
	/// If the blend is paused and never resumed, these blocks won't be called.
	func blend(filter: BLNFilter, failure fail:((NSError?) -> ())?, success succeed:((blend: BLNBlend) -> ()))
	
	/// Cancels all blending.
	func stop()
	
	/// Cancels these currently blending filters. If these filters are not blending, nothing happens.
	func cancel(filters: [BLNFilter])
	
}


/// A blend of two images
public struct BLNBlend: Hashable {
	var image: UIImage
	
	var filter: BLNFilter
	var firstParentKey: Int
	var secondParentKey: Int
	var blenderName: String
	
	public var hashValue: Int {
		// We don't need to hash the image because it's identity is made from it's other values.
		return filter.hashValue ^ firstParentKey ^ secondParentKey ^ blenderName.hashValue
	}
}

public func == (lhs: BLNBlend, rhs:BLNBlend) -> Bool {
	return lhs.filter == rhs.filter
		&& lhs.firstParentKey == rhs.firstParentKey
		&& lhs.secondParentKey == rhs.secondParentKey
}

/// A percentage on [0,1]
public typealias Intensity = CGFloat

/// A specific filter with a name and intensity attached to it
public enum BLNFilter: Hashable {
	case    Dissolve(Intensity),
			Darken(Intensity),
			Multiply(Intensity),
			ColorBurn(Intensity),
			LinearBurn(Intensity),
			Lighten(Intensity),
			Screen(Intensity),
			ColorDodge(Intensity),
			Add(Intensity),
			Overlay(Intensity),
			SoftLight(Intensity),
			HardLight(Intensity),
			Difference(Intensity),
			Exclusion(Intensity),
			Subtract(Intensity),
			Divide(Intensity),
			Hue(Intensity),
			Saturation(Intensity),
			Color(Intensity),
			Luminosity(Intensity)
	
	func name() -> String {
		var name: String
		switch self {
			case .Dissolve: name = "Dissolve"
			case .Darken: name = "Darken"
			case .Multiply: name = "Multiply"
			case .ColorBurn: name = "ColorBurn"
			case .LinearBurn: name = "LinearBurn"
			case .Lighten: name = "Lighten"
			case .Screen: name = "Screen"
			case .ColorDodge: name = "ColorDodge"
			case .Add: name = "Add"
			case .Overlay: name = "Overlay"
			case .SoftLight: name = "SoftLight"
			case .HardLight: name = "HardLight"
			case .Difference: name = "Difference"
			case .Exclusion: name = "Exclusion"
			case .Subtract: name = "Subtract"
			case .Divide: name = "Divide"
			case .Hue: name = "Hue"
			case .Saturation: name = "Saturation"
			case .Color: name = "Color"
			case .Luminosity: name = "Luminosity"
			default: name = "Unknown"
		}
		return name
	}
	
	var intensity: Intensity {
		switch(self) {
			case .Dissolve(let a): return a
			case .Darken(let a): return a
			case .Multiply(let a): return a
			case .ColorBurn(let a): return a
			case .LinearBurn(let a): return a
			case .Lighten(let a): return a
			case .Screen(let a): return a
			case .ColorDodge(let a): return a
			case .Add(let a): return a
			case .Overlay(let a): return a
			case .SoftLight(let a): return a
			case .HardLight(let a): return a
			case .Difference(let a): return a
			case .Exclusion(let a): return a
			case .Subtract(let a): return a
			case .Divide(let a): return a
			case .Hue(let a): return a
			case .Saturation(let a): return a
			case .Color(let a): return a
			case .Luminosity(let a): return a
		}
	}
	
	/// MARK: hashable
	public var hashValue: Int {
		switch(self) {
		default:
			return self.intensity.hashValue ^ self.name().hashValue
		}
	}
}

// MARK: Equatable
/// BLNFilters' must have the same type and same associated Intensity value.
// This is the best way to equate them
public func == (lhs: BLNFilter, rhs:BLNFilter) -> Bool {
	switch(lhs,rhs) {
		case (.Dissolve(let a), .Dissolve(let b)) where a == b: return true
		case (.Darken(let a), .Darken(let b)) where a == b: return true
		case (.Multiply(let a), .Multiply(let b)) where a == b: return true
		case (.ColorBurn(let a), .ColorBurn(let b)) where a == b: return true
		case (.LinearBurn(let a), .LinearBurn(let b)) where a == b: return true
		case (.Lighten(let a), .Lighten(let b)) where a == b: return true
		case (.Screen(let a), .Screen(let b)) where a == b: return true
		case (.ColorDodge(let a), .ColorDodge(let b)) where a == b: return true
		case (.Add(let a), .Add(let b)) where a == b: return true
		case (.Overlay(let a), .Overlay(let b)) where a == b: return true
		case (.SoftLight(let a), .SoftLight(let b)) where a == b: return true
		case (.HardLight(let a), .HardLight(let b)) where a == b: return true
		case (.Difference(let a), .Difference(let b)) where a == b: return true
		case (.Exclusion(let a), .Exclusion(let b)) where a == b: return true
		case (.Subtract(let a), .Subtract(let b)) where a == b: return true
		case (.Divide(let a), .Divide(let b)) where a == b: return true
		case (.Hue(let a), .Hue(let b)) where a == b: return true
		case (.Saturation(let a), .Saturation(let b)) where a == b: return true
		case (.Color(let a), .Color(let b)) where a == b: return true
		case (.Luminosity(let a), .Luminosity(let b)) where a == b: return true
		default: return false
	}
}
