//
//  IndexPathDiffResult.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import Foundation

public struct IndexPathDiffResult<SectionType: Identifiable, ItemType: Identifiable> {
	public var sectionResults = List.Result<SectionType>()
	public var commonSectionResults = Dictionary<Int, List.Result<ItemType>>()
}
