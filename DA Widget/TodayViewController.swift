//
//  TodayViewController.swift
//  DA Widget
//
//  Created by FLK on 20/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var LogView: UITextView!
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var TempBtn: UIButton!
    @IBOutlet weak var TempLabel: UILabel!
    
    var nbR: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        print("viewDidLoad")

        
        let managedContext = self.managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: "Device")
        fetchRequest.predicate = NSPredicate(format: "id == %@", argumentArray: ["E802"])
        
        //fetchRequest.returnsObjectsAsFaults = false
        do {
            let results = try managedContext.executeFetchRequest(fetchRequest) as NSArray
            print(results)
            let tmpdevice = results.objectAtIndex(0) as! NSManagedObject
            
            self.TempLabel.text = tmpdevice.valueForKey("data") as? String

            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            
        }
        
        
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        // Dispose of any resources that can be recreated.
    }
    
    func widgetMarginInsetsForProposedMarginInsets
        (defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
            print (defaultMarginInsets)
            

            var inset = defaultMarginInsets
            
            inset.bottom = 10
            inset.top = 10
            inset.right = 10

            print (inset)

            return inset//UIEdgeInsetsZero
    }

    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        print("widgetPerformUpdateWithCompletionHandler", terminator: "")
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
       
        //self.TempLabel.text = "widgetPerformUpdateWithCompletionHandler"
        //self.LogView.text = "\(NSDate()) widgetPerform\n\(self.LogView.text)"
        self.RefreshTemp(self.TempBtn)
        
        completionHandler(NCUpdateResult.NewData)
        
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("viewDidAppear", terminator: "")
        //self.LogView.text = "\(NSDate()) viewDidAppear\n\(self.LogView.text)"
        self.RefreshTemp(self.TempBtn)
    }
    
    @IBAction func RefreshTemp(sender: UIButton) {
        self.ActivityIndicator.startAnimating()
        Alamofire.request(.GET, "http://192.168.1.29:8080/json.htm?type=devices&filter=all&used=true&order=Name")
            .responseJSON { response in
                //print(response.request)  // original URL request
                //print(response.response) // URL response
                //print(response.data)     // server data
                //print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    //print("JSON: \(JSON)")
                    
                    if let result = JSON["result"] as? NSArray {
                        for item in result {
                            let obj = item as? NSDictionary
                            if let isFavorite = obj?.objectForKey("Favorite") {
                                if (isFavorite.integerValue == 1) {
                                    if (obj?.objectForKey("TypeImg") as? String == "temperature") {
                                        print(obj)
                                        let data = obj?.objectForKey("Data") as? String
                                        
                                        self.TempLabel.text = data
                                        
                                        self.TempBtn.setTitle("\(self.nbR)", forState: UIControlState.Normal)
                                        self.nbR += 1

                                        self.ActivityIndicator.stopAnimating()
                                        
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
        }
    }
    
    
    
    // MARK: - Core Data stack
    
    lazy var applicationDocumentsDirectory: NSURL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "com.flkone.DomoArigato" in the application's documents Application Support directory.
        let urls = NSFileManager.defaultManager().containerURLForSecurityApplicationGroupIdentifier("group.domoarigato")
        print(urls)
        //        let urls = NSFileManager.defaultManager().URLsForDirectory(.DocumentDirectory, inDomains: .UserDomainMask)
        return urls!//[urls.count-1]
    }()
    
    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = NSBundle.mainBundle().URLForResource("DomoArigato", withExtension: "momd")!
        return NSManagedObjectModel(contentsOfURL: modelURL)!
    }()
    
    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        // Create the coordinator and store
        let coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
        let url = self.applicationDocumentsDirectory.URLByAppendingPathComponent("SingleViewCoreData.sqlite")
        var failureReason = "There was an error creating or loading the application's saved data."
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
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
        
        return coordinator
    }()
    
    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .MainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }()
    
    // MARK: - Core Data Saving support
    
    func saveContext () {
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nserror = error as NSError
                NSLog("Unresolved error \(nserror), \(nserror.userInfo)")
                abort()
            }
        }
    }
    
}