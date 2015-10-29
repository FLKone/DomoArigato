//
//  CoreDataStore.swift
//  DomoArigato
//
//  Created by FLK on 28/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import Foundation

import Foundation
import CoreData

public class CoreDataStore: NSObject {
    
    
    class var sharedInstance : CoreDataStore {
        struct Static {
            static let instance : CoreDataStore = CoreDataStore()
        }
        return Static.instance
    }
    
    override init() {
        super.init()
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSavePrivateQueueContext:", name: NSManagedObjectContextDidSaveNotification, object: self.privateQueueCtxt)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextDidSaveMainQueueContext:", name: NSManagedObjectContextDidSaveNotification, object: self.mainQueueCtxt)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Notifications
    
    func contextDidSavePrivateQueueContext(notification: NSNotification) {
        //print("contextDidSavePrivateQueueContext \(notification)")
        if let context = self.mainQueueCtxt {
            self.synced(self, closure: { () -> () in
                context.performBlock({() -> Void in
                    context.mergeChangesFromContextDidSaveNotification(notification)
                })
            })
        }
    }
    
    func contextDidSaveMainQueueContext(notification: NSNotification) {
        //print("contextDidSaveMainQueueContext \(notification)")

        if let context = self.privateQueueCtxt {
            self.synced(self, closure: { () -> () in
                context.performBlock({() -> Void in
                    context.mergeChangesFromContextDidSaveNotification(notification)
                })
            })
        }
    }
    
    func synced(lock: AnyObject, closure: () -> ()) {
        objc_sync_enter(lock)
        closure()
        objc_sync_exit(lock)
    }
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.AnyTap.Swift_Widget" in the application's documents Application Support directory.
        let url = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier(kAppGroup)
        return url!
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("DomoArigato", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator? = {
        // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        let options = [NSMigratePersistentStoresAutomaticallyOption: true]
        do {
            try coordinator.addPersistentStoreWithType(NSSQLiteStoreType, configuration: nil, URL: url, options: options)
        } catch {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data"
            dict[NSLocalizedFailureReasonErrorKey] = failureReason
            
            dict[NSUnderlyingErrorKey] = error as NSError
            let wrappedError = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            NSLog("Unresolved error \(wrappedError), \(wrappedError.userInfo)")
            abort()
        }
        
        print("\(coordinator.persistentStores)")
        return coordinator
    }()
    
    // MARK: - NSManagedObject Contexts
    
    public class func mainQueueContext() -> NSManagedObjectContext {
        print("mainQueueContext")
        return self.sharedInstance.mainQueueCtxt!
    }
    
    public class func privateQueueContext() -> NSManagedObjectContext {
        print("privateQueueContext")
        return self.sharedInstance.privateQueueCtxt!
    }
    
    lazy var mainQueueCtxt: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        var managedObjectContext = NSManagedObjectContext(concurrencyType:.MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }()
    
    lazy var privateQueueCtxt: NSManagedObjectContext? = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        var managedObjectContext = NSManagedObjectContext(concurrencyType:.PrivateQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = self.persistentStoreCoordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    

    
    public class func saveContext (context: NSManagedObjectContext?) throws -> NSError? {
        print("saveContext")
        if context!.hasChanges {
            do {
                try context!.save()
                
                return nil
            } catch let caught as NSError {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                return caught
            }
        }
        return nil

    }
}

// MARK: - NSManagedObject Extension

extension NSManagedObject {
    
    public class func createInContext(entityName: String, context: NSManagedObjectContext) -> AnyObject {
        let entity = NSEntityDescription.entityForName(entityName, inManagedObjectContext: context)
        return NSManagedObject(entity: entity!, insertIntoManagedObjectContext: context)
    }
    
    public class func findAllInContext(entityName: String, context: NSManagedObjectContext) -> [AnyObject]? {
        let request = NSFetchRequest(entityName: entityName)
        var result: [AnyObject]?
        request.returnsObjectsAsFaults = false

        do {
            result = try context.executeFetchRequest(request)
        } catch let error as NSError {
            print("Fetch failed: \(error.localizedDescription)")
            
        }
        return result
    }
}

