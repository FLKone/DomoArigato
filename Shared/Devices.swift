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
    
    private func fetch( filter deviceFilter: DeviceFilter = .All,
                        grouped groupResults: Bool = true,
                        completion:(devicesController :NSFetchedResultsController) ->())
    {
        
        let devicesFetchRequest = NSFetchRequest(entityName: "Device")
        
        let primarySortDescriptor = NSSortDescriptor(key: "type", ascending: false)
        let secondarySortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        
        devicesFetchRequest.sortDescriptors = [primarySortDescriptor, secondarySortDescriptor]
        
        switch deviceFilter {
            case .Favorites:
                devicesFetchRequest.predicate = NSPredicate(format: "(isFavorite == %@)", argumentArray: [true])
            case .Today:
                devicesFetchRequest.predicate = NSPredicate(format: "(isToday == %@)", argumentArray: [true])
            default:
                break
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
        
        // TODO: Error management if no accounts

        let accounts = NSManagedObject.findAllInContext("Account", context: self.context) as! [Account]
        
        if accounts.count == 0 {
            print("update IN > no accounts")
            completion()
            return
        }
        
        print("update IN > accounts ok")

        //print(accounts)
        
        let URLScheme = accounts[0].ssl ? "https" : "http"
        
        Alamofire.request(.GET, "\(URLScheme)://\(accounts[0].ip):\(accounts[0].port)/json.htm?type=devices&filter=all&used=true&order=Name")
        .responseJSON { response in
            print(response.request)  // original URL request
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
                            
                            var device:Device
                            
                            if result.count == 1 {
                                //update
                                device = result.objectAtIndex(0) as! Device
                            }
                            else  {
                                //create new one
                                device = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: self.context) as! Device
                            }

                            device.name = obj.valueForKey("Name") as? String
                            device.id = obj.valueForKey("idx") as? String
                            device.data = obj.valueForKey("Data") as? String
                            device.type = obj.valueForKey("TypeImg") as? String
                            
                            if let isFavorite = obj.valueForKey("Favorite")?.integerValue {
                                NSLog("update > Updated Device = \(obj.valueForKey("Name")) = \(obj.valueForKey("Data")) | Fav=\(Bool(isFavorite))")
                                device.isFavorite = Bool(isFavorite)
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
    
    /*
        Get devices
        force updated from webservice with update=true
    */
    public func get(filter deviceFilter: DeviceFilter = .All,
                    update forceUpdate: Bool = false,
                    grouped groupResults: Bool = true,
                    completion:(devicesController :NSFetchedResultsController) ->())
    {
        
        NSLog(">>>>>> GET IN f=\(deviceFilter) u=\(forceUpdate) g=\(groupResults)")
        
        if forceUpdate {
            NSLog("!! force Update")
            
            self.update {
                NSLog(">>>>>> GET update IN f=\(deviceFilter) u=\(forceUpdate) g=\(groupResults)")

                self.fetch(filter: deviceFilter, grouped: groupResults, completion: { (devicesController) -> () in
                    completion(devicesController:devicesController)
                })
            }
        }
        else {
            NSLog("!! fetch only")
            
            self.fetch(filter: deviceFilter, grouped: groupResults, completion: { (devicesController) -> () in
                completion(devicesController:devicesController)
            })
        }
        
        NSLog("<<<<<< GET OUT")
    }

    /* 
        Remotely send command to webservice 
    */
    public func put(deviceIndex: String,
                    toStatus newStatus: Bool,
                    completion:() ->())
    {
        let accounts = NSManagedObject.findAllInContext("Account", context: self.context) as! [Account]
        
        if accounts.count == 0 {
            print("update IN > no accounts")
            dispatch_async(dispatch_get_main_queue(),{
                completion()
            })
            return
        }
        
        print("update IN > accounts ok")
        
        //print(accounts)
        
        let URLScheme = accounts[0].ssl ? "https" : "http"
        let SwitchCmd = newStatus ? "On" : "Off"
        
        Alamofire.request(.GET, "\(URLScheme)://\(accounts[0].ip):\(accounts[0].port)/json.htm?type=command&param=switchlight&idx=\(deviceIndex)&switchcmd=\(SwitchCmd)&level=0&passcode=")
            .responseJSON { response in
                print(response.request)  // original URL request
                //print(response.response) // URL response
                //print(response.data)     // server data
                //print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    
                    print(JSON)
                    dispatch_async(dispatch_get_main_queue(),{
                        completion()
                    })
                }
            }

        
    }
    

    /*
        modify local fields, save within the app, not remotely
    */
    public func corePut(deviceIndex: String,
                        field entityField: DeviceField,
                        newValue value: AnyObject,
                        completion:() ->())
    {

        
        //Core Data
        let request = NSFetchRequest(entityName: "Device")
        
        print("looking for idx=\(deviceIndex)")
        
        request.predicate = NSPredicate(format: "id == %@", argumentArray: [deviceIndex])
        request.returnsObjectsAsFaults = false
        
        do {
            let result = try self.context.executeFetchRequest(request) as NSArray
            
            var device:Device
            
            if result.count == 1 {
                //update
                device = result.objectAtIndex(0) as! Device

                switch entityField {
                    case .Today:
                        if let isToday = value as? Bool {
                            NSLog("update > Updated Device = \(device.name) = oldT=\(device.isToday) | newT=\(Bool(isToday))")
                            device.isToday = Bool(isToday)
                    }
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
        
        dispatch_async(dispatch_get_main_queue(),{
            completion()
        })
        
    }
    
    
    
}