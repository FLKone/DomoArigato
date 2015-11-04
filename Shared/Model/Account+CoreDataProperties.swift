//
//  Account+CoreDataProperties.swift
//  DomoArigato
//
//  Created by FLK on 05/11/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Account {

    @NSManaged var api: Int64
    @NSManaged var haveLocal: Bool
    @NSManaged var ip: String?
    @NSManaged var isActive: Bool
    @NSManaged var local_ip: String?
    @NSManaged var local_network: String?
    @NSManaged var local_port: Int64
    @NSManaged var mustAuth: Bool
    @NSManaged var port: Int64
    @NSManaged var selfsigned: Bool
    @NSManaged var ssl: Bool
    @NSManaged var username: String?

}
