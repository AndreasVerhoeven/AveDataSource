//
//  TableViewDataSource.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import UIKit

/// This is a data source for a table view: it manages updates by applying snapshots and calling back into
public class TableViewDataSource<SectionType: Identifiable, ItemType: Identifiable>: BaseTableViewDataSource<TableViewDataSource<SectionType, ItemType>.SnapshotType> {
	public typealias SnapshotType = Snapshot<SectionType, ItemType>
}

