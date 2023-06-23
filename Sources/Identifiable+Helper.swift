//
//  Identifiable+Helper.swift
//  Demo
//
//  Created by Andreas Verhoeven on 23/06/2023.
//

import Foundation

// this is not a good idea, since we do not own both protocols.

//extension Identifiable where Self: RawRepresentable, Self.RawValue: Hashable {
//	var id: Self.RawValue { rawValue }
//}

// Can be used for ObjC enum boxing
public struct IdentifiableWrapper<T: RawRepresentable>: Identifiable where T.RawValue: Hashable {
	public var value: T
	public var id: T.RawValue { value.rawValue }
}

// MARK: -
internal protocol AnyIdentifiableBox {
	var id: AnyHashable { get }
}

internal struct AnyIdentifiableConcreteBox<T: Identifiable>: AnyIdentifiableBox {
	internal let value: T
	public var id: AnyHashable { AnyHashable(value.id) }
}

/// This is a wrapper to compare different identifiable's as one.
public struct AnyIdentifiable: Identifiable {
	internal let box: AnyIdentifiableBox
	
	public init<T: Identifiable>(_ value: T) {
		box = AnyIdentifiableConcreteBox(value: value)
	}
	
	/// The actual id
	public var id: AnyHashable { box.id }
	
	/// Gets the value of the boxed identifiable
	public func unbox<T: Identifiable>(as: T.Type) -> T? {
		(box as? AnyIdentifiableConcreteBox<T>)?.value
	}
	
	/// Gets the value of the boxed identifiable
	public func unbox<T: Identifiable>(as: T.Type) -> T {
		(box as! AnyIdentifiableConcreteBox<T>).value
	}
}

// MARK: -

/// This can be used to identify anything that has a type and or an item that can be expressed as a string.
public struct ItemID: Hashable, Codable {
	public var type: String
	
	// swiftlint:disable:next redundant_optional_initialization
	public var identifier: String? = nil
	// swiftlint:disable:prev redundant_optional_initialization
	
	public var stringRepresentation: String { identifier.map { "\(type).\($0)" } ?? type }
}

// MARK: -

/// A protocol for sortable identifiables that can be persisted
public protocol SortableIdentifiable: Identifiable where ID: Codable {
	/// the sort order, where lower values sort before higher values
	var sortOrder: Int { get }
	
	/// if true, unsorted items will be appended at the start, otherwise at the end
	var insertsUnsortedAtStart: Bool { get }
	
	/// the string represention of this identifiable, used to save the sort order
	var stringRepresentation: String { get }
}

extension SortableIdentifiable where ID == ItemID {
	var stringRepresentation: String { id.stringRepresentation }
}

extension SortableIdentifiable where ID == String {
	var stringRepresentation: String { id }
}

// MARK: -

extension SortableIdentifiable {
	public var sortOrder: Int { return 0 }
	public var insertsUnsortedAtStart: Bool { return false }
	
	/// Sorts a list of items by the given order
	public static func sort(_ items: [Self], order: [ID]? = nil) -> [Self] {
		let indexedItems = Dictionary(items.map { ($0.id, $0) }) { _, last in last }
		var sortedItems = [Self]()
		
		let orderSet = Set(order ?? [])
		var seenIds = Set<ID>()
		order?.forEach {
			guard let item = indexedItems[$0] else { return }
			guard seenIds.contains($0) == false else { return }
			sortedItems.append(item)
			seenIds.insert($0)
		}
		
		let unsortedItems = items.filter { orderSet.contains($0.id) == false }
		unsortedItems.forEach {
			if $0.insertsUnsortedAtStartInner() == true {
				sortedItems.insert($0, at: $0.indexForAtStartSortedInsertion(in: sortedItems))
			} else {
				sortedItems.insert($0, at: $0.indexForSortedInsertion(in: sortedItems))
			}
		}
		return sortedItems
	}
	
	/// Sorts a list of items by previously saved order data
	public static func sort(_ items: [Self], orderData: Data?) -> [Self] {
		guard let data = orderData, let order = try? JSONDecoder().decode([ID].self, from: data) else { return sort(items) }
		return sort(items, order: order)
	}
	
	/// Gets the sort order data from a list of items
	public static func sortOrderData(from items: [Self]) -> Data? {
		return try? JSONEncoder().encode(items.map { $0.id })
	}
	
	internal func insertsUnsortedAtStartInner() -> Bool {
		return insertsUnsortedAtStart
	}
	
	
	internal func indexForSortedInsertion(in items: [Self]) -> Int {
		let order = sortOrder
		if let index = items.lastIndex(where: { order == $0.sortOrder }) { return index + 1 }
		if let index = items.lastIndex(where: { $0.sortOrder < order }) { return index + 1 }
		if let index = items.firstIndex(where: { $0.sortOrder > order }) { return index }
		return 0
	}
	
	internal func indexForAtStartSortedInsertion(in items: [Self]) -> Int {
		return 0
	}
}

// MARK: -

/// Conform enums to this to automatically get a `Identifiable` that works
/// for normal cases and single associated enum cases where the associated value implements
/// `Identifiable` or `Hashable`.
public protocol AutomaticEnumIdentifiable: Identifiable {
}

/// This is used to identify enum cases that conform to `AutomaticEnumIdentifiable`
public struct EnumID: Hashable {
	public var label: String
	public var value: AnyHashable?
	
	public var stringRepresentation: String { value.map { "\(label).\($0.description)" } ?? label }
}


extension AutomaticEnumIdentifiable {
	public var id: EnumID {
		let mirror = Mirror(reflecting: self)
		assert(mirror.displayStyle == .enum)
		
		guard let child = mirror.children.first else { return EnumID(label: String(describing: self)) }
		
		let label = child.label!
		if let hashable = (child.value as? (any Identifiable))?.id {
			return EnumID(label: label, value: hashable as? AnyHashable)
		} else if let hashable = child.value as? (any Hashable) {
			return EnumID(label: label, value: hashable as? AnyHashable)
		} else {
			return EnumID(label: label)
		}
	}
}
