//
//  SingleSectionTableViewDataSource.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import UIKit

/// A data source where there is only one section with items
open class SingleSectionTableViewDataSource<ItemType: Identifiable>: BaseTableViewDataSource<SingleSectionSnapshot<ItemType> > {

	/// applies new items to the data source
	public func apply(items: [ItemType], animated: Bool = true, completion: ((Bool) -> Void)? = nil) {
		apply(SingleSectionSnapshot<ItemType>(items: items), animated: animated, completion: completion)
	}
}
