//
//  Snapshot+UIKit.swift
//  AveDataSource
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import UIKit

extension SnapshotProtocol {

	/// Applies changes from one snapshot to another for the given cell type
	func applyChanges<Cell>(from other: Self,
							sectionOffset: Int = 0,
							visibleItems: [(Cell, IndexPath)],
							additionalUpdates: (_ diff: Diff) -> Void = {_ in },
							updateItem: (_ cell: Cell, _ item: Section.ItemType, _ indexPath: IndexPath, _ animated: Bool) -> Void,
							deleteSections: (_ sections: IndexSet) -> Void,
							insertSections: (_ sections: IndexSet) -> Void,
							moveSection: (_ from: Int, _ to: Int) -> Void,
							deleteItems: (_ items: [IndexPath]) -> Void,
							insertItems: (_ items: [IndexPath]) -> Void,
							moveItem: (_ from: IndexPath, _ to: IndexPath) -> Void,
							updateData: (Self) -> Void) {
		let oldSnapshot = self
		updateData(other)

		let diff = oldSnapshot.diff(with: other)
		additionalUpdates(diff)

		for (cell, indexPath) in visibleItems {
			guard let section = diff.commonSectionResults[indexPath.section] else{continue}
			guard section.common.contains(indexPath.row) else {continue}
			let sectionIdentifier = oldSnapshot.section(at: indexPath.section).id
			let itemIdentifier = oldSnapshot.item(at: indexPath).id
			let newSectionIndex = diff.sectionResults.newIndexFor(identifier: sectionIdentifier).map{$0 + sectionOffset} ?? indexPath.section
			let newRowIndex = section.newIndexFor(identifier: itemIdentifier) ?? indexPath.row
			let newIndexPath = IndexPath(row: newRowIndex, section: newSectionIndex)
			let newItem = other.item(at: newIndexPath)
			//print("\(indexPath.section) -> \(newIndexPath.section)")
			updateItem(cell, newItem, newIndexPath, true)
		}

		deleteSections(diff.sectionResults.deletes)
		insertSections(diff.sectionResults.inserts)
		for move in diff.sectionResults.moves {
			moveSection(move.from, move.to)
		}

		diff.commonSectionResults.forEach { oldSectionIndex, result in
			let sectionIdentifier = oldSnapshot.section(at: oldSectionIndex).id
			let newSectionIndex = diff.sectionResults.newIndexFor(identifier: sectionIdentifier) ?? oldSectionIndex

			deleteItems(result.deletes.map({IndexPath(row: $0, section: oldSectionIndex + sectionOffset)}))
			insertItems(result.inserts.map({IndexPath(row: $0, section: newSectionIndex + sectionOffset)}))
			for move in result.moves {
				moveItem(IndexPath(row: move.from, section: oldSectionIndex + sectionOffset), IndexPath(row: move.to, section: newSectionIndex + sectionOffset))
			}
		}
	}

	/// applies changes to a snapshot to a collection view
	func applyChanges(from other: Self,
					  to collectionView: UICollectionView,
					  sectionOffset: Int = 0,
					  elementaryViewKinds: Set<String> = Set<String>(),
					  updateData: (Self) -> Void,
					  updateItem: (_ cell: UICollectionViewCell, _ item: Section.ItemType, _ indexPath: IndexPath, _ animated: Bool) -> Void,
					  updateSupplementaryView: (_ view: UICollectionReusableView, _ section: Section.SectionType?, _ indexPath: IndexPath, _ kind: String, _ animated: Bool) -> Void,
					  completion: ((Bool) -> Void)? = nil) {

		collectionView.performBatchUpdates({
			let visibleItems = collectionView.visibleCells.compactMap({cell in collectionView.indexPath(for: cell).map({(cell, $0)}) })

			let oldSnapshot = self
			let additionalUpdates: (Diff) -> Void = { diff in

				for kind in elementaryViewKinds {
					for indexPath in collectionView.indexPathsForVisibleSupplementaryElements(ofKind: kind) {
						guard let view = collectionView.supplementaryView(forElementKind: kind, at: indexPath) else {continue}
						guard let indexPathSection = indexPath.first else {continue}

						guard let section = diff.commonSectionResults[indexPathSection] else {continue}
						let sectionIdentifier = oldSnapshot.section(at: indexPathSection).id
						let newSectionIndex = diff.sectionResults.newIndexFor(identifier: sectionIdentifier).map{$0 + sectionOffset} ?? indexPathSection
						if indexPath.count == 1 {
							let newIndexPath = IndexPath(index: newSectionIndex)
							updateSupplementaryView(view, other.sectionOrNil(at: newSectionIndex), newIndexPath, kind, true)
						} else {
							if let itemIdentifier = oldSnapshot.itemOrNil(at: indexPath)?.id {
								let newRowIndex = section.newIndexFor(identifier: itemIdentifier) ?? indexPath.row
								let newIndexPath = IndexPath(row: newRowIndex, section: newSectionIndex)
								updateSupplementaryView(view, other.sectionOrNil(at: newSectionIndex), newIndexPath, kind, true)
							} else {
								let newIndexPath = IndexPath(index: newSectionIndex)
								updateSupplementaryView(view, other.sectionOrNil(at: newSectionIndex), newIndexPath, kind, true)
							}
						}
					}
				}
			}

			applyChanges(from: other,
						 sectionOffset: sectionOffset,
						 visibleItems: visibleItems,
						 additionalUpdates: additionalUpdates,
						 updateItem: updateItem,
						 deleteSections: {collectionView.deleteSections($0)},
						 insertSections: {collectionView.insertSections($0)},
						 moveSection: {collectionView.moveSection($0, toSection: $1)},
						 deleteItems: {collectionView.deleteItems(at: $0)},
						 insertItems: {collectionView.insertItems(at: $0)},
						 moveItem: {collectionView.moveItem(at: $0, to: $1)},
						 updateData: updateData)
		}, completion: completion)
	}

	/// applies changes to a snapshot to a table view
	func applyChanges(from other: Self,
					  to tableView: UITableView,
					  sectionOffset: Int = 0,
					  updateData: (Self) -> Void,
					  updateItem: (_ cell: UITableViewCell, _ item: Section.ItemType, _ indexPath: IndexPath, _ animated: Bool) -> Void,
					  rowAnimation: UITableView.RowAnimation = .fade,
					  completion: ((Bool) -> Void)? = nil) {

		tableView.performBatchUpdates({
			let visibleItems = tableView.visibleCells.compactMap({cell in tableView.indexPath(for: cell).map({(cell, $0)}) })
			applyChanges(from: other,
						 sectionOffset: sectionOffset,
						 visibleItems: visibleItems,
						 updateItem: updateItem,
						 deleteSections: {tableView.deleteSections($0, with: rowAnimation)},
						 insertSections: {tableView.insertSections($0, with: rowAnimation)},
						 moveSection: {tableView.moveSection($0, toSection: $1)},
						 deleteItems: {tableView.deleteRows(at: $0, with: rowAnimation)},
						 insertItems: {tableView.insertRows(at: $0, with: rowAnimation)},
						 moveItem: {tableView.moveRow(at: $0, to: $1)},
						 updateData: updateData)
		}, completion: completion)
	}
}

