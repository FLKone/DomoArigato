//
//  AccountCell.swift
//  DomoArigato
//
//  Created by FLK on 29/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import UIKit

class AccountCell: UITableViewCell {
    var name: String? // CoreData Key
}

class AccountTextFieldCell: AccountCell {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var textfield: UITextField!

    @IBAction func valueChanged(sender : AnyObject?) {
        print("valueChanged")
        if let value = self.textfield.text as String? {
            print("postNotif AccountTextFieldCell \(value)")
            NSNotificationCenter.defaultCenter().postNotificationName(kAccountValueChanged, object: nil, userInfo: ["value" : value, "name" : self.name!])
        }
    }
}

class AccountTextFieldIntCell: AccountTextFieldCell {
    
    @IBAction override func valueChanged(sender : AnyObject?) {
        print("valueChanged")
        if let value = self.textfield.text as String? {
            print("postNotif AccountTextFieldIntCell \(Int(value)!)")
            NSNotificationCenter.defaultCenter().postNotificationName(kAccountValueChanged, object: nil, userInfo: ["value" : Int(value)!, "name" : self.name!])
        }
    }
}

class AccountBoolCell: AccountCell {
    
    @IBOutlet weak var label: UILabel!
    @IBOutlet weak var cellswitch: UISwitch!
    
    @IBAction func valueChanged(sender : AnyObject?) {
        print("postNotif AccountBoolCell \(self.cellswitch.on)")
        NSNotificationCenter.defaultCenter().postNotificationName(kAccountValueChanged, object: nil, userInfo: ["value" : Bool(self.cellswitch.on), "name" : self.name!])

    }
}
