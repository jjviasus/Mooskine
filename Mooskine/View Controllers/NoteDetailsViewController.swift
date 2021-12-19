//
//  NoteDetailsViewController.swift
//  Mooskine
//
//  Created by Josh Svatek on 2017-05-31.
//  Copyright © 2017 Udacity. All rights reserved.
//

import UIKit
import CoreData

// This is where the user sees and edits individual notes.
class NoteDetailsViewController: UIViewController {
    /// A text view that displays a note's text
    @IBOutlet weak var textView: UITextView!

    /// The note being displayed and edited
    var note: Note! // injected before view controller is displayed
    
    var dataController: DataController! // injected before view controller is displayed (previous view passes it to us during the segue)
    
    var saveObserverToken: Any?

    /// A closure that is run when the user asks to delete the current note
    var onDelete: (() -> Void)?

    /// A date formatter for the view controller's title text
    let dateFormatter: DateFormatter = {
        let df = DateFormatter()
        df.dateStyle = .medium
        return df
    }()

    /// The accessory view used when displaying the keyboard
    var keyboardToolbar: UIToolbar?

    override func viewDidLoad() {
        super.viewDidLoad()

        if let creationDate = note.creationDate {
            navigationItem.title = dateFormatter.string(from: creationDate)
        }
        textView.attributedText = note.attributedText

        // keyboard toolbar configuration
        configureToolbarItems()
        configureTextViewInputAccessoryView()
        
        addSaveNotificationObserver()
    }
    
    deinit {
        removeSaveNotificationObserver()
    }

    @IBAction func deleteNote(sender: Any) {
        presentDeleteNotebookAlert()
    }
}

// -----------------------------------------------------------------------------
// MARK: - Editing

