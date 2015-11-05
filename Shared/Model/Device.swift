//
//  Device.swift
//  DomoArigato
//
//  Created by FLK on 05/11/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import Foundation
import CoreData


class Device: NSManagedObject {

// Insert code here to add functionality to your managed object subclass
    override var description: String {
        //return "MyClass \(string)"
        return "desc of \(self.name), dex=\(self.id), data=\(self.data)"
    }
}
