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

    @IBOutlet weak var ReloadButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    var devices =  [NSManagedObject]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        self.refreshData(nil)
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        
        let appDelegate = UIApplication.sharedApplication().delegate as! AppDelegate
        let managedContext = appDelegate.managedObjectContext
        
        let fetchRequest = NSFetchRequest(entityName: "Device")
        
        do {
            let results =
            try managedContext.executeFetchRequest(fetchRequest)
            devices = results as! [NSManagedObject]
            
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
            
        }
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    
    // MARK: - UITableView DataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return devices.count;
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = self.tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
        
        let device = devices[indexPath.row]
        
        cell.textLabel!.text = device.valueForKey("name") as? String
        cell.detailTextLabel!.text = device.valueForKey("data") as? String

        if (device.valueForKey("type") as? String == "lightbulb") {
            print("row: \(cell.textLabel?.text) light : \(device.valueForKey("data"))")
        }
        else if (device.valueForKey("type") as? String == "temperature") {
            print("row: \(cell.textLabel?.text) temp : \(device.valueForKey("data"))")

        }

        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        print("You selected cell #\(indexPath.row)!")
    }
    

    @IBAction func refreshData(sender: AnyObject?) {
        print("refreshData from \(sender)")
        
        //self.items.removeAll()
        
        
        Alamofire.request(.GET, "http://192.168.1.29:8080/json.htm?type=devices&filter=all&used=true&order=Name")
            .responseJSON { response in
                //print(response.request)  // original URL request
                //print(response.response) // URL response
                //print(response.data)     // server data
                //print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    //print("JSON: \(JSON)")
                    
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
                                    let olddevice = device


                                    device.setValue(obj.valueForKey("Name"), forKey: "name")
                                    device.setValue(obj.valueForKey("ID"), forKey: "id")
                                    device.setValue(obj.valueForKey("TypeImg"), forKey: "type")
                                    device.setValue(obj.valueForKey("Data"), forKey: "data")
                                    device.setValue("\(obj.valueForKey("Favorite")!)", forKey: "isFavorite")
                                    
                                    //Save It
                                    do {
                                        try managedContext.save()
                                        self.devices[self.devices.indexOf(olddevice)!] = device
                                        
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
                                        self.devices.append(device)
                                        
                                    } catch let error as NSError  {
                                        print("Could not save \(error), \(error.userInfo)")
                                        
                                    }
                                }
                                
                                
                            } catch let error as NSError {
                                print("Fetch failed: \(error.localizedDescription)")

                            }

                        }
                    }
                    
                    self.tableView.reloadData()
                    
                }
        }
    }
}

