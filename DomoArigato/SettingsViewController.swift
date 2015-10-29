//
//  SettingsViewController.swift
//  DomoArigato
//
//  Created by FLK on 28/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import UIKit
import CoreData

class SettingsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var tableView: UITableView!
    let context = CoreDataStore.mainQueueContext()    
    var accounts = [NSManagedObject]()
    
    @IBAction func unwindToSettings(segue: UIStoryboardSegue) {
        print("unwindToSettings \(segue)")
        //we have the opportunity to udpate UI after account change
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
        self.accounts = NSManagedObject.findAllInContext("Account", context: self.context) as! [NSManagedObject]
        
        print(self.accounts)
        
        //self.navigationItem.rightBarButtonItem?.enabled = false
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "contextShouldReset:", name: kContextChangedNotification, object: nil)
    }
    
    deinit {
        print("deinit")
        
        NSNotificationCenter.defaultCenter().removeObserver(self)
    }
    
    // MARK: - Notification Methods
    
    func contextShouldReset(notification: NSNotification) {
        print("contextShouldReset \(notification)")
        // Reset changed context
        self.context.reset()
    }
    
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return (self.accounts.count + 1)
        }
        else {
            return 1
        }
        
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        
        if indexPath.section > 0 {
            let cell = self.tableView.dequeueReusableCellWithIdentifier("AboutCell", forIndexPath: indexPath)

            let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
            let build = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! String

            cell.textLabel!.text = "Version"
            cell.detailTextLabel!.text = "\(version) #\(build)"
            return cell

        }
        else {
            if (self.accounts.count > 0 && indexPath.row == 0) {
                let cell = self.tableView.dequeueReusableCellWithIdentifier("ServerCell", forIndexPath: indexPath)

                cell.textLabel!.text = "Domo \(self.accounts[indexPath.row].valueForKey("api")!)"
                cell.detailTextLabel!.text = "IP \(self.accounts[indexPath.row].valueForKey("ip")!):\(self.accounts[indexPath.row].valueForKey("port")!)"
                return cell
            }
            else if (self.accounts.count == 0 && indexPath.row == 0) {
                let cell = self.tableView.dequeueReusableCellWithIdentifier("AddServerCell", forIndexPath: indexPath)
                cell.textLabel!.text = "Add Server"
                return cell
            }
            else {
                let cell = self.tableView.dequeueReusableCellWithIdentifier("InfoCell", forIndexPath: indexPath)
                cell.textLabel!.text = "Can't add more that on server"
                return cell
                
            }


        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section > 0 {
            return "About"
        }
        else {
            return "Configuration"
        }
    }
    
    // MARK: - UITableView Delegate
    func tableView(tableView: UITableView,
        didSelectRowAtIndexPath indexPath: NSIndexPath) {
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            print("You selected cell #\(indexPath.row)!")
    }
}