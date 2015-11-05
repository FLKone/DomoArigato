//
//  AccountViewController.swift
//  DomoArigato
//
//  Created by FLK on 29/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import UIKit
import CoreData

class AccountViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    @IBOutlet weak var tableView: UITableView!
    let context = CoreDataStore.mainQueueContext()
    var inputs = [NSDictionary]() //store DB scheme
    var values = Dictionary<String, AnyObject>()
    //var account:NSManagedObject? //current Object, from DB, if exist
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.title = "Account"
        
        inputs.append(["name" : "IP",           "key" : "ip",           "type" : "string",      "default" : "1.2.3.4"])
        inputs.append(["name" : "Port",         "key" : "port",         "type" : "int",         "default" : "8080"])
        
        inputs.append(["name" : "SSL",          "key" : "ssl",          "type" : "switch",      "default" : false])
        inputs.append(["name" : "Self-signed?", "key" : "selfsigned",   "type" : "switch",      "default" : false])
        
        inputs.append(["name" : "Username",     "key" : "username",     "type" : "string",      "default" : "user"])
        inputs.append(["name" : "Password",     "key" : "passowrd",     "type" : "string",      "default" : "pass"])
        
        //self.navigationItem.rightBarButtonItem?.enabled = false
        NSNotificationCenter.defaultCenter().addObserver(self, selector: "valueDidChange:", name: kAccountValueChanged, object: nil)
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
    
    func valueDidChange(notification: NSNotification) {
        print("notif \(notification.userInfo)")
        
        if let name = notification.userInfo!["name"] as! String? {
            let value = notification.userInfo!["value"]
            switch (value) {
                case let (value as String):
                    print("String \(name) \(value)")
                    self.values[name] = value
                case let (value as Int):
                    print("Int \(name) \(value)")
                    self.values[name] = value
                default:
                    print("default \(name)")
                
            }
        }
        
        print(self.values.description)
    }
    
    // MARK: - View Actions

    @IBAction func save(sender: UIBarButtonItem?) {
        print("save")
        
        let entity =  NSEntityDescription.entityForName("Account", inManagedObjectContext:self.context)
        let account = Account(entity: entity!, insertIntoManagedObjectContext: self.context)

        account.ip = values["ip"] as! String
        account.port = Int64(values["port"] as! Int)
        
        if let ssl = values["ssl"] as? Int {
            account.ssl = Bool(ssl)
        }

        if let selfsigned = values["selfsigned"] as? Int {
            account.selfsigned = Bool(selfsigned)
        }
        
        if let username = values["username"] as? String, let password = values["password"] as? String {
            account.username = username
            // TODO: Storepassord in keychain
            //account.password = password

            account.mustAuth = true
        }
        else {
            account.mustAuth = false
        }

        //Save It
        do {
            try CoreDataStore.saveContext(self.context)
            
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
            
        }

    }
    
    @IBAction func cancel(sender: UIBarButtonItem?) {
        print("cancel")
        self.performSegueWithIdentifier("unwindToSettings:", sender: self)
    }
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return inputs.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let input = inputs[indexPath.row]
        
        switch (input.valueForKey("type") as? String) {
            case "string"?:
                let cell = self.tableView.dequeueReusableCellWithIdentifier("AccountTextFieldCell", forIndexPath: indexPath) as! AccountTextFieldCell
                cell.name = input.valueForKey("key") as? String
                cell.label.text = input.valueForKey("name") as? String
                cell.textfield.text = "192.168.1.2"
                cell.textfield.placeholder = input.valueForKey("default") as? String

                return cell
            case "int"?:
                let cell = self.tableView.dequeueReusableCellWithIdentifier("AccountTextFieldIntCell", forIndexPath: indexPath) as! AccountTextFieldIntCell
                cell.name = input.valueForKey("key") as? String
                cell.label.text = input.valueForKey("name") as? String
                cell.textfield.text = "808"
                cell.textfield.placeholder = input.valueForKey("default") as? String

                return cell
            case "switch"?:
                let cell = self.tableView.dequeueReusableCellWithIdentifier("AccountBoolCell", forIndexPath: indexPath) as! AccountBoolCell
                cell.name = input.valueForKey("key") as? String                
                cell.label.text = input.valueForKey("name") as? String
                cell.cellswitch.on = input.valueForKey("default") as! Bool
                
                return cell
            default:
                let cell = self.tableView.dequeueReusableCellWithIdentifier("AccountBasicCell", forIndexPath: indexPath)
                cell.textLabel!.text = input.valueForKey("name") as? String
                
                return cell
        }
    }
    
    func tableView(tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        if section > 0 {
            return "Local"
        }
        else {
            return "Remote"
        }
    }
    
    // MARK: - UITableView Delegate
    func tableView(tableView: UITableView,
        didSelectRowAtIndexPath indexPath: NSIndexPath) {
            
            tableView.deselectRowAtIndexPath(indexPath, animated: true)
            print("You selected cell #\(indexPath.row)!")
    }
}