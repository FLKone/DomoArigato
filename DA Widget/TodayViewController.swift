//
//  TodayViewController.swift
//  DA Widget
//
//  Created by FLK on 20/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import UIKit
import CoreData
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding, UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {

    @IBOutlet weak var collectionView: UICollectionView!

    //var devices = [NSManagedObject]()
    var devicesController = NSFetchedResultsController()
    var lastLoadDate: NSDate?
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        Crittercism.enableWithAppID(kCrittercismAPI)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        NSLog("viewDidLoad")

        self.getDevices()
        self.preferredContentSize = CGSizeMake(self.view.frame.width, 94 + 8);
    }
    
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        NSLog("viewWillAppear \(self.lastLoadDate)")
        
        self.getDevices(forceUpdate: true)
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        NSLog("widgetPerformUpdateWithCompletionHandler")
        
        self.getDevices()
        completionHandler(NCUpdateResult.NewData)
    }
    
    func getDevices(sender: AnyObject? = nil, forceUpdate update: Bool = false) {
        NSLog("getDevices update=\(update) sender=\(sender)")
        
        // Save in shared user defaults
        let sharedDefaults = NSUserDefaults(suiteName: kAppGroup)!
        sharedDefaults.setBool(true, forKey: kWidgetModelChanged)
        sharedDefaults.synchronize()

        Devices.sharedInstance.get(favorites: true, update: update, grouped: false) { (newDevicesController) -> () in
            
            NSLog("reloadData newDevicesController \(newDevicesController.sections?.count)")
            self.devicesController = newDevicesController
            
            if let sections = self.devicesController.sections {
                
                NSLog("sections.count \(sections.count)")
                
                if  sections.count > 0 {
                    let currentSection = sections[0]
                    print("current Obj = \(currentSection.numberOfObjects)")
                }
            }
            
            self.lastLoadDate = NSDate()
            self.collectionView.reloadSections(NSIndexSet(index: 0))
            self.collectionView.reloadSections(NSIndexSet(index: 1))

        }
        
    }
    
    func widgetMarginInsetsForProposedMarginInsets(defaultMarginInsets: UIEdgeInsets) -> UIEdgeInsets {
        return UIEdgeInsetsZero//UIEdgeInsetsMake(10, 10, 10, 10)
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
        let device = devicesController.objectAtIndexPath(indexPath)
        
        NSLog("configureCell \(device)")

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

        NSLog("select \(indexPath)")
        
        if indexPath.section == 1 {
            NSLog("make it crash")
            NSLog("device \(self.devicesController.sections![666])") // this will crash, perdio.
        }
        else {
            collectionView.cellForItemAtIndexPath(indexPath)?.backgroundColor = UIColor.lightGrayColor()
            UIView.animateWithDuration(0.5) { () -> Void in
                collectionView.cellForItemAtIndexPath(indexPath)?.backgroundColor = UIColor.clearColor()
            }
        }


    }

    func numberOfSectionsInCollectionView(collectionView: UICollectionView) -> Int {
        return 2
    }
    
    func collectionView(collectionView: UICollectionView,
        numberOfItemsInSection section: Int) -> Int {
            
            
            if section == 0 {
                if let sections = self.devicesController.sections {
                    let currentSection = sections[section]
                    return currentSection.numberOfObjects
                }
                else {
                    return 0
                }
            }
            else {
                return 1
            }

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

        let device = self.devicesController.objectAtIndexPath(indexPath)
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
