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
    
    var backgroundContext: NSManagedObjectContext!
    
    init(modelName: String) {
        // we need the name of the data model file
        persistentContainer = NSPersistentContainer(name: modelName)
    }
    
    func configureContexts() {
        // instantiate the background context
        backgroundContext = persistentContainer.newBackgroundContext() // creates a context associated with a private queue
        
        viewContext.automaticallyMergesChangesFromParent = true
        backgroundContext.automaticallyMergesChangesFromParent = true
        
        backgroundContext.mergePolicy = NSMergePolicy.mergeByPropertyObjectTrump // it will prefer its own property values in the case of a conflict
        viewContext.mergePolicy = NSMergePolicy.mergeByPropertyStoreTrump // it will prefer the property values from the persistent store in the case of a conflict
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
            self.configureContexts()
            
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

// // creates a background context that sticks around
// let backgroundContext = persistentContainer.newBackgroundContext()
//
// These 3 methods below are invaluable, you should always wrap your context's tasks in a perform call. If you don't, using a context on the wrong queue won't always crash your app. Unfortunately, the errors it causes can be intermitten and hard to debug. Because of this XCode provides a debug flag you can add to your scheme that will cause your app to crash immediately if you access a context from the wrong queue.

// To add the flag: Product -> Scheme -> Edit Scheme

// The 1 in -com.apple.CoreData.ConcurrencyDebug 1 indicates the level of detail in the stack trace. You can bump this up to 2 or 3 for more verbose output. It's a great idea to leave this set during development or debugging to identify any code running on the wrong queue.

//        // creates a temporary background context to perform a single piece of work (performs background task on the container)
//        persistentContainer.performBackgroundTask { context in
//            doSomeSlowWork()
//            try? context.save()
//        }
//
//        // dispatches asynchronously on the correct queue for that context
//        viewContext.perform {
//            doSomeWork()
//        }
//
//        // dispatches synchronously on the correct queue (performs and waits on the context itself)
//        viewContext.performAndWait {
//            doSomeWork()
//        }
