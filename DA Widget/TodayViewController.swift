//
//  TodayViewController.swift
//  DA Widget
//
//  Created by FLK on 20/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import UIKit
import Alamofire
import NotificationCenter

class TodayViewController: UIViewController, NCWidgetProviding {
    
    @IBOutlet weak var LogView: UITextView!
    @IBOutlet weak var ActivityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var TempBtn: UIButton!
    @IBOutlet weak var TempLabel: UILabel!
    
    var nbR: Int = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        
        print("viewDidLoad")

    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()

        // Dispose of any resources that can be recreated.
    }
    
    func widgetMarginInsetsForProposedMarginInsets
        (defaultMarginInsets: UIEdgeInsets) -> (UIEdgeInsets) {
            return UIEdgeInsetsZero
    }
    
    func widgetPerformUpdateWithCompletionHandler(completionHandler: ((NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        print("widgetPerformUpdateWithCompletionHandler")
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
       
        //self.TempLabel.text = "widgetPerformUpdateWithCompletionHandler"
        self.LogView.text = "\(NSDate()) widgetPerform\n\(self.LogView.text)"
        self.RefreshTemp(self.TempBtn)
        
        completionHandler(NCUpdateResult.NewData)
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        print("viewDidAppear")
        self.LogView.text = "\(NSDate()) viewDidAppear\n\(self.LogView.text)"
        self.RefreshTemp(self.TempBtn)
    }
    
    @IBAction func RefreshTemp(sender: UIButton) {
        self.ActivityIndicator.startAnimating()
        Alamofire.request(.GET, "http://192.168.1.29:8080/json.htm?type=devices&filter=all&used=true&order=Name")
            .responseJSON { response in
                //print(response.request)  // original URL request
                //print(response.response) // URL response
                //print(response.data)     // server data
                //print(response.result)   // result of response serialization
                
                if let JSON = response.result.value {
                    //print("JSON: \(JSON)")
                    
                    if let result = JSON["result"] as? NSArray {
                        for item in result {
                            let obj = item as? NSDictionary
                            if let isFavorite = obj?.objectForKey("Favorite") {
                                if (isFavorite.integerValue == 1) {
                                    if (obj?.objectForKey("TypeImg") as? String == "temperature") {
                                        print(obj)
                                        let data = obj?.objectForKey("Data") as? String
                                        
                                        self.TempLabel.text = data
                                        
                                        self.TempBtn.setTitle("\(self.nbR)", forState: UIControlState.Normal)
                                        self.nbR += 1

                                        self.ActivityIndicator.stopAnimating()
                                        break
                                    }
                                }
                            }
                        }
                    }
                }
        }
    }
    
}