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

class TodayViewController: UIViewController, NCWidgetProviding, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    
    /*
    @IBOutlet weak var LogView: UITextView!

    @IBOutlet weak var TempBtn: UIButton!
    @IBOutlet weak var TempLabel: UILabel!
    */
    var devices = [NSManagedObject]()
    var nbR: Int = 0
    var lastLoadDate: NSDate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        //self.tableView.tableFooterView = UIView(frame: CGRectMake(0, 0, 1, 1))

        self.preferredContentSize = CGSizeMake(self.view.frame.width, 80);
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero//UIEdgeInsetsMake(10, 10, 10, 10)
    }
    
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        
        self.reloadData(nil)
        completionHandler(NCUpdateResult.NewData)
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        // on first load view is already loaded from widgetPerformUpdateWithCompletionHandler, on subsquents calls lastLoadData wont be nil
        if self.lastLoadDate != nil {
            self.reloadData(nil)
        }

    }
    
    
    
    func refreshData() {
        
        
        let managedContext = self.managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: "Device")
        //fetchRequest.predicate = NSPredicate(format: "(isFavorite == %@) AND (type == %@)", argumentArray: ["1", "temperature"])
        fetchRequest.predicate = NSPredicate(format: "(isFavorite == %@)", argumentArray: [true])
        let primarySortDescriptor = NSSortDescriptor(key: "type", ascending: false)
        let secondarySortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        
        fetchRequest.sortDescriptors = [primarySortDescriptor, secondarySortDescriptor]

        
        do {
            let tempDevices = try managedContext.executeFetchRequest(fetchRequest) as! [NSManagedObject]
            self.lastLoadDate = NSDate()
            
            devices = tempDevices
            self.collectionView.reloadSections(NSIndexSet(index: 0))
            
            /*
            if devices.count == 0 {

            }
            else {
                devices = tempDevices
                self.collectionView.reloadData()
            }
*/
            
            print("r= \(devices)")
            print("r= \(devices.count)")
            

//            self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)])
//            self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: 1, inSection: 0)])
            
            /*[self.collectionView performBatchUpdates:^{
                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            } completion:nil];
            */
            
            print("=== After Reload \(self.preferredContentSize)")
            //self.preferredContentSize = self.collectionView.contentSize
            print("=== After Reload 2 \(self.preferredContentSize)")
            //self.tableView.reloadData()
            
            //print("preferredContentSize= \(self.preferredContentSize)")
            //print("contentSize= \(self.tableView.contentSize)")

            //self.preferredContentSize = self.tableView.contentSize;
            //self.tableView.hidden = false;
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        


    }
    
    @IBAction func reloadData(sender: AnyObject?) {
        //self.ActivityIndicator.startAnimating()
        Alamofire.request(.GET, "http://192.168.1.29:8080/json.htm?type=devices&filter=all&used=true&order=Name")
            .responseJSON { response in
                //print(response.request)  // original URL request
                //print(response.response) // URL response
                //print(response.data)     // server data
                //print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    //Core Data
                    let managedContext = self.managedObjectContext
                    let entity =  NSEntityDescription.entityForName("Device", inManagedObjectContext:managedContext)
                    
                    //print(JSON)
                    if let result = JSON["result"] as? NSArray {
                        for item in result {
                            let obj = item as! NSDictionary
                            
                            let request = NSFetchRequest(entityName: "Device")
                            request.predicate = NSPredicate(format: "id == %@", argumentArray: [(obj.valueForKey("idx"))!])
                            
                            do {
                                let result = try managedContext.executeFetchRequest(request) as NSArray
                                
                                //print("Fetch ok: \(result)")
                                if result.count == 2 {
                                    continue
                                }
                                
                                if result.count == 1 {
                                    //update
                                    let device = result.objectAtIndex(0) as! NSManagedObject
                                    
                                    print("\(obj.valueForKey("idx")!) \(obj.valueForKey("Name")!)=\(obj.valueForKey("Data")!) Fav:\(obj.valueForKey("Favorite")!)")
                                        
                                    device.setValue(obj.valueForKey("Name"), forKey: "name")
                                    device.setValue(obj.valueForKey("idx"), forKey: "id")
                                    device.setValue(obj.valueForKey("TypeImg"), forKey: "type")
                                    device.setValue(obj.valueForKey("Data"), forKey: "data")
                                    if let isFavorite = obj.valueForKey("Favorite")?.integerValue {
                                        device.setValue(Bool(isFavorite), forKey: "isFavorite")
                                    }
                                    
                                    //Save It
                                    do {
                                        try managedContext.save()
                                        
                                    } catch let error as NSError  {
                                        print("Could not save \(error), \(error.userInfo)")
                                    }
                                }
                                else if result.count == 0 {
                                    //create new one
                                    let device = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
                                    device.setValue(obj.valueForKey("Name"), forKey: "name")
                                    device.setValue(obj.valueForKey("idx"), forKey: "id")
                                    device.setValue(obj.valueForKey("TypeImg"), forKey: "type")
                                    device.setValue(obj.valueForKey("Data"), forKey: "data")
                                    if let isFavorite = obj.valueForKey("Favorite")?.integerValue {
                                        device.setValue(Bool(isFavorite), forKey: "isFavorite")
                                    }
                                    
                                    //Save It
                                    do {
                                        try managedContext.save()
                                        
                                    } catch let error as NSError  {
                                        print("Could not save \(error), \(error.userInfo)")
                                        
                                    }
                                }
                                
                                
                            } catch let error as NSError {
                                print("Fetch failed: \(error.localizedDescription)")
                                
                            }
                            
                        }
                    }
                    
                    self.refreshData()
                    
                    //delay(4) {
                      //  self.ActivityIndicator.stopAnimating()
                    //}
                }
                
        }
        
        
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            print("sizeForItemAtIndexPath 2")
            
            let nbItem = self.collectionView(self.collectionView, numberOfItemsInSection: indexPath.section) as Int
            
            let leftInset = ((self.view.frame.width - 40 - CGFloat(10*(nbItem-1))) / CGFloat(nbItem))
            
            return CGSize(width: leftInset, height: 54)
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            
            
            //print("insetForSectionAtIndex \(nbItem)")
            
            //let leftInset = (self.view.frame.width - CGFloat(54*nbItem) - CGFloat(10*(nbItem-1))) / 2
            return UIEdgeInsets(top: 8.0, left: 20, bottom: 12.0, right: 20)

