//
//  SnapshotProtocol.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import Foundation

/// This is a snapshot protocol that can be implemented by different snapshot types
public protocol SnapshotProtocol {

	/// the snapshot protocol type for sections
	associatedtype Section: SnapshotSectionProtocol

	/// the result type of the diff call
	typealias Diff = IndexPathDiffResult<Section.SectionType, Section.ItemType>

	/// the sections in the snapshot
	var sections: [Section] { get }

	/// creates an empty snapshot
	init()

	/// true if this item has sections
	var hasItems: Bool { get }

	/// the number of sections
	var numberOfSections: Int { get }

	/// the item at the given index path
	func item(at indexPath: IndexPath) -> Section.ItemType

	/// checks if the index path is valid
	func isValidIndexPath(_ indexPath: IndexPath) -> Bool

	/// the section for the given index
	func section(at index: Int) -> Section

	/// creates a Diff between this and other
	func diff(with other: Self) -> Diff
}

extension SnapshotProtocol {
	/// helper to get a section at an index if it exists, or nil otherwise
	func sectionOrNil(at index: Int) -> Section.SectionType? {
		guard index >= 0 && index < numberOfSections else {return nil}
		return section(at: index).sectionItem
	}

	/// helper to get the items in a section at an index if the section exists, or nil otherwise
	func itemsInSectionOrNil(at index: Int) -> [Section.ItemType]? {
		guard index >= 0 && index < numberOfSections else {return nil}
		return section(at: index).items
	}

	/// item at the given index path if it exists, or nil otherwise
	func itemOrNil(at indexPath: IndexPath) -> Section.ItemType? {
		guard let items = itemsInSectionOrNil(at: indexPath.section) else {return nil}
		guard indexPath.row >= 0 && indexPath.row < items.count else {return nil}
		return items[indexPath.row]
	}
}
