//
//  BaseTableViewDataSource.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import UIKit

/// Our base table view data source. Use this to manage a snapshot and provide the right callbacks.
open class BaseTableViewDataSource<Snapshot: SnapshotProtocol> : NSObject, UITableViewDataSource, UITableViewDelegate {
	public typealias ItemType = Snapshot.Section.ItemType
	public typealias SectionType = Snapshot.Section.SectionType

	/// called when we need a new cell
	public typealias CellProvider = (_ tableView: UITableView, _ item: ItemType, _ indexPath: IndexPath) -> UITableViewCell?

	/// called when we need to update a cell
	public typealias CellUpdater = (_ tableView: UITableView, _ cell: UITableViewCell, _ item: ItemType, _ indexPath: IndexPath, _ animated: Bool)  -> Void

	/// called when we need a header/footer view
	public typealias HeaderFooterViewProvider = (_ tableView: UITableView, _ section: SectionType, _ index: Int) -> UITableViewHeaderFooterView?

	/// called when we need a header/footer title
	public typealias HeaderFooterTitleProvider = (_ tableView: UITableView, _ section: SectionType, _ index: Int) -> String?
	
	/// called when a header/footer is updated
	public typealias HeaderFooterViewUpdater = (_ tableView: UITableView, _ view: UIView, _ section: SectionType, _ index: Int, _ animated: Bool) -> Void
	
	/// called when a row is selected
	public typealias SelectionCallback = (_ tableView: UITableView, _ item: ItemType, _ indexPath: IndexPath) -> Void
	
	/// called when we query if a row is editable
	public typealias CanEditRowCallback = (_ tableView: UITableView, _ item: ItemType, _ indexPath: IndexPath) -> Bool?
	
	/// called when commiting editor for a row
	public typealias CommitEditingCallback = (_ tableView: UITableView, _ item: ItemType, _ indexPath: IndexPath, _ style: UITableViewCell.EditingStyle) -> Void
	
	/// called when committing a move operation
	public typealias MoveCallback = (_ tableView: UITableView, _ source: ItemType, _ sourceIndexPath: IndexPath, _ destination: ItemType?, _ destionationIndexPath: IndexPath) -> Void

	/// MARK: - UITableViewDataSource
	public func numberOfSections(in tableView: UITableView) -> Int {
		return currentSnapshot.numberOfSections
	}

	public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
		return currentSnapshot.section(at: section).items.count
	}

	public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
		let item = currentSnapshot.item(at: indexPath)
		guard let cell = cellProvider(tableView, item, indexPath) else {return UITableViewCell()}
		cellUpdater?(tableView, cell, item, indexPath, false)
		return cell
	}

	public func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
		// WORKAROUND (iOS 12, *) UIKit sometimes calls this method when we don't have any sections
		guard section < currentSnapshot.numberOfSections else { return nil }
		return headerTitleProvider?(tableView, currentSnapshot.section(at: section).sectionItem, section)
	}
	
	public func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
		// WORKAROUND (iOS 12, *) UIKit sometimes calls this method when we don't have any sections
		guard section < currentSnapshot.numberOfSections else { return nil }
		return footerTitleProvider?(tableView, currentSnapshot.section(at: section).sectionItem, section)
	}
	
	// MARK: - UITableViewDelegate
	public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
		// WORKAROUND (iOS 12, *) UIKit sometimes calls this method when we don't have any sections
		guard section < currentSnapshot.numberOfSections else { return nil }
		let sectionItem = currentSnapshot.section(at: section).sectionItem
		let view = headerViewProvider?(tableView, sectionItem, section)
		if let view = view {
			headerViewUpdater?(tableView, view, sectionItem, section, false)
		}
		return view
	}
	
	public func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
		// WORKAROUND (iOS 12, *) UIKit sometimes calls this method when we don't have any sections
		guard section < currentSnapshot.numberOfSections else { return nil }
		let sectionItem = currentSnapshot.section(at: section).sectionItem
		let view = footerViewProvider?(tableView, sectionItem, section)
		if let view = view {
			footerViewUpdater?(tableView, view, sectionItem, section, false)
		}
		return view
	}
	
	public func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
		let item = currentSnapshot.item(at: indexPath)
		return canEditRow?(tableView, item, indexPath) ?? (commitEditingStyle != nil)
	}
	
	public func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool {
		let item = currentSnapshot.item(at: indexPath)
		return canMoveRow?(tableView, item, indexPath) ?? false
	}
	
	public func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
		let item = currentSnapshot.item(at: indexPath)
		commitEditingStyle?(tableView, item, indexPath, editingStyle)
	}
	
	public func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath, to destinationIndexPath: IndexPath) {
		guard let sourceItem = currentSnapshot.itemOrNil(at: sourceIndexPath) else { return }
		let destinationItem = currentSnapshot.itemOrNil(at: destinationIndexPath)
		moveCallback?(tableView, sourceItem, sourceIndexPath, destinationItem, destinationIndexPath)
	}
	
	public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		didSelectCallback?(tableView, currentSnapshot.item(at: indexPath), indexPath)
	}

	/// the table view
	public var tableView: UITableView

	/// our cell provider, called when we need a new cell
	public var cellProvider: CellProvider


	/// our cell updated, called when we need to update a cell
	public var cellUpdater: CellUpdater?

	/// called when we need a header/footer title/view
	public var headerTitleProvider: HeaderFooterTitleProvider?
	public var footerTitleProvider: HeaderFooterTitleProvider?
	
	/// called when we are delegate
	public var headerViewProvider: HeaderFooterViewProvider?
	public var footerViewProvider: HeaderFooterViewProvider?
	public var headerViewUpdater: HeaderFooterViewUpdater?
	public var footerViewUpdater: HeaderFooterViewUpdater?
	public var didSelectCallback: SelectionCallback?
	
	/// called when editing
	public var canEditRow: CanEditRowCallback?
	public var canMoveRow: CanEditRowCallback?
	public var commitEditingStyle: CommitEditingCallback?
	public var moveCallback: MoveCallback?
	
	/// default row animation
	public var defaultRowAnimation: UITableView.RowAnimation = .fade

	/// our actual snapshot
	private var actualSnapshot = Snapshot.init()

	/// the snapshot we are currently displaying. Changes to this are always animated instantly
	public var currentSnapshot: Snapshot {
		get { actualSnapshot }
		set {
			apply(newValue, animated: true)
		}
	}

	/// call to update the current snapshot and apply the changes when done
	public func updateSnapshot(animated: Bool = true, _ callback: (inout Snapshot) -> Void) {
		var snapshot = currentSnapshot
		callback(&snapshot)
		apply(snapshot, animated: animated)
	}

	/// creates a data source for a table view and a cell provider
	public init(tableView: UITableView, cellProvider: @escaping CellProvider) {
		self.tableView = tableView
		self.cellProvider = cellProvider
		super.init()
		self.tableView.dataSource = self
	}

	/// updates all visible cells, without changing the snapshot
	public func updateCells(animated: Bool = true) {
		if animated == true {
			apply(currentSnapshot, animated: animated)
		} else {
			tableView.reloadData()
		}
	}

	/// applies a new snapshot
	public func apply(_ snapshot: Snapshot, animated: Bool, completion: ((Bool) -> Void)? = nil) {
		guard tableView.bounds.size != .zero else {
			actualSnapshot = snapshot
			return
		}

		guard animated == true else {
			actualSnapshot = snapshot
			tableView.reloadData()
			return
		}

		if #available(iOS 15, *) {
			// toggle prefetching to get rid of prefetched cells
			tableView.isPrefetchingEnabled.toggle()
			tableView.isPrefetchingEnabled.toggle()
		}
		
		actualSnapshot.applyChanges(from: snapshot,
									to: tableView,
									updateData: {actualSnapshot = $0},
									updateItem: {cellUpdater?(tableView, $0, $1, $2, $3)},
									rowAnimation: defaultRowAnimation,
									completion: completion)
		
		for index in 0..<currentSnapshot.sections.count {
			let sectionItem = currentSnapshot.sections[index].sectionItem
			
			if let headerView = tableView.headerView(forSection: index) {
				headerViewUpdater?(tableView, headerView, sectionItem, index, animated)
			}
			
			if let footerView = tableView.footerView(forSection: index) {
				footerViewUpdater?(tableView, footerView, sectionItem, index, animated)
			}
		}
	}
}

public extension BaseTableViewDataSource {
	/// returns the item for the given index path, if it exists
	func item(at indexPath: IndexPath) -> ItemType? {
		return currentSnapshot.itemOrNil(at: indexPath)
	}

	/// gets the next item in the same section, if it exists
	func itemInSameSection(after indexPath: IndexPath) -> ItemType? {
		return item(at: IndexPath(row: indexPath.row + 1, section: indexPath.section))
	}

	/// gets the previous item in the same index, if it exists
	func itemInSameSection(before indexPath: IndexPath) -> ItemType? {
		return item(at: IndexPath(row: indexPath.row - 1, section: indexPath.section))
	}

	/// finds the first index path for an item, if it exists
	func firstIndexPathForItem(matching: (ItemType) -> Bool) -> IndexPath? {
		let snapshot = currentSnapshot
		for sectionIndex in 0..<snapshot.sections.count {
			let section = currentSnapshot.sections[sectionIndex]
			for rowIndex in 0..<section.items.count {
				if matching(section.items[rowIndex]) == true {
					return IndexPath(row: rowIndex, section: sectionIndex)
				}
			}
		}

		return nil
	}


	/// creates a data source where every cell is of the same type
	convenience init<T: UITableViewCell>(
		tableView: UITableView,
		cellClass: T.Type,
		style: UITableViewCell.CellStyle = .default,
		updater: ((_ tableView: UITableView, _ cell: T, _ item: ItemType, _ indexPath: IndexPath, _ animated: Bool) -> Void)? = nil) {
			if style == .default {
				tableView.register(cellClass, forCellReuseIdentifier: "Cell")
			}
			
			self.init(tableView: tableView, cellProvider: { tableView, _, _ in
				if style == .default {
					return tableView.dequeueReusableCell(withIdentifier: "Cell")
				} else {
					// swiftlint:disable:next explicit_init
					return tableView.dequeueReusableCell(withIdentifier: "Cell") ?? T.init(style: style, reuseIdentifier: "Cell")
				}
			})
			
			guard let updater = updater else { return }
			self.cellUpdater = { tableView, cell, item, indexPath, animated in
				guard let cell = cell as? T else { return }
				updater(tableView, cell, item, indexPath, animated)
			}
	}
}
