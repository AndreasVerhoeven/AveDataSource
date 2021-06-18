//
//  IndexPathDiffResult.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import Foundation

public struct IndexPathDiffResult<SectionType: Identifiable, ItemType: Identifiable> {
	var sectionResults = List.Result<SectionType>()
	var commonSectionResults = Dictionary<Int, List.Result<ItemType>>()
}
