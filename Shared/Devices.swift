//
//  Devices.swift
//  DomoArigato
//
//  Created by FLK on 28/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import Foundation
import CoreData
import Alamofire


public class Devices:NSObject {
    static let sharedInstance = Devices()
    private let context = CoreDataStore.privateQueueContext()
    
    private override init() {
        super.init()
        print("==== INIT DEVICES")
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextShouldReset:", name: kContextChangedNotification, object: nil)
    } //This prevents others from using the default '()' initializer for this class.

    deinit {
        print("==== DEINIT DEVICES")
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    public func contextShouldReset(notification: NSNotification) {
        print("contextShouldReset \(notification)")
        // Reset changed context
        self.context.reset()
    }

    // MARK: Privates
    
    private func fetch( favorites favoritesOnly: Bool = false,
                        grouped groupResults: Bool = true,
                        completion:(devicesController :NSFetchedResultsController) ->())
    {
        
        let devicesFetchRequest = NSFetchRequest(entityName: "Device")
        
        let primarySortDescriptor = NSSortDescriptor(key: "type", ascending: false)
        let secondarySortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        
        devicesFetchRequest.sortDescriptors = [primarySortDescriptor, secondarySortDescriptor]
        
        if favoritesOnly {
            devicesFetchRequest.predicate = NSPredicate(format: "(isFavorite == %@)", argumentArray: [true])
        }
        
        NSLog("grouped = \((groupResults ? "type" : "no group"))")
        NSLog("context \(self.context)")
        let frc = NSFetchedResultsController(
            fetchRequest: devicesFetchRequest,
            managedObjectContext: self.context,
            sectionNameKeyPath: (groupResults ? "type" : nil),
            cacheName: nil)
        
        // TODO: Manager NSFetchedResultsController delegate
        //frc.delegate = self
        
        self.context.performBlock {
            NSLog("fetch > PERFORM BLOCK START")
            
            do {
                try frc.performFetch()
                
                
                dispatch_async(dispatch_get_main_queue(),{
                    completion(devicesController: frc)
                })
                
                NSLog("fetch > PERFMOR BLOCK END")
                
                
            } catch let error as NSError {
                NSLog("Could not fetch \(error), \(error.userInfo)")
                
            }
            
        }

    }
    
    private func update(completion:() ->()) {
        
        NSLog("update IN")
        
        Alamofire.request(.GET, "http://192.168.1.29:8080/json.htm?type=devices&filter=all&used=true&order=Name")
        .responseJSON { response in
            //print(response.request)  // original URL request
            //print(response.response) // URL response
            //print(response.data)     // server data
            //print(response.result)   // result of response serialization
            
            if let JSON = response.result.value {
                
                //Core Data
                let entity =  NSEntityDescription.entityForName("Device", inManagedObjectContext:self.context)
                
                
                if let result = JSON["result"] as? NSArray {
                    for item in result {
                        let obj = item as! NSDictionary
                        
                        let request = NSFetchRequest(entityName: "Device")
                        
                        print("looking for idx=\((obj.valueForKey("idx"))!)")
                        
                        request.predicate = NSPredicate(format: "id == %@", argumentArray: [(obj.valueForKey("idx"))!])
                        request.returnsObjectsAsFaults = false

                        // TODO: Delete removed devices (or hide)
                        
                        do {
                            let result = try self.context.executeFetchRequest(request) as NSArray
                            
                            //print("Fetch ok")
                            if result.count == 2 {
                                continue
                            }
                            
                            if result.count == 1 {
                                //update
                                let device = result.objectAtIndex(0) as! NSManagedObject
                                
                                device.setValue(obj.valueForKey("Name"), forKey: "name")
                                device.setValue(obj.valueForKey("idx"), forKey: "id")
                                device.setValue(obj.valueForKey("TypeImg"), forKey: "type")
                                device.setValue(obj.valueForKey("Data"), forKey: "data")
                                if let isFavorite = obj.valueForKey("Favorite")?.integerValue {
                                    NSLog("update > Updated Device = \(obj.valueForKey("Name")) = \(obj.valueForKey("Data")) | Fav=\(Bool(isFavorite))")
                                    device.setValue(Bool(isFavorite), forKey: "isFavorite")
                                }
                            }
                            else if result.count == 0 {
                                //create new one
                                let device = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: self.context)
                                device.setValue(obj.valueForKey("Name"), forKey: "name")
                                device.setValue(obj.valueForKey("idx"), forKey: "id")
                                device.setValue(obj.valueForKey("TypeImg"), forKey: "type")
                                device.setValue(obj.valueForKey("Data"), forKey: "data")
                                if let isFavorite = obj.valueForKey("Favorite")?.integerValue {
                                    NSLog("update > New Device = \(obj.valueForKey("Name")) = \(obj.valueForKey("Data")) | Fav=\(Bool(isFavorite))")
                                    device.setValue(Bool(isFavorite), forKey: "isFavorite")
                                }

                            }
                            
                            //Save It
                            do {
                                try CoreDataStore.saveContext(self.context)
                            } catch let error as NSError  {
                                print("Could not save \(error), \(error.userInfo)")
                                
                            }
                            
                        } catch let error as NSError {
                            print("Fetch failed: \(error.localizedDescription)")
                            
                        }

                    }
                    
                }
            
                dispatch_async(dispatch_get_main_queue(),{
                    NSLog("update END, dispatch callback")
                    completion()
                })
                
            }
        }
    }

    // MARK: Shared Public
    
    public func get(favorites favoritesOnly: Bool = false,
                    update forceUpdate: Bool = false,
                    grouped groupResults: Bool = true,
                    completion:(devicesController :NSFetchedResultsController) ->())
    {
        
        NSLog(">>>>>> GET IN f=\(favoritesOnly) u=\(forceUpdate) g=\(groupResults)")
        
        if forceUpdate {
            NSLog("!! force Update")
            
            self.update {
                NSLog(">>>>>> GET update IN f=\(favoritesOnly) u=\(forceUpdate) g=\(groupResults)")

                self.fetch(favorites: favoritesOnly, grouped: groupResults, completion: { (devicesController) -> () in
                    completion(devicesController:devicesController)
                })
            }
        }
        else {
            NSLog("!! fetch only")
            
            self.fetch(favorites: favoritesOnly, grouped: groupResults, completion: { (devicesController) -> () in
                completion(devicesController:devicesController)
            })
        }
        
        NSLog("<<<<<< GET OUT")
    }

    
}