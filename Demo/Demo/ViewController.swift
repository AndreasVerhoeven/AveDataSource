//
//  ViewController.swift
//  Demo
//
//  Created by Andreas Verhoeven on 16/05/2021.
//

import UIKit

class ViewController: UITableViewController {

	// this models our section
	enum Section: String, Hashable, Identifiable, CaseIterable {
		case first
		case second
		case third

		var id: Self { self }

		static var random: Self {
			allCases.randomElement()!
		}
	}

	struct Item: Identifiable {
		var id = UUID()
		var text: String
	}

	lazy var dataSource = TableViewDataSource<Section, Item>(tableView: tableView, cellClass: UITableViewCell.self) { tableView, cell, item, indexPath, animated in

		if animated == true {
			/// if we are asked to animate, we update an existing cell with new contents
			UIView.transition(with: cell, duration: 0.25, options: [.beginFromCurrentState, .transitionCrossDissolve], animations: {
				cell.textLabel?.text = item.text
			})
		} else {
			/// if we are not asked to animate, we update a new cell or an existing cell without animation
			cell.textLabel?.text = item.text
		}
	}


	@objc private func addItem() {
		/// this adds an item to a random section
		var snapshot = dataSource.currentSnapshot
		snapshot.addItems([Item(text: "Some text \(Int.random(in: 0...100))")], to: .random)
		dataSource.apply(snapshot, animated: true)
	}

	@objc private func removeItem() {
		/// this removes a random item from the table view
		dataSource.updateSnapshot { snapshot in
			guard var section = dataSource.currentSnapshot.sections.randomElement() else { return }
			section.items.remove(at: Int.random(in: 0..<section.items.count))
			snapshot.updateItems(section.items, in: section.sectionItem)
		}
	}

	@objc private func editItem() {
		/// this changes the text of a single random item and updates the table view
		/// As you can see, the cells are not replaced, just updated
		dataSource.updateSnapshot { snapshot in
			guard var section = dataSource.currentSnapshot.sections.randomElement() else { return }
			section.items[Int.random(in: 0..<section.items.count)].text = "Random text \(Int.random(in: 0...100))"
			snapshot.updateItems(section.items, in: section.sectionItem)
		}
	}


	override func viewDidLoad() {
		super.viewDidLoad()

		navigationItem.rightBarButtonItems = [
			UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(addItem)),
			UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(removeItem)),
			UIBarButtonItem(barButtonSystemItem: .edit, target: self, action: #selector(editItem)),

		]

		dataSource.headerTitleProvider = { _, section, _ in
			return section.rawValue
		}

		/// our initial snapshot
		var snapshot = dataSource.currentSnapshot
		snapshot.addItems([Item(text: "Item 1")], to: .first)
		snapshot.addItems([Item(text: "Item 2")], to: .first)
		snapshot.addItems([Item(text: "Item 3")], to: .third)
		dataSource.currentSnapshot = snapshot
	}

	override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
		tableView.deselectRow(at: indexPath, animated: true)
		let item = dataSource.currentSnapshot.item(at: indexPath)
		let alert = UIAlertController(title: item.text, message: nil, preferredStyle: .alert)
		alert.addAction(UIAlertAction(title: "OK", style: .cancel, handler: nil))
		present(alert, animated: true)
	}
}

extension Int: Identifiable {
	public var id: Self { self }
}