extension NoteDetailsViewController {
    func presentDeleteNotebookAlert() {
        let alert = UIAlertController(title: "Delete Note", message: "Do you want to delete this note?", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Delete", style: .destructive, handler: deleteHandler))
        present(alert, animated: true, completion: nil)
    }

    func deleteHandler(alertAction: UIAlertAction) {
        onDelete?()
    }
}

// -----------------------------------------------------------------------------
// MARK: - UITextViewDelegate

extension NoteDetailsViewController: UITextViewDelegate {
    func textViewDidEndEditing(_ textView: UITextView) {
        note.attributedText = textView.attributedText
        // try? note.managedObjectContext?.save()
        try? dataController.viewContext.save()
    }
}

// MARK: - Toolbar

extension NoteDetailsViewController {
    /// Returns an array of toolbar items. Used to configure the view controller's
    /// `toolbarItems' property, and to configure an accessory view for the
    /// text view's keyboard that also displays these items.
    func makeToolbarItems() -> [UIBarButtonItem] {
        let trash = UIBarButtonItem(barButtonSystemItem: .trash, target: self, action: #selector(deleteTapped(sender:)))
        let space = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        let bold = UIBarButtonItem(image: #imageLiteral(resourceName: "toolbar-bold"), style: .plain, target: self, action: #selector(boldTapped(sender:)))
        let red = UIBarButtonItem(image: #imageLiteral(resourceName: "toolbar-underline"), style: .plain, target: self, action: #selector(redTapped(sender:)))
        let cow = UIBarButtonItem(image: #imageLiteral(resourceName: "toolbar-cow"), style: .plain, target: self, action: #selector(cowTapped(sender:)))
        
        return [trash, space, bold, red, cow]
    }

    /// Configure the current toolbar
    func configureToolbarItems() {
        toolbarItems = makeToolbarItems()
        navigationController?.setToolbarHidden(false, animated: false)
        }

    /// Configure the text view's input accessory view -- this is the view that
    /// appears above the keyboard. We'll return a toolbar populated with our
    /// view controller's toolbar items, so that the toolbar functionality isn't
    /// hidden when the keyboard appears
    func configureTextViewInputAccessoryView() {
        let toolbar = UIToolbar(frame: CGRect(x: 0, y: 0, width: view.bounds.width, height: 44))
        toolbar.items = makeToolbarItems()
        textView.inputAccessoryView = toolbar
    }

    @IBAction func deleteTapped(sender: Any) {
        showDeleteAlert()
    }
    
    @IBAction func boldTapped(sender: Any) {
        let newText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        newText.addAttribute(.font, value: UIFont(name: "OpenSans-Bold", size: 22)!, range: textView.selectedRange)
        
        let selectedTextRange = textView.selectedTextRange
        
        textView.attributedText = newText
        textView.selectedTextRange = selectedTextRange
        note.attributedText = textView.attributedText
        try? dataController.viewContext.save()
    }
    
    @IBAction func redTapped(sender: Any) {
        let newText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        let attributes:[NSAttributedString.Key: Any] = [
            .foregroundColor: UIColor.red,
            .underlineStyle: 1,
            .underlineColor: UIColor.red
        ] // allows us to set multiple attributes at once
        newText.addAttributes(attributes, range: textView.selectedRange)
        
        let selectedTextRange = textView.selectedTextRange
        
        textView.attributedText = newText
        textView.selectedTextRange = selectedTextRange
        note.attributedText = textView.attributedText
        try? dataController.viewContext.save()
    }
    
    @IBAction func cowTapped(sender: Any) {
        let backgroundContext:NSManagedObjectContext! = dataController.backgroundContext
        
        let newText = textView.attributedText.mutableCopy() as! NSMutableAttributedString
        
        let selectedRange = textView.selectedRange
        let selectedText = textView.attributedText.attributedSubstring(from: selectedRange)
        
        // Every managed object has an identifier that's consitent across contexts. We can access it through the objectID property.
        
        // We store the note's ID before we enter the perform block.
        let noteID = note.objectID
        
        // Since UI kit isn't thread safe, we shouldn't access any UI elements from the background. So we won't include any UI code in the perform block. We will have all our foreground dependent code up top. We also can't access any viewContext objects in our perform block. The note instance is associated with the viewContext, so we can't use this note instance in the background. We need another note instance.
        backgroundContext.perform {
            // we need to get a matching note instance associated with the background context
            let backgroundNote = backgroundContext.object(with: noteID) as! Note
            
            let cowText = Pathifier.makeMutableAttributedString(for: selectedText, withFont: UIFont(name: "AvenirNext-Heavy", size: 56)!, withPatternImage: #imageLiteral(resourceName: "texture-cow"))
            newText.replaceCharacters(in: selectedRange, with: cowText)
            
            sleep(5)
            
            // update the attributed text of the background note to use the new text
            backgroundNote.attributedText = newText
            
            // save the changes in the background context
            try? backgroundContext.save()
        }
        
//        // Update the UI
//        textView.attributedText = newText
//        textView.selectedRange = NSMakeRange(selectedRange.location, 1)
    }

    // MARK: Helper methods for actions
    private func showDeleteAlert() {
        let alert = UIAlertController(title: "Delete Note?", message: "Are you sure you want to delete the current note?", preferredStyle: .alert)

        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive) { [weak self] _ in
            guard let strongSelf = self else { return }
            strongSelf.onDelete?()
        }

        alert.addAction(cancelAction)
        alert.addAction(deleteAction)
        present(alert, animated: true, completion: nil)
    }
}

// All we've done here is request to be notified when data in the view context has changed, so that we can handle that event and reload the text.
extension NoteDetailsViewController {
    
    func removeSaveNotificationObserver() {
        // check whether the saveObserverToken property has a value
        if let token = saveObserverToken {
            // remove it from notification center
            NotificationCenter.default.removeObserver(token)
        }
    }
    
    func addSaveNotificationObserver() {
        // Remove any existing observer
        removeSaveNotificationObserver()
        
        // Set the token
        saveObserverToken = NotificationCenter.default.addObserver(
            forName: .NSManagedObjectContextObjectsDidChange, // we watch for this
            object: dataController.viewContext, // on the view context
            queue: nil, // run the block synchronously on the posting thread
            using: handleSaveNotification(notification:)) // the block to run
    }
    
    // reload the text
    fileprivate func reloadText() {
        textView.attributedText = note.attributedText
    }
    
    // handles the notifications when they come
    func handleSaveNotification(notification: Notification) {
        // make sure we dispath this code on the main queue
        DispatchQueue.main.async {
            self.reloadText()
        }
    }
}
