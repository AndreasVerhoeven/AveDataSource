//
//  SnapshotSectionProtocol.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import Foundation

/// This is the protocol for a snapshot of a section
public protocol SnapshotSectionProtocol: Identifiable {

	/// the type used to identify sections
	associatedtype SectionType: Identifiable

	/// the type of items this section contains
	associatedtype ItemType: Identifiable

	/// the item for this section that uniquely identifies this section
	var sectionItem: SectionType { get }

	/// the items in this section
	var items: [ItemType] { get }

	/// the id of this section
	var id: SectionType.ID { get }
}