//            return UIEdgeInsets(top: 10.0, left: leftInset, bottom: 10.0, right: 10)
            
            
    }
    
    
    // MARK: - UICollectionView DataSource

    
    func configureCell(cell: UICollectionViewCell, atIndexPath indexPath: NSIndexPath, type: String) {
        let device = devices[indexPath.row]
        //print("config cell \(device)")
        let nameLabel = cell.viewWithTag(1) as? UILabel
        let dataLabel = cell.viewWithTag(2) as? UILabel
        let typeImage = cell.viewWithTag(3) as? UIImageView
        
        nameLabel?.text = device.valueForKey("name") as? String

        let data = device.valueForKey("data") as! String

        switch type {
            case "temperature" :
                typeImage?.image = UIImage(named: "TemperatureOff")
                //typeImage?.highlightedImage = UIImage(named: "TemperatureOn")

                dataLabel?.text = data.stringByReplacingOccurrencesOfString(" C", withString: "").stringByReplacingOccurrencesOfString(" F", withString: "")
                typeImage?.highlighted = false
            case "lightbulb" :
                //typeImage?.image = UIImage(named: "SwitchOff")
                //typeImage?.highlightedImage = UIImage(named: "SwitchOn")
                
                dataLabel?.text = device.valueForKey("data") as? String
                typeImage?.image = UIImage(named: ((data == "On") ? "SwitchOn" : "SwitchOff"))

            default:
                dataLabel?.text = device.valueForKey("data") as? String

        }
        
        //cell.backgroundColor = UIColor.lightGrayColor()
    }

    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print("select \(indexPath)")
    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func collectionView(collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
            
            print("numberOfItemsInSection \(devices.count)")

            return devices.count;
    }
    
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
            
        print("cellForItemAtIndexPath")
            
        var cell:UICollectionViewCell

        let device = devices[indexPath.row]
        let type = device.valueForKey("type") as! String
        switch type {
            case "temperature" :
                cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("TempCell", forIndexPath: indexPath)
                self.configureCell(cell, atIndexPath: indexPath, type: "temperature")
            case "lightbulb" :
                cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("SwitchCell", forIndexPath: indexPath)
                self.configureCell(cell, atIndexPath: indexPath, type: "lightbulb")
            default:
                cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("UtilCell", forIndexPath: indexPath)
                self.configureCell(cell, atIndexPath: indexPath, type: "default")
        }
            
        print("cellForItemAtIndexPath \(cell)")
            
        return cell
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