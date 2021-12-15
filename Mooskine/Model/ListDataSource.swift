//
//  ListDataSource.swift
//  Mooskine
//
//  Created by Justin Viasus on 12/13/21.
//  Copyright © 2021 Udacity. All rights reserved.
//

import Foundation
import CoreData
import UIKit

// ObjectType such as Notebook, CellType such as NotebookCell.
// Don't forget to set both tableView.dataSource and fetchedResultsController.delegate equal to this object.

class ListDataSource<ObjectType: NSManagedObject, CellType: UITableViewCell>: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate where CellType: Cell {
    
    private var tableView: UITableView
    private var configure: (ObjectType, CellType) -> Void
    
    // these rely on dependency injections
    var dataController: DataController!
    var fetchedResultsController: NSFetchedResultsController<ObjectType>!
    
    init(tableView: UITableView, managedObjectContext: NSManagedObjectContext, fetchRequest: NSFetchRequest<ObjectType>, configure: @escaping (ObjectType, CellType) -> Void) {
        self.tableView = tableView
        self.configure = configure
        super.init()
    }
    
    // MARK: - Table View Data Source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let object: ObjectType = fetchedResultsController.object(at: indexPath)
        print(object)
        let cell: CellType = tableView.dequeueReusableCell(withIdentifier: CellType.defaultReuseIdentifier, for: indexPath) as! CellType

        // Configure cell
        configure(object, cell)
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {
        switch editingStyle {
        case .delete: deleteObject(at: indexPath)
        default: () // Unsupported
        }
    }
    
    // MARK: - Helpers
    
    func deleteObject(at indexPath: IndexPath) {
        // get a reference to the object to delete
        let objectToDelete = fetchedResultsController.object(at: indexPath)

        // delete the object from the context
        dataController.viewContext.delete(objectToDelete)

        // try saving the context
        try? dataController.viewContext.save() // save the context (error is not handled)
    }
    
    // MARK: - Fetched Results Controller Delegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    // notifies the receiver of the addition or removal of a section
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        let indexSet = IndexSet(integer: sectionIndex)
        switch type {
        case .insert:
            tableView.insertSections(indexSet, with: .fade)
        case .delete:
            tableView.deleteSections(indexSet, with: .fade)
        case .update, .move:
            fatalError("Invalid change type in controller(_:didChange:atSectionIndex:for:). Only .insert or .delete should be possible.")
        }
    }
    
    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .fade)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .fade)
        default:
            break
        }
    }
}

// TODO: create a ListDataSource in both view controllers and configure it as the table views' delegate. ???

// TODO: extra credit: make sure you notify the view controllers after content updates have occured so that the state of the edit button updates when the UITableView changes its content.
