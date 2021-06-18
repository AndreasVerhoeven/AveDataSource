# AveDataSource

This is a library that makes working with CollectionView and UITableViews easier by managing the data for you and ensuring that the right insert/delete operations are called.

It's similar to UIKit DiffableDataSource, but with one addition: it supports updating existing cells with animation, without replacing the actual cell. This ensures that in flight animations are not interrupted.


## Snapshot

The basis of everything is a snapshot. A snapshot is a view of your data at a given moment. If we have two snapshots, we can calculate the `diff` of those two and know exactly what to update.

A snapshot manages **Item**s  in **Section**s. The concrete Item Type and Section Types need to implement `Identifiable` so that they have a stable id that doesn't depend on their data.

As an optimization, there's also `SingleSectionSnapshot` which only manages a list of `Item`s: this is useful if you only ever have one section.


## TableViewDataSource

There are three variants:

- `TableViewDataSource` that manages the data in all sections of your table view
- `SingleSectionTableViewDataSource` that manages the data in a table view with only one single section
- `TableViewSectionDataSource` that book keeps data in one section, while you are responsible for the other sections and implementing the actually data .


# Example:

```
let dataSource = TableViewDataSource(tableView, cellProvider: { tableView, item, indexPath
  return tableView.dequeueCellWithIdentifier("Cell")
})
dataSource.cellUpdater = { tableView, cell, item, indexPath, animated in
  cell.textLabel?.setText(item.text, animated: animated)
}


var snapshot = dataSource.currentSnapshot
snapshot.addItems([Item(text: "Item 1")], to: .first)
snapshot.addItems([Item(text: "Item 2")], to: .first)
snapshot.addItems([Item(text: "Item 3")], to: .third)
dataSource.apply(snapshot, animated: true)

```
 
 ## CollectionViewDataSource
 
 There are two variants:
 
 - `CollectionViewDataSource` that manages the data in all sections of your collection view
 - `SingleSectionCollectionViewDataSource` that manages the data in a collection view with only one single section
