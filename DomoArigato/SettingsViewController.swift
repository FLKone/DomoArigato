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

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Settings"
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
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
            let cell = self.tableView.dequeueReusableCellWithIdentifier("AddServerCell", forIndexPath: indexPath)
            cell.textLabel!.text = "Add Server"
            return cell

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