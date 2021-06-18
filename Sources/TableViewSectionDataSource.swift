//
//  TableViewSectionDataSource.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import UIKit

/// A data source for a section in a table view, can be used if you only want to manage a single section, as apart
/// This data source doesn't take over the table view's data source: it still needs to be handled manually.
public class TableViewSectionDataSource<ItemType: Identifiable> {
	public typealias Snapshot = SingleSectionSnapshot<ItemType>

	/// the index of the section we manage
	public var sectionIndex: Int

	/// the snapshot for our section
	public private(set) var currentSnapshot = Snapshot.init()

	/// the table view we are attached to
	public let tableView: UITableView

	/// our items. Setting this will always animate the changes
	public var items: [ItemType] {
		get { currentSnapshot.items }
		set { apply(items: newValue) }
	}

	/// the number of items
	public var numberOfItems: Int {return currentSnapshot.items.count}

	/// returns the item at for the given index
	public func item(at index: Int) -> ItemType {return currentSnapshot.items[index]}

	/// called when updating the cell
	public typealias CellUpdateHandler = (_ tableView: UITableView, _ cell: UITableViewCell, _ item: ItemType, _ indexPath: IndexPath, _ animated: Bool) -> Void

	/// called when updating the cell
	public var cellUpdater: CellUpdateHandler?

	/// creates a data source
	public init(tableView: UITableView, sectionIndex: Int, cellUpdater: CellUpdateHandler? = nil) {
		self.sectionIndex = sectionIndex
		self.tableView = tableView
		self.cellUpdater = cellUpdater
	}

	/// applies new items to the snapshot
	public func apply(items: [ItemType], completion: ((Bool) -> Void)? = nil) {
		let snapshot = Snapshot(items: items)
		currentSnapshot.applyChanges(from: snapshot, to: tableView, sectionOffset: sectionIndex, updateData: { newSnapshot in
			currentSnapshot = newSnapshot
		}, updateItem: {cell, item, indexPath, animated in
			guard indexPath.section == sectionIndex else {return}
			cellUpdater?(tableView, cell, item, indexPath, animated)
		},  completion: completion)

	}
}
