//
//  ViewController.swift
//  DomoArigato
//
//  Created by FLK on 20/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import UIKit
import CoreData
import Alamofire

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, NSFetchedResultsControllerDelegate {

    @IBOutlet weak var tableView: UITableView!
    var devices =  [NSManagedObject]()
    var showFavoritesOnly: Bool = false
    
    lazy var fetchedResultsController: NSFetchedResultsController = {

        let devicesFetchRequest = NSFetchRequest(entityName: "Device")

        let primarySortDescriptor = NSSortDescriptor(key: "type", ascending: true)
        let secondarySortDescriptor = NSSortDescriptor(key: "name", ascending: true)

        devicesFetchRequest.sortDescriptors = [primarySortDescriptor, secondarySortDescriptor]

        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate

        let frc = NSFetchedResultsController(
            fetchRequest: devicesFetchRequest,
            managedObjectContext: appDelegate.managedObjectContext,
            sectionNameKeyPath: "type",
            cacheName: nil)

        frc.delegate = self
        
        return frc
    }()
    
    // MARK: - View lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "reloadData:", forControlEvents: .ValueChanged)
        tableView.addSubview(refreshControl)
        
        self.refreshData()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func refreshData() {
        if self.showFavoritesOnly {
            fetchedResultsController.fetchRequest.predicate = NSPredicate(format: "isFavorite == %@", argumentArray: ["1"])
        }
        else {
            fetchedResultsController.fetchRequest.predicate = nil
        }

        do {
            NSFetchedResultsController.deleteCacheWithName(nil)
            print(fetchedResultsController.fetchRequest)
            try fetchedResultsController.performFetch()
            
            self.tableView.reloadData()
        } catch {
            print("An error occurred")
        }
    }
    
    
    // MARK: - Actions
    
    @IBAction func filterDevices(sender: UISegmentedControl) {
        
        print(" index \(sender.selectedSegmentIndex)")
        
        if sender.selectedSegmentIndex == 0 {
            self.showFavoritesOnly = false
        }
        else {
            self.showFavoritesOnly = true
        }
        
        self.refreshData()
    }

    @IBAction func reloadData(sender: AnyObject?) {
        print("reloadData from \(sender)")
        
        //self.items.removeAll()
        
        
        Alamofire.request(.GET, "http://192.168.1.29:8080/json.htm?type=devices&filter=all&used=true&order=Name")
            .responseJSON { response in
                //print(response.request)  // original URL request
                //print(response.response) // URL response
                //print(response.data)     // server data
                //print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    //Core Data
                    let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
                    let managedContext = appDelegate.managedObjectContext
                    let entity =  NSEntityDescription.entityForName("Device", inManagedObjectContext:managedContext)
                    
                    
                    if let result = JSON["result"] as? NSArray {
                        for item in result {
                            let obj = item as! NSDictionary
                            
                            let request = NSFetchRequest(entityName: "Device")
                            request.predicate = NSPredicate(format: "id == %@", argumentArray: [(obj.valueForKey("ID"))!])
                            
                            do {
                                let result = try managedContext.executeFetchRequest(request) as NSArray
                                
                                //print("Fetch ok: \(result)")
                                if result.count == 2 {
                                    continue
                                }
                                
                                if result.count == 1 {
                                    //update
                                    let device = result.objectAtIndex(0) as! NSManagedObject
                                    
                                    device.setValue(obj.valueForKey("Name"), forKey: "name")
                                    device.setValue(obj.valueForKey("ID"), forKey: "id")
                                    device.setValue(obj.valueForKey("TypeImg"), forKey: "type")
                                    device.setValue(obj.valueForKey("Data"), forKey: "data")
                                    device.setValue("\(obj.valueForKey("Favorite")!)", forKey: "isFavorite")
                                    
                                    //Save It
                                    do {
                                        try managedContext.save()
                                        //self.devices[self.devices.indexOf(olddevice)!] = device
                                        
                                    } catch let error as NSError  {
                                        print("Could not save \(error), \(error.userInfo)")
                                    }
                                }
                                else if result.count == 0 {
                                    //create new one
                                    let device = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: managedContext)
                                    device.setValue(obj.valueForKey("Name"), forKey: "name")
                                    device.setValue(obj.valueForKey("ID"), forKey: "id")
                                    device.setValue(obj.valueForKey("TypeImg"), forKey: "type")
                                    device.setValue(obj.valueForKey("Data"), forKey: "data")
                                    device.setValue("\(obj.valueForKey("Favorite")!)", forKey: "isFavorite")
                                    
                                    //Save It
                                    do {
                                        try managedContext.save()
                                        //self.devices.append(device)
                                        
                                    } catch let error as NSError  {
                                        print("Could not save \(error), \(error.userInfo)")
                                        
                                    }
                                }
                                
                                
                            } catch let error as NSError {
                                print("Fetch failed: \(error.localizedDescription)")
                                
                            }
                            
                        }
                    }
                    
                    if let refreshctrl = sender as? UIRefreshControl {
                        // sender is a UIRefreshControl.
                        refreshctrl.endRefreshing()
                    }
                    
                }
                
        }
    }

    
    // MARK: - UITableView DataSource
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        let device = fetchedResultsController.objectAtIndexPath(indexPath)
        //cell.textLabel?.text = "\(device.valueForKey("name")!) \(device.valueForKey("isFavorite")!)"
        cell.textLabel?.text = device.valueForKey("name") as? String
        cell.detailTextLabel?.text = device.valueForKey("data") as? String
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = fetchedResultsController.sections {
            return sections.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        
        return 0
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = fetchedResultsController.sections {
            let currentSection = sections[section]
            return currentSection.name
        }
        
        return nil
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

    func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func tableView(tableView: UITableView, commitEditingStyle editingStyle: UITableViewCellEditingStyle, forRowAtIndexPath indexPath: NSIndexPath) {
        
        
        if (editingStyle == UITableViewCellEditingStyle.Delete) {
            print("delete")
            let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
            let managedContext = appDelegate.managedObjectContext
            
            managedContext.deleteObject(fetchedResultsController.objectAtIndexPath(indexPath) as! NSManagedObject)
        }
        else {
            print("commit \(editingStyle)")
        }
    }

    // MARK: - UITableView Delegate
    func tableView(tableView: UITableView,
        didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            print("You selected cell #\(indexPath.row)!")
    }
    
    // MARK: - NSFetchedResultsControllerDelegate

    func controllerWillChangeContent(controller: NSFetchedResultsController) {
        self.tableView.beginUpdates()
    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeSection sectionInfo: NSFetchedResultsSectionInfo,
        atIndex sectionIndex: Int,
        forChangeType type: NSFetchedResultsChangeType) {
        
            //print("Section \(sectionIndex) at \(type)")
            
            switch type {
                case .Insert:
                    print("Insert")
                    self.tableView.insertSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Top)
                case .Update:
                    print("Update")
                case .Move:
                    print("Move")
                case .Delete:
                    print("Delete")
                    self.tableView.deleteSections(NSIndexSet(index: sectionIndex), withRowAnimation: .Bottom)
            }


    }
    
    func controller(controller: NSFetchedResultsController,
        didChangeObject object: AnyObject,
        atIndexPath indexPath: NSIndexPath?,
        forChangeType type: NSFetchedResultsChangeType,
        newIndexPath: NSIndexPath?) {
            
            //print("Object \(object) at \(indexPath)")
            
            switch type {
                case .Insert:
                    print("Insert")
                    self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Top)
                case .Update:
                    print("Update")
                    let cell = self.tableView.cellForRowAtIndexPath(indexPath!)
                    self.configureCell(cell!, atIndexPath: indexPath!)
                    self.tableView.reloadRowsAtIndexPaths([indexPath!], withRowAnimation: .None)
                case .Move:
                    print("Move")
                    self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Automatic)
                    self.tableView.insertRowsAtIndexPaths([newIndexPath!], withRowAnimation: .Automatic)
                case .Delete:
                    print("Delete \(indexPath)")
                    self.tableView.deleteRowsAtIndexPaths([indexPath!], withRowAnimation: .Bottom)
            }
    }

    func controllerDidChangeContent(controller: NSFetchedResultsController) {
        self.tableView.endUpdates()
    }
}

