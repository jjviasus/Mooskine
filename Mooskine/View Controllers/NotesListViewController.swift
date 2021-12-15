//
//  NotesListViewController.swift
//  Mooskine
//
//  Created by Josh Svatek on 2017-05-31.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import CoreData

class NotesListViewController: UIViewController {
    
    // MARK: - Outlets
    
    /// A table view that displays a list of notes for a notebook
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties

    /// The notebook whose notes are being displayed
    var notebook: Notebook!
    var dataController: DataController! // implicity unwrapping an optional means it is still optional and might be nil, but Swift eliminates the need for unwrapping
    var listDataSource: ListDataSource<Note, NoteCell>!
    var fetchedResultsController: NSFetchedResultsController<Note>!
    
    // MARK: - Setup

    /// A date formatter for date text in note cells
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()
    
    fileprivate func setUpDelegates() {
        // Set the required delegates
        tableView.dataSource = listDataSource
        fetchedResultsController.delegate = listDataSource
    }
    
    fileprivate func setUpListDataSource(_ fetchRequest: NSFetchRequest<Note>) {
        // Instantiate the listDataSource
        listDataSource = ListDataSource(tableView: tableView, managedObjectContext: dataController.viewContext, fetchRequest: fetchRequest, configure: { note, cell in
            cell.textPreviewLabel.text = note.text
                    if let creationDate = note.creationDate {
                        cell.dateLabel.text = self.dateFormatter.string(from: creationDate)
                    }
        })
        
        // Inject the data controller and fetched results controller dependencies into the listDataSource
        listDataSource.dataController = dataController
        listDataSource.fetchedResultsController = fetchedResultsController
    }

    fileprivate func setupFetchedResultsController() {
        // Create the fetch request
        let fetchRequest: NSFetchRequest<Note> = Note.fetchRequest()
        let predicate = NSPredicate(format: "notebook == %@", notebook) // The predicate will ensure that we only fetch the notes for the selected notebook. %@ gets replaced by notebook at runtime.
        fetchRequest.predicate = predicate
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: true) // sort descriptor to sort by creation date
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Instantiate the fetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "\(notebook.name ?? "notebook name")")
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
        
        // NSFetchRequest -> SELECT Query
        // NSPredicate -> WHERE clause
        // NSSortDescriptors -> ORDER BY
        
        setUpListDataSource(fetchRequest)
        setUpDelegates()
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.title = notebook.name
        navigationItem.rightBarButtonItem = editButtonItem
        
        setupFetchedResultsController()
    
        updateEditButtonState()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupFetchedResultsController()

        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil
    }

    // MARK: - Actions

    @IBAction func addTapped(sender: Any) {
        addNote()
    }

    // MARK: - Editing

    // Adds a new `Note` to the end of the `notebook`'s `notes` array
    func addNote() {
        let note = Note(context: dataController.viewContext)
        
        note.text = "New Note"
        note.creationDate = Date()
        note.notebook = self.notebook
        
        try? dataController.viewContext.save() // save the context (error is not handled)
    }

    // Deletes the `Note` at the specified index path
    func deleteNote(at indexPath: IndexPath) {
        // get a reference to the note to delete
        let noteToDelete = fetchedResultsController.object(at: indexPath)
        
        // delete the note from the context
        dataController.viewContext.delete(noteToDelete)
        
        // try saving the context
        try? dataController.viewContext.save() // save the context (error is not handled)
    }

    func updateEditButtonState() {
        if let sections = fetchedResultsController.sections {
            navigationItem.rightBarButtonItem?.isEnabled = sections[0].numberOfObjects > 0
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If this is a NoteDetailsViewController, we'll configure its `Note`
        // and its delete action
        if let vc = segue.destination as? NoteDetailsViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                vc.note = fetchedResultsController.object(at: indexPath)
                vc.dataController = dataController

                vc.onDelete = { [weak self] in
                    if let indexPath = self?.tableView.indexPathForSelectedRow {
                        self?.deleteNote(at: indexPath)
                        self?.navigationController?.popViewController(animated: true)
                    }
                }
            }
        }
    }
}
