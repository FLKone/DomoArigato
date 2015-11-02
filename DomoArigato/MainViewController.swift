//
//  ViewController.swift
//  DomoArigato
//
//  Created by FLK on 20/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import UIKit
import CoreData

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
    
    func configureCell(cell: UITableViewCell, atIndexPath indexPath: NSIndexPath) {
        
        let device = devicesController.objectAtIndexPath(indexPath)
        
        NSLog("configure \(indexPath) \(device.valueForKey("name")) = \(device.valueForKey("data"))")

        cell.textLabel?.text = device.valueForKey("name") as? String
        cell.detailTextLabel?.text = device.valueForKey("data") as? String
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
        let cell = self.tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath)
        self.configureCell(cell, atIndexPath: indexPath)
        return cell
    }

}

