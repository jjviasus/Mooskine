//
//  DataController.swift
//  Mooskine
//
//  Created by Justin Viasus on 12/7/21.
//  Copyright © 2021 Udacity. All rights reserved.
//

import Foundation
import CoreData

// class instead of struct because it will be passed between view controllers and we don't want to create multiple copies when doing so.

// holds a persistent container instance, loads the persistent store, and accesses the context. (The Core Data stack)
class DataController {
    // we make it immutable (let) because the persistentContainer shouldn't change over the life of the data controller
    let persistentContainer: NSPersistentContainer
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext // the viewContext is associated with the main queue
    }
    
    init(modelName: String) {
        // we need the name of the data model file
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    // takes in a completion as a parameter, which is optional and defaults to nil.
    func load(completion: (() -> Void)? = nil) { // () means of type closure.
        // loadPersistentStores accepts a completion handler as its only parameter.
        persistentContainer.loadPersistentStores { storeDescription, error in
            // The loading of the persistent stores has completed and everything below will be executed.
            
            guard error == nil else {
                fatalError(error!.localizedDescription)
            }
            
            self.autoSaveViewContext()
            
            // The passed in function gets called after loading the store.
            completion?()
        }
    }
}

extension DataController {
    // saves the view context and recursively calls itself again every so often
    func autoSaveViewContext(interval: TimeInterval = 30) {
        print("autosaving")
        guard interval > 0 else {
            print("cannot set negative autosave interval")
            return
        }

        // we only want to save if the view context has changes
        if viewContext.hasChanges {
            try? viewContext.save() // error not handled
        }
        
        // calls autosave again after the specified interval has ellapsed
        DispatchQueue.main.asyncAfter(deadline: .now() + interval) {
            self.autoSaveViewContext(interval: interval)
        }
    }
}
