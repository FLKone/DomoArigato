//
//  TodayViewController.swift
//  DA Widget
//
//  Created by FLK on 20/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import UIKit
import CoreData
import Alamofire
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    
    let context = CoreDataStore.mainQueueContext()

    var devices = [NSManagedObject]()
    var nbR: Int = 0
    var lastLoadDate: NSDate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Crittercism.enableWithAppID(kCrittercismAPI)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        

        //self.tableView.tableFooterView = UIView(frame: CGRectMake(0, 0, 1, 1))

        self.preferredContentSize = CGSizeMake(self.view.frame.width, 94 + 8);
        
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }

    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero//UIEdgeInsetsMake(10, 10, 10, 10)
    }
    
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        print("widgetPerformUpdateWithCompletionHandler")

        self.reloadData(nil)
        completionHandler(NCUpdateResult.NewData)
        
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        print("viewWillAppear \(self.lastLoadDate) \(self.devices.count)")
        // on first load view is already loaded from widgetPerformUpdateWithCompletionHandler, on subsquents calls lastLoadData wont be nil
        self.reloadData(nil)

    }
    
    func save() {
        //Save It
        do {
            try CoreDataStore.saveContext(self.context)
            
            // Save in shared user defaults
            let sharedDefaults = NSUserDefaults(suiteName: kAppGroup)!
            sharedDefaults.setBool(true, forKey: kWidgetModelChanged)
            sharedDefaults.synchronize()
            
        } catch let error as NSError  {
            print("Could not save \(error), \(error.userInfo)")
            
        }
    }
    
    func refreshData() {
        
        
        let fetchRequest = NSFetchRequest(entityName: "Device")
        //fetchRequest.predicate = NSPredicate(format: "(isFavorite == %@) AND (type == %@)", argumentArray: ["1", "temperature"])
        fetchRequest.predicate = NSPredicate(format: "(isFavorite == %@)", argumentArray: [true])
        let primarySortDescriptor = NSSortDescriptor(key: "type", ascending: false)
        let secondarySortDescriptor = NSSortDescriptor(key: "name", ascending: true)
        
        fetchRequest.sortDescriptors = [primarySortDescriptor, secondarySortDescriptor]

        
        do {
            let tempDevices = try context.executeFetchRequest(fetchRequest) as! [NSManagedObject]
            self.lastLoadDate = NSDate()

            devices = tempDevices
            self.collectionView.reloadSections(NSIndexSet(index: 0))
            self.collectionView.reloadSections(NSIndexSet(index: 1))
        
            /*
            if devices.count == 0 {

            }
            else {
                devices = tempDevices
                self.collectionView.reloadData()
            }
*/
            
            //print("r= \(devices)")
            print("r= \(devices.count)")
            

//            self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forRow: 0, inSection: 0)])
//            self.collectionView.reloadItemsAtIndexPaths([NSIndexPath(forItem: 1, inSection: 0)])
            
            /*[self.collectionView performBatchUpdates:^{
                [self.collectionView reloadSections:[NSIndexSet indexSetWithIndex:0]];
            } completion:nil];
            */
            
            print("=== After Reload \(self.preferredContentSize)")
            //self.preferredContentSize = self.collectionView.contentSize
            print("=== After Reload 2 \(self.preferredContentSize)")
            //self.tableView.reloadData()
            
            //print("preferredContentSize= \(self.preferredContentSize)")
            //print("contentSize= \(self.tableView.contentSize)")

            //self.preferredContentSize = self.tableView.contentSize;
            //self.tableView.hidden = false;
        } catch let error as NSError {
            print("Could not fetch \(error), \(error.userInfo)")
        }
        


    }
    
    @IBAction func reloadData(sender: AnyObject?) {
        //self.ActivityIndicator.startAnimating()
        Alamofire.request(.GET, "http://192.168.1.29:8080/json.htm?type=devices&filter=all&used=true&order=Name")
            .responseJSON { response in
                //print(response.request)  // original URL request
                //print(response.response) // URL response
                //print(response.data)     // server data
                //print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    //Core Data
                    let entity =  NSEntityDescription.entityForName("Device", inManagedObjectContext:self.context)
                    
                    //print(JSON)
                    if let result = JSON["result"] as? NSArray {
                        for item in result {
                            let obj = item as! NSDictionary
                            
                            let request = NSFetchRequest(entityName: "Device")
                            request.predicate = NSPredicate(format: "id == %@", argumentArray: [(obj.valueForKey("idx"))!])
                            
                            do {
                                let result = try self.context.executeFetchRequest(request) as NSArray
                                
                                //print("Fetch ok: \(result)")
                                if result.count == 2 {
                                    continue
                                }
                                
                                if result.count == 1 {
                                    //update
                                    let device = result.objectAtIndex(0) as! NSManagedObject
                                    
                                    print("\(obj.valueForKey("idx")!) \(obj.valueForKey("Name")!)=\(obj.valueForKey("Data")!) Fav:\(obj.valueForKey("Favorite")!)")
                                        
                                    device.setValue(obj.valueForKey("Name"), forKey: "name")
                                    device.setValue(obj.valueForKey("idx"), forKey: "id")
                                    device.setValue(obj.valueForKey("TypeImg"), forKey: "type")
                                    device.setValue(obj.valueForKey("Data"), forKey: "data")
                                    if let isFavorite = obj.valueForKey("Favorite")?.integerValue {
                                        device.setValue(Bool(isFavorite), forKey: "isFavorite")
                                    }
                                    
                                    self.save()
                                }
                                else if result.count == 0 {
                                    //create new one
                                    let device = NSManagedObject(entity: entity!, insertIntoManagedObjectContext: self.context)
                                    device.setValue(obj.valueForKey("Name"), forKey: "name")
                                    device.setValue(obj.valueForKey("idx"), forKey: "id")
                                    device.setValue(obj.valueForKey("TypeImg"), forKey: "type")
                                    device.setValue(obj.valueForKey("Data"), forKey: "data")
                                    if let isFavorite = obj.valueForKey("Favorite")?.integerValue {
                                        device.setValue(Bool(isFavorite), forKey: "isFavorite")
                                    }
                                    
                                    self.save()
                                }
                                
                                
                            } catch let error as NSError {
                                print("Fetch failed: \(error.localizedDescription)")
                                
                            }
                            
                        }
                    }
                    
                    self.refreshData()
                    
                    //delay(4) {
                      //  self.ActivityIndicator.stopAnimating()
                    //}
                }
                
        }
        
        
    }
    
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize {
            //print("sizeForItemAtIndexPath 2")
            
            let nbItem = self.collectionView(self.collectionView, numberOfItemsInSection: indexPath.section) as Int
            
            let leftInset = ((self.view.frame.width - 40 - CGFloat(10*(nbItem-1))) / CGFloat(nbItem))
            if indexPath.section == 0 {
                return CGSize(width: leftInset, height: 54)
            }
            else  {
                return CGSize(width: 200, height: 20)
            }
    }
    
    func collectionView(collectionView: UICollectionView,
        layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: Int) -> UIEdgeInsets {
            if section == 1 {
                return UIEdgeInsetsMake(0, 0, 0, 0)
            }
            let nbItem = self.collectionView(self.collectionView, numberOfItemsInSection: section) as Int

            
            let leftInset = (self.view.frame.width - CGFloat(((self.view.frame.width - 40 - CGFloat(10*(nbItem-1))) / CGFloat(nbItem))*CGFloat(nbItem)) - CGFloat(10*(nbItem-1))) / 2
            print("insetForSectionAtIndex calc=\(self.view.frame.width) nb=\(nbItem) inset=\(leftInset)")

            print("insetForSectionAtIndex section=\(section) nb=\(nbItem) inset=\(leftInset)")

            return UIEdgeInsets(top: 8.0, left: 20, bottom: 12.0, right: 20)
            //return UIEdgeInsets(top: 10, left: leftInset, bottom: 10, right: 10)

//            return UIEdgeInsets(top: 10.0, left: leftInset, bottom: 10.0, right: 10)
            
            
    }
    
    
    // MARK: - UICollectionView DataSource

    
    func configureCell(cell: UICollectionViewCell, atIndexPath indexPath: NSIndexPath, type: String) {
        let device = devices[indexPath.row]
        //print("config cell \(device)")
        let nameLabel = cell.viewWithTag(1) as? UILabel
        let dataLabel = cell.viewWithTag(2) as? UILabel
        let typeImage = cell.viewWithTag(3) as? UIImageView
        
        nameLabel?.text = device.valueForKey("name") as? String

        let data = device.valueForKey("data") as! String

        switch type {
            case "temperature" :
                typeImage?.image = UIImage(named: "TemperatureOff")
                //typeImage?.highlightedImage = UIImage(named: "TemperatureOn")

                dataLabel?.text = data.stringByReplacingOccurrencesOfString(" C", withString: "").stringByReplacingOccurrencesOfString(" F", withString: "")
                typeImage?.highlighted = false
            case "lightbulb" :
                //typeImage?.image = UIImage(named: "SwitchOff")
                //typeImage?.highlightedImage = UIImage(named: "SwitchOn")
                
                dataLabel?.text = device.valueForKey("data") as? String
                typeImage?.image = UIImage(named: ((data == "On") ? "SwitchOn" : "SwitchOff"))

            default:
                dataLabel?.text = device.valueForKey("data") as? String

        }
        
        //cell.backgroundColor = UIColor.lightGrayColor()
    }

    func collectionView(collectionView: UICollectionView, shouldHighlightItemAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    
    func collectionView(collectionView: UICollectionView, didSelectItemAtIndexPath indexPath: NSIndexPath) {
        print("select \(indexPath)")
        if indexPath.section == 1 {
            print("make it crash")
            print("device \(devices[11])")
        }

    }
    
    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
            
            //print("numberOfItemsInSection \(devices.count)")
            if section == 0 {
                return devices.count; }
            else {
                    return 1 }
    }
    
    func collectionView(collectionView: UICollectionView,
        cellForItemAtIndexPath indexPath: NSIndexPath) -> UICollectionViewCell {
        var cell:UICollectionViewCell

        //print("cellForItemAtIndexPath")
        if indexPath.section == 1 {
            cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("FakeCell", forIndexPath: indexPath)
            let nameLabel = cell.viewWithTag(1) as? UILabel
            let dataLabel = cell.viewWithTag(2) as? UILabel
            
            let version = NSBundle.mainBundle().infoDictionary!["CFBundleShortVersionString"] as! String
            let build = NSBundle.mainBundle().infoDictionary!["CFBundleVersion"] as! String
            
            nameLabel!.text = "\(version) #\(build)"
            if let lastdate = self.lastLoadDate {
                dataLabel!.text = "\(lastdate.descriptionWithLocale(NSLocale.systemLocale()))"
            }

            //cell.backgroundColor = UIColor.redColor()
            return cell
        }

        let device = devices[indexPath.row]
        let type = device.valueForKey("type") as! String
        switch type {
            case "temperature" :
                cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("TempCell", forIndexPath: indexPath)
                self.configureCell(cell, atIndexPath: indexPath, type: "temperature")
            case "lightbulb" :
                cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("SwitchCell", forIndexPath: indexPath)
                self.configureCell(cell, atIndexPath: indexPath, type: "lightbulb")
            default:
                cell = self.collectionView.dequeueReusableCellWithReuseIdentifier("UtilCell", forIndexPath: indexPath)
                self.configureCell(cell, atIndexPath: indexPath, type: "default")
        }
            
        //print("cellForItemAtIndexPath \(cell)")
            
        return cell
    }
}