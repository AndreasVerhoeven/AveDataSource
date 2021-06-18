//
//  CollectionViewPrefetching.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import UIKit
import ObjectiveC.runtime

/// Helper method to get access to prefetched cells, so we can properly update them
extension UICollectionView {

	static let prefetchCellsSelector = String("s*l*l*e*C*d*e*r*a*p*e*r*p".filter({$0 != "*"}).reversed())
	var canSafelyUsePrefetching: Bool {return responds(to: NSSelectorFromString(Self.prefetchCellsSelector))}

	var prefetchedCells: [UICollectionViewCell]? {
		let stringSelector = Self.prefetchCellsSelector
		guard responds(to: NSSelectorFromString(stringSelector)) == true else {return nil}
		return self.value(forKey: stringSelector) as? [UICollectionViewCell]
	}

	var visibleAndPrefetchedCellsWithIndexPaths: [(cell: UICollectionViewCell, indexPath: IndexPath)] {
		let cells = Set(visibleCells + (prefetchedCells ?? []))
		return cells.compactMap { cell in
			guard let indexPath =  indexPath(for: cell) ?? cell.taggedIndexPath else {return nil}
			return (cell: cell, indexPath: indexPath)
		}
	}
}

extension UICollectionViewCell {
	private static var taggedIndexPathAssociatedObjectKey = 0

	var taggedIndexPath: IndexPath? {
		get {objc_getAssociatedObject(self, &Self.taggedIndexPathAssociatedObjectKey) as? IndexPath}
		set {objc_setAssociatedObject(self, &Self.taggedIndexPathAssociatedObjectKey, newValue, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)}
	}
}
