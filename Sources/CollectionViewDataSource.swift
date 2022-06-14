//
//  CollectionViewDataSource.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import UIKit

/// A data source for managing a snapshot in a collection view.
open class CollectionViewDataSource<SectionType: Identifiable, ItemType: Identifiable>: BaseCollectionViewDataSource<CollectionViewDataSource<SectionType, ItemType>.SnapshotType> {
	public typealias SnapshotType = Snapshot<SectionType, ItemType>
}
