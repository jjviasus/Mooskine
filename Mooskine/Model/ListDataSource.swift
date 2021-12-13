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

// we have generic types ObjectType and CellType
class ListDataSource<ObjectType: NSManagedObject, CellType: UITableViewCell>: NSObject, UITableViewDataSource, NSFetchedResultsControllerDelegate {
    
    var fetchedResultsController: NSFetchedResultsController<ObjectType>!
    var configureCell: (CellType, ObjectType) -> Void
    var context: NSManagedObjectContext
    var tableView: UITableView
    
    init(tableView: UITableView, managedObjectContext: NSManagedObjectContext, fetchRequest: NSFetchRequest<ObjectType>, configure: @escaping (CellType, ObjectType) -> Void) {
        //super.init() ?
        
        //    let predicate = NSPredicate(format: "notebook == %@", notebook) // The predicate will ensure that we only fetch the notes for the selected notebook. %@ gets replaced by notebook at runtime.
        //    fetchRequest.predicate = predicate
        //    let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true) // sort descriptor to sort by creation date
        //    fetchRequest.sortDescriptors = [sortDescriptor]
        
        self.fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: managedObjectContext, sectionNameKeyPath: nil, cacheName: nil) // cacheName?
        //fetchedResultsController.delegate = self ?
        
        do {
            try self.fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
        self.configureCell = configure
        self.context = managedObjectContext
        self.tableView = tableView
    }
    
    // MARK: - Table view data source
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return fetchedResultsController.sections?.count ?? 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return fetchedResultsController.sections?[section].numberOfObjects ?? 0
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let object: ObjectType = fetchedResultsController.object(at: indexPath)
        let cell: CellType = tableView.dequeueReusableCell(withIdentifier: String(describing: object), for: indexPath) as! CellType // TODO: may need to fix the withIdentifier
        
        // Configure cell
        configureCell(cell, object)
        
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
        context.delete(objectToDelete)
        
        // try saving the context
        try? context.save() // save the context (error is not handled)
    }
    
    // MARK: - Fetched Results Controller Delegate
    
    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.beginUpdates()
    }
    
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        tableView.endUpdates()
    }
    
    // notifies the receiver of the addition or removal of a section
    //    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
    //        // do we need to implement this?
    //    }
    
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

// TODO: create a ListDataSource in both view controllers and configure it as the table views' delegate.

// TODO: extra credit: make sure you notify the view controllers after content updates have occured so that the state of the edit button updates when the UITableView changes its content.
