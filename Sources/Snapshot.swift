//
//  Snapshot.swift
//  AveDataSource
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import Foundation

/// This is a snapshot for multiple sections.
///
///
/// Each section is associated with a "Section" object that should uniquely identify the section.
/// Each item in a section should be associated with an "Item" that uniquely identifies the item
/// within the section as well.
public struct Snapshot<SectionType: Identifiable, ItemType: Identifiable>: SnapshotProtocol {

	/// holds data for each section
	public struct Section: SnapshotSectionProtocol {
		public var sectionItem: SectionType
		public var items: [ItemType]
		public var id: SectionType.ID {sectionItem.id}

		public init(sectionItem: SectionType, items: [ItemType]) {
			self.sectionItem = sectionItem
			self.items = items
		}
	}
	public var sections: [Section] = []

	/// creates an empty snapshot
	public init() {
		self.sections = []
	}

	/// creates a snapshot filled with sections
	public init(sections: [Section]) {
		self.sections = sections
	}

	/// creates a snapshot with items per section
	public init(items: [(SectionType, [ItemType])]) {
		items.forEach { addItems($0.1, for: $0.0) }
	}

	/// this is used to attach custom info to the snapshot
	public struct UserInfoKey: RawRepresentable, Hashable {
		public var rawValue: String

		public init(rawValue: String) {
			self.rawValue = rawValue
		}
	}
	/// user info attached to this snapshot
	public var userInfo = Dictionary<UserInfoKey, Any>()


	/// true if this snapshot has any items
	public var hasItems: Bool { return sections.first {$0.items.count > 0} != nil}

	/// the number of sections
	public var numberOfSections: Int {return sections.count}

	/// returns the section at the given index
	public func section(at index: Int) -> Section {return sections[index]}

	/// returns the item at the given index path
	public func item(at indexPath: IndexPath) -> ItemType {
		return sections[indexPath.section].items[indexPath.row]
	}

	/// returns true if the index path is valid in this snapshot
	public func isValidIndexPath(_ indexPath: IndexPath) -> Bool {
		return indexPath.section < sections.count && indexPath.row < sections[indexPath.section].items.count
	}

	/// returns the difference between this and another snapshot
	public func diff(with other: Snapshot) -> IndexPathDiffResult<SectionType, ItemType> {
		let sectionDiff = List.diffing(oldArray: sections.map{$0.sectionItem}, newArray: other.sections.map{$0.sectionItem})
		var commonResults = Dictionary<Int, List.Result<ItemType>>()

		for index in sectionDiff.common {
			let old = sections[index]
			guard let newIndex = sectionDiff.newIndexFor(identifier: old.id) else {continue}
			let new = other.section(at: newIndex)
			commonResults[index] = List.diffing(oldArray: old.items, newArray: new.items)
		}
		return IndexPathDiffResult(sectionResults: sectionDiff, commonSectionResults: commonResults)
	}

	/// Adds a section with the given items.
	/// The section will be appended at the end, regardless if there already is a section with the same id.
	public mutating func addItems(_ items: [ItemType], for section: SectionType) {
		sections.append(Section(sectionItem: section, items: items))
	}

	/// Adds items to a section.
	/// If the section does not exist, it will be appended at the end.
	/// If the section exist, the items will be added to the existing section.
	public mutating func addItems(_ items: [ItemType], to section: SectionType) {
		guard let index = sections.firstIndex(where: { $0.sectionItem.id == section.id }) else { return addItems(items, for: section) }
		sections[index].items.append(contentsOf: items)
	}
	
	/// Adds a section with the given item.
	/// The section will be appended at the end, regardless if there already is a section with the same id.
	public mutating func addItem(_ item: ItemType, for section: SectionType) {
		addItems([item], for: section)
	}
	
	/// Adds an item to a section.
	/// If the section does not exist, it will be appended at the end.
	/// If the section exist, the item will be added to the existing section.
	public mutating func addItem(_ item: ItemType, to section: SectionType) {
		addItems([item], to: section)
	}

	/// Updates the items in a section
	/// If the section does not exist, the items will be added if there are any items
	/// If the section does exist, the items will replace the items in the section
	/// If the new items are the empty list, the existing section will be removed
	public mutating func updateItems(_ items: [ItemType], in section: SectionType) {
		guard let index = sections.firstIndex(where: { $0.sectionItem.id == section.id }) else {
			if items.isEmpty {
				return addItems(items, for: section)
			} else {
				return
			}
		}
		if items.isEmpty {
			sections.remove(at: index)
		} else {
			sections[index].items = items
		}
	}

	/// moves an item from one index path to another
	public mutating func move(from: IndexPath, to: IndexPath) {
		let item = sections[from.section].items.remove(at: from.row)
		sections[to.section].items.insert(item, at: min(sections[to.section].items.count, to.row))
	}
}

public extension Snapshot {
	/// creates a snapshot for the given items, grouped into sections
	/// that are determined by the `groupedBy` callback.
	init(orderedItems: [ItemType], groupedBy: (ItemType) -> SectionType) {
		var sections = Array<Section>()
		for item in orderedItems {
			let sectionItem = groupedBy(item)
			if sections.last?.sectionItem.id != sectionItem.id {
				sections.append(Section(sectionItem: sectionItem, items: [item]))
			} else {
				sections[sections.count-1].items.append(item)
			}
		}
		self.init(sections: sections)
	}
}


public extension Snapshot {
	/// find the first index path that matches the callback
	func firstIndexPath(where callback: (ItemType) -> Bool) -> IndexPath? {
		for (sectionIndex, sectionItem) in sections.enumerated() {
			if let itemIndex = sectionItem.items.firstIndex(where: callback) {
				return IndexPath(row: itemIndex, section: sectionIndex)
			}
		}
		return nil
	}
	
	/// find the first index path that matches the given item by id
	func firstIndexPath(of item: ItemType) -> IndexPath? {
		return firstIndexPath(where: { $0.id == item.id })
	}
	
	/// fins the first item matching the callback
	func firstItem(where matching: (ItemType) -> Bool) -> ItemType? {
		return firstIndexPath(where: matching).flatMap { self[$0] }
	}
	
	subscript(_ indexPath: IndexPath) -> ItemType? {
		get { itemOrNil(at: indexPath) }
		set { newValue.flatMap { sections[indexPath.section].items[indexPath.row] = $0 } }
	}
}
