//
//  SingleSectionSnapshot.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import Foundation

/// This is a snapshot that only ever has a single section, so it's easier to use
/// and more optimized:
/// - you don't need a SectionType
///	- there are helper methods to  directly apply items
public struct SingleSectionSnapshot<ItemType: Identifiable>: SnapshotProtocol, SnapshotSectionProtocol {

	/// our section is... ourselves!
	public typealias SectionType = SingleSectionSnapshot<ItemType>

	/// creates a snapshot without any items
	public init() {
	}

	/// creates a snapshot with the given items
	public init(items: [ItemType]) {
		self.items = items
	}

	/// we need an id for `SnapshotSectionProtocol`, since we only ever have one section, we just use
	/// a constant integer.
	public let id = 0

	/// the items in this snapshot
	public var items: [ItemType] = []

	/// we are our own section
	public var sections: [SectionType] {[self]}
	public var sectionItem: SectionType {self}

	/// the number of items in this list
	public var hasItems: Bool {return items.count > 0}

	/// always 1
	public var numberOfSections: Int {return 1}

	/// always ourselves
	public func section(at index: Int) -> SectionType {return self}

	/// returns the item at the given index path. the `section` is ignored
	public func item(at indexPath: IndexPath) -> ItemType {
		return items[indexPath.row]
	}

	/// checks if the index path is valid.`section` must be 0.
	public func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
		return indexPath.section == 0 && indexPath.row < items.count
	}

	/// creates a difference between this and another snapshot.
	public func diff(with other: SingleSectionSnapshot<ItemType>) -> IndexPathDiffResult<SectionType, ItemType> {
		let diff = List.diffing(oldArray: items, newArray: other.items)
		return IndexPathDiffResult(commonSectionResults: [0: diff])
	}

	/// moves an item from one index path to another. `section` must be 0 for both index paths.
	public mutating func move(from: IndexPath, to: IndexPath) {
		let item = items.remove(at: from.row)
		items.insert(item, at: min(items.count, to.row))
	}
}
