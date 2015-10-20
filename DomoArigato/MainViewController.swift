//
//  ViewController.swift
//  DomoArigato
//
//  Created by FLK on 20/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import UIKit
import Alamofire

class MainViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {

    @IBOutlet weak var ReloadButton: UIBarButtonItem!
    @IBOutlet weak var tableView: UITableView!
    var items: [NSDictionary] = []// = ["We", "Heart", "Swift"]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.refreshData(nil)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    // MARK: - UITableView DataSource
    
    func numberOfSectionsInTableView(tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.items.count;
    }

    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {

        let cell = self.tableView.dequeueReusableCellWithIdentifier("BasicCell", forIndexPath: indexPath) as UITableViewCell!
        cell.textLabel?.text = self.items[indexPath.row].objectForKey("Name") as? String
        let data = self.items[indexPath.row].objectForKey("Data") as? String
        
        cell.detailTextLabel?.text = data
        
        
        if (self.items[indexPath.row].objectForKey("TypeImg") as? String == "lightbulb") {
            print("row: \(cell.textLabel?.text) light : \(data)")
        }
        else if (self.items[indexPath.row].objectForKey("TypeImg") as? String == "temperature") {
            print("row: \(cell.textLabel?.text) temp : \(data)")

        }
        
         /*
        let dic = self.items[indexPath.row] as [String:AnyObject]
        cell!.textLabel?.text = dic.objectForKey("name")
        
       
        if dic = self.items[indexPath.row] {
            if let name = dic.objectForKey("name") as String {
                cell!.textLabel?.text = name
            }
        }
*/

        
        return cell!
        
        
    }
    
    func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        
        tableView.deselectRowAtIndexPath(indexPath, animated: true)
        print("You selected cell #\(indexPath.row)!")
    }
    

    @IBAction func refreshData(sender: AnyObject?) {
        print("refreshData from \(sender)")
        
        Alamofire.request(.GET, "http://192.168.1.29:8080/json.htm?type=devices&filter=all&used=true&order=Name")
            .responseJSON { response in
                //print(response.request)  // original URL request
                //print(response.response) // URL response
                //print(response.data)     // server data
                //print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    print("JSON: \(JSON)")
                    
                    if let result = JSON["result"] as? NSArray {
                        for item in result {
                            let obj = item as? NSDictionary
                            if let isFavorite = obj?.objectForKey("Favorite") {
                                if (isFavorite.integerValue == 1) {
                                    self.items.append(obj!)
                                    //print(obj)
                                }
                            }
                        }
                    }
                    
                    self.tableView.reloadData()
                    
                }
        }
    }
    
    
}

