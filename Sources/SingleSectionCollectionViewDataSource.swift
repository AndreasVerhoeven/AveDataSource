//
//  SingleSectionCollectionViewDataSource.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import UIKit

/// A data source for when there's only a single section in the collection view. This is optimized, so that
/// one doesn't have to provide a section type.
open class SingleSectionCollectionViewDataSource<ItemType: Identifiable>: BaseCollectionViewDataSource<SingleSectionSnapshot<ItemType> > {
	public func apply(items: [ItemType], animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
		apply(SingleSectionSnapshot<ItemType>(items: items), animated: animated, completion: completion)
	}
}

public extension SingleSectionCollectionViewDataSource {
	/// returns the item at the given section
	func item(at index: Int) -> ItemType? {
		return currentSnapshot.itemOrNil(at: IndexPath(item: index, section: 0))
	}
}
