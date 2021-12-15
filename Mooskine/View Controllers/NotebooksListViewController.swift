//
//  NotebooksListViewController.swift
//  Mooskine
//
//  Created by Josh Svatek on 2017-05-31.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import CoreData

class NotebooksListViewController: UIViewController {
    
    // MARK: - Outlets
    
    /// A table view that displays a list of notebooks
    @IBOutlet weak var tableView: UITableView!
    
    // MARK: - Properties
    
    var dataController: DataController! // we are implicitly unwrapping it because we can count on this dependency being injected
    var listDataSource: ListDataSource<Notebook, NotebookCell>!
    var fetchedResultsController: NSFetchedResultsController<Notebook>!
    
    // MARK: - Setup
    
    fileprivate func setUpDelegates() {
        // Set the required delegates
        tableView.dataSource = listDataSource
        fetchedResultsController.delegate = listDataSource
    }
    
    fileprivate func setUpListDataSource(_ fetchRequest: NSFetchRequest<Notebook>) {
        // Instantiate the listDataSource
        listDataSource = ListDataSource(tableView: tableView, managedObjectContext: dataController.viewContext, fetchRequest: fetchRequest, configure: { notebook, cell in
            cell.nameLabel.text = notebook.name
            if let count = notebook.notes?.count {
                let pageString = count == 1 ? "page" : "pages"
                cell.pageCountLabel.text = "\(count) \(pageString)"
            }
        })
        
        // Inject the data controller and fetched results controller dependencies into the listDataSource
        listDataSource.dataController = dataController
        listDataSource.fetchedResultsController = fetchedResultsController
    }
    
    fileprivate func setUpFetchedResultsController() {
        // Create the fetch request
        let fetchRequest: NSFetchRequest<Notebook> = Notebook.fetchRequest()
        let sortDescriptor = NSSortDescriptor(key: "creationDate", ascending: false)
        fetchRequest.sortDescriptors = [sortDescriptor]
        
        // Instantiate the fetchedResultsController
        fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: dataController.viewContext, sectionNameKeyPath: nil, cacheName: "notebooks")
        do {
            try fetchedResultsController.performFetch()
        } catch {
            fatalError("The fetch could not be performed: \(error.localizedDescription)")
        }
                
        setUpListDataSource(fetchRequest)
        setUpDelegates()
    }
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.titleView = UIImageView(image: #imageLiteral(resourceName: "toolbar-cow"))
        navigationItem.rightBarButtonItem = editButtonItem
        setUpFetchedResultsController()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setUpFetchedResultsController()
        if let indexPath = tableView.indexPathForSelectedRow {
            tableView.deselectRow(at: indexPath, animated: false)
            tableView.reloadRows(at: [indexPath], with: .fade)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        fetchedResultsController = nil //?
    }

    // MARK: - Actions

    @IBAction func addTapped(sender: Any) {
        presentNewNotebookAlert()
    }

    // MARK: - Editing

    /// Display an alert prompting the user to name a new notebook. Calls
    /// `addNotebook(name:)`.
    func presentNewNotebookAlert() {
        let alert = UIAlertController(title: "New Notebook", message: "Enter a name for this notebook", preferredStyle: .alert)

        // Create actions
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let saveAction = UIAlertAction(title: "Save", style: .default) { [weak self] action in
            if let name = alert.textFields?.first?.text {
                self?.addNotebook(name: name)
            }
        }
        saveAction.isEnabled = false

        // Add a text field
        alert.addTextField { textField in
            textField.placeholder = "Name"
            NotificationCenter.default.addObserver(forName: UITextField.textDidChangeNotification, object: textField, queue: .main) { notif in
                if let text = textField.text, !text.isEmpty {
                    saveAction.isEnabled = true
                } else {
                    saveAction.isEnabled = false
                }
            }
        }

        alert.addAction(cancelAction)
        alert.addAction(saveAction)
        present(alert, animated: true, completion: nil)
    }

    /// Adds a new notebook to the end of the `notebooks` array
    func addNotebook(name: String) {
        // Update the model:
        
        // make changes in a context, and then ask the context to save the changes to the persistent store
        let notebook = Notebook(context: dataController.viewContext)
        notebook.name = name // set the name
        notebook.creationDate = Date() // set the creation date
        try? dataController.viewContext.save() // saves the notebook to the persistent store
    }

    /// Deletes the notebook at the specified index path
    func deleteNotebook(at indexPath: IndexPath) {
        let notebookToDelete = fetchedResultsController.object(at: indexPath)
        dataController.viewContext.delete(notebookToDelete)
        try? dataController.viewContext.save()
    }

    func updateEditButtonState() {
        if let sections = fetchedResultsController.sections {
            navigationItem.rightBarButtonItem?.isEnabled = sections[0].numberOfObjects > 0 // numberOfNotebooks > 0
        }
    }

    override func setEditing(_ editing: Bool, animated: Bool) {
        super.setEditing(editing, animated: animated)
        tableView.setEditing(editing, animated: animated)
    }

    // MARK: - Navigation

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // If this is a NotesListViewController, we'll configure its `Notebook`
        if let vc = segue.destination as? NotesListViewController {
            if let indexPath = tableView.indexPathForSelectedRow {
                // We pass both the notebook and core data stack to the Notes List View Controller once a note book is selected
                vc.notebook = fetchedResultsController.object(at: indexPath)
                vc.dataController = dataController // dependency injection
            }
        }
    }
}
