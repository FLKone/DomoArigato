//
//  ViewController.swift
//  DomoArigato
//
//  Created by FLK on 20/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import UIKit
import CoreData
import MCSwipeTableViewCell

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    
    var devicesController = NSFetchedResultsController()
    var showFavoritesOnly: Bool = false
    
    @IBAction func unwindToMainMenu(segue: UIStoryboardSegue) {
        print("unwindToMainMenu \(segue)")
        //we have the opportunity to udpate UI after setings change
    }
    
    // MARK: - View lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: "getDevices:forceUpdate:", forControlEvents: .ValueChanged)
        self.tableView.addSubview(refreshControl)
        
        self.getDevices(forceUpdate: true)
        
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextShouldReset:", name: kContextChangedNotification, object: nil)
    }
    
    deinit {
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }

    func getDevices(sender: AnyObject? = nil, var forceUpdate update: Bool = false) {
        NSLog("reloadData update=\(update) sender=\(sender)")

        // When getDevices is triggered from UIRefreshControl, we need to force update
        if let _ = sender as? UIRefreshControl {
            update = true
        }
        
        Devices.sharedInstance.get(favorites: self.showFavoritesOnly, update: update) { (newDevicesController) -> () in
            
            NSLog("reloadData newDevicesController \(newDevicesController)")
            self.devicesController = newDevicesController
            self.tableView.reloadData()
            
            if let refreshctrl = sender as? UIRefreshControl {
                refreshctrl.endRefreshing()
            }
        }
        
    }
    
    // MARK: - Notification Methods
    
    func contextShouldReset(notification: NSNotification) {
        NSLog("contextShouldReset \(notification)")
        self.getDevices(forceUpdate: false)
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

        self.getDevices(forceUpdate: false)
    }
    
    // MARK: - UITableView DataSource
    
    func configureCell(cell: DeviceSwitchCell, atIndexPath indexPath: NSIndexPath) {
        
        let curDevice = devicesController.objectAtIndexPath(indexPath) as! Device

        NSLog("configure \(indexPath) \(curDevice)")
        
        // Setting the default inactive state color to the tableView background color
        cell.defaultColor = UIColor(red: 227.0 / 255.0, green: 227.0 / 255.0, blue: 227.0 / 255.0, alpha: 1.0)
        
        cell.label.text = curDevice.name
        cell.data.text = curDevice.data
        
        let checkOnView = imageViewWithImageName("SwitchOn")
        checkOnView.tintColor = UIColor.whiteColor()
        
        let checkOffView = imageViewWithImageName("SwitchOff")
        checkOffView.tintColor = UIColor.whiteColor()

        
        let greenColor = UIColor(red: 85.0/255.0, green: 213.0/255.0, blue: 80.0/255.0, alpha: 1.0)
        let grayColor = UIColor(red: 227.0 / 255.0, green: 227.0 / 255.0, blue: 227.0 / 255.0, alpha: 1.0)
        
        
        switch curDevice.type! {
            case "lightbulb":
                cell.firstTrigger = 0.11
                cell.secondTrigger = 0.35
                
                if curDevice.data == "On" {
                    cell.setSwipeGestureWithView(checkOnView, color: grayColor, mode: MCSwipeTableViewCellMode.Switch, state:MCSwipeTableViewCellState.State3, completionBlock: { cell, state, mode in
                        print("switch osef")
                        //self.changeCoffeeScore(coffeeScore!, newValue: NSNumber.numberWithInt(-1))
                        //return ()
                    });
                    
                    cell.setSwipeGestureWithView(checkOffView, color: greenColor, mode: MCSwipeTableViewCellMode.Switch, state:MCSwipeTableViewCellState.State4, completionBlock: { cell, state, mode in
                        print("switch action Off for \(curDevice.id)")
                        Devices.sharedInstance.put(curDevice.id!, toStatus:false) {
                            self.getDevices(forceUpdate: true)
                        }
                        //self.changeCoffeeScore(coffeeScore!, newValue: NSNumber.numberWithInt(-1))
                        //return ()
                    });
                }
                else {
                    cell.setSwipeGestureWithView(checkOffView, color: grayColor, mode: MCSwipeTableViewCellMode.Switch, state:MCSwipeTableViewCellState.State3, completionBlock: { cell, state, mode in
                        print("switch osef")
                        //self.changeCoffeeScore(coffeeScore!, newValue: NSNumber.numberWithInt(-1))
                        //return ()
                    });
                    
                    cell.setSwipeGestureWithView(checkOnView, color: greenColor, mode: MCSwipeTableViewCellMode.Switch, state:MCSwipeTableViewCellState.State4, completionBlock: { cell, state, mode in
                        print("switch action On for \(curDevice.id)")
                        Devices.sharedInstance.put(curDevice.id!, toStatus:true) {
                            self.getDevices(forceUpdate: true)
                        }
                        //self.changeCoffeeScore(coffeeScore!, newValue: NSNumber.numberWithInt(-1))
                        //return ()
                    });
                }

            default:
                break
        }

    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        if let sections = devicesController.sections {
            return sections.count
        }
        
        return 0
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let sections = devicesController.sections {
            let currentSection = sections[section]
            return currentSection.numberOfObjects
        }
        
        return 0
    }

    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if let sections = devicesController.sections {
            let currentSection = sections[section]
            return currentSection.name
        }
        
        return nil
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = self.tableView.dequeueReusableCellWithIdentifier("DeviceSwitchCell", forIndexPath: indexPath) as! DeviceSwitchCell
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        self.tableView.deselectRowAtIndexPath(indexPath, animated: true)
        
    }

}

