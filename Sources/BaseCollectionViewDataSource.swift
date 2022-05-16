//
//  BaseCollectionViewDataSource.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import UIKit

/// a data source that manages data in collection view thru snapshots.
public class BaseCollectionViewDataSource<Snapshot: SnapshotProtocol> : NSObject, UICollectionViewDataSource {
	public typealias ItemType = Snapshot.Section.ItemType
	public typealias SectionType = Snapshot.Section.SectionType

	/// called when we need a cell
	public typealias CellProvider = (_ collectionView: UICollectionView, _ item: ItemType, _ indexPath: IndexPath) -> UICollectionViewCell?

	/// called when a cell needs to be updated
	public typealias CellUpdater = (_ collectionView: UICollectionView, _ cell: UICollectionViewCell, _ item: ItemType, _ indexPath: IndexPath, _ animated: Bool)  -> Void

	/// called when we need a supplementary view
	public typealias SupplementaryElementViewProvider = (_ collectionView: UICollectionView, _ section: SectionType?, _ indexPath: IndexPath, _ kind: String, _ animated: Bool) -> UICollectionReusableView?

	/// called when a supplementary view needs to be updated
	public typealias SupplementaryElementViewUpdater = (_ collectionView: UICollectionView, _ view: UICollectionReusableView, _ section: SectionType?, _ indexPath: IndexPath, _ kind: String, _ animated: Bool) -> Void

	// MARK: UITableViewDataSource
	public func numberOfSections(in collectionView: UICollectionView) -> Int {
		return currentSnapshot.numberOfSections
	}

	public func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
		return currentSnapshot.section(at: section).items.count
	}

	public func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
		let item = currentSnapshot.item(at: indexPath)
		guard let cell = cellProvider(collectionView, item, indexPath) else {return UICollectionViewCell()}
		cellUpdater?(collectionView, cell, item, indexPath, false)
		return cell
	}

	public	func collectionView(_ collectionView: UICollectionView, viewForSupplementaryElementOfKind kind: String, at indexPath: IndexPath) -> UICollectionReusableView {
		let section = indexPath.count > 1 ? currentSnapshot.sectionOrNil(at: indexPath.section) : nil
		elementaryViewKinds.insert(kind)
		guard let view = supplementaryElementViewProvider?(collectionView, section, indexPath, kind, false) else { return UICollectionReusableView() }
		supplementaryElementViewUpdater?(collectionView, view, section, indexPath, kind, false)
		return view
	}

	/// the collection view we work on
	public var collectionView: UICollectionView

	/// called when we need a cell
	public var cellProvider: CellProvider

	/// called when a cell needs to be updated
	public var cellUpdater: CellUpdater?

	/// called when we need a supplementary view
	public var supplementaryElementViewProvider: SupplementaryElementViewProvider?

	/// called when a supplementary view needs to be updated
	public var supplementaryElementViewUpdater: SupplementaryElementViewUpdater?

	/// view kinds for elements
	private var elementaryViewKinds = Set<String>()

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

	/// creates a snapshot for a collection view
	public init(collectionView: UICollectionView, cellProvider: @escaping CellProvider) {
		self.collectionView = collectionView
		self.cellProvider = cellProvider
		super.init()
		self.collectionView.dataSource = self
	}

	/// updates only the visible items, doesn't change the snapshot
	public func updateVisibleItems(animated: Bool) {
		// can be optimized later on
		apply(actualSnapshot, animated: animated)
	}

	/// applies a new snapshot
	public func apply(_ snapshot: Snapshot, animated: Bool, completion: ((Bool) -> Void)? = nil) {
		guard collectionView.bounds.size != .zero else {
			actualSnapshot = snapshot
			return
		}

		guard animated == true else {
			actualSnapshot = snapshot
			collectionView.reloadData()
			return
		}

		// toggle prefetching to get rid of prefetched cells
		collectionView.isPrefetchingEnabled.toggle()
		collectionView.isPrefetchingEnabled.toggle()
		
		actualSnapshot.applyChanges(from: snapshot,
									 to: collectionView,
									 elementaryViewKinds: elementaryViewKinds,
									 updateData: {actualSnapshot = $0},
									 updateItem: {cellUpdater?(collectionView, $0, $1, $2, $3)},
									 updateSupplementaryView: {supplementaryElementViewUpdater?(collectionView, $0, $1, $2, $3, $4)},
									 completion: completion)
	}
}

public extension BaseCollectionViewDataSource {
	/// Creates a data source where every cell is of a specified type.
	convenience init<T: UICollectionViewCell>(
		collectionView: UICollectionView,
		cellsWithClass cellClass: T.Type,
		updater: ((_ collectionView: UICollectionView, _ cell: T, _ item: ItemType, _ indexPath: IndexPath, _ animated: Bool) -> Void)? = nil) {
		collectionView.register(cellClass, forCellWithReuseIdentifier: "Cell")
		
		self.init(collectionView: collectionView, cellProvider: {collectionView, _, indexPath in
			return collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath)
		})
		
		guard let updater = updater else { return }
		self.cellUpdater = { collectionView, cell, item, indexPath, animated in
			guard let cell = cell as? T else { return }
			updater(collectionView, cell, item, indexPath, animated)
		}
	}

	/// creates a data source where every cell is of the same type
	convenience init(collectionView: UICollectionView, cellsWithIdentifier cellIdentifier: String) {
		self.init(collectionView: collectionView, cellProvider: {collectionView, _, indexPath in
			return collectionView.dequeueReusableCell(withReuseIdentifier: cellIdentifier, for: indexPath)
		})
	}

	/// returns the item at the given index path, if it exists
	func item(at indexPath: IndexPath) -> ItemType? {
		return currentSnapshot.itemOrNil(at: indexPath)
	}

	/// returns the next item in the same section, if it exists
	func itemInSameSection(after indexPath: IndexPath) -> ItemType? {
		return item(at: IndexPath(row: indexPath.row + 1, section: indexPath.section))
	}

	/// returns the previous item in the same section, if it exists
	func itemInSameSection(before indexPath: IndexPath) -> ItemType? {
		return item(at: IndexPath(row: indexPath.row - 1, section: indexPath.section))
	}
}

