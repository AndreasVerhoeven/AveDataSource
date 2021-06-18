//
//  RowItem.swift
//  Demo
//
//  Created by Andreas Verhoeven on 17/06/2021.
//

import Foundation

/// A simple ItemType implementation that can be used
/// to wrap items + an `add` button
enum RowItem<ItemType: Identifiable>: Identifiable {
	enum Operation: Identifiable, Hashable {
		var id: Operation {return self}
		case add
	}
	var id: AnyHashable {
		switch self {
			case .item(let item): return item.id
			case .operation(let operation): return operation.id
		}
	}

	case item(ItemType)
	case operation(Operation)

	static func from(_ items: [ItemType]?, operation: Operation? = nil) -> [RowItem] {
		var values = items?.map {RowItem.item($0)} ?? []
		operation.map { values.append(.operation($0)) }
		return values
	}
}
