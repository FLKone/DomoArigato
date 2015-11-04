//
//  Device+CoreDataProperties.swift
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

extension Device {

    @NSManaged var data: String?
    @NSManaged var data_old: String?
    @NSManaged var id: String?
    @NSManaged var isFavorite: Bool
    @NSManaged var isToday: Bool
    @NSManaged var name: String?
    @NSManaged var type: String?

}
