//
//  Photo+CoreDataProperties.swift
//  Photo Search
//
//  Created by Dmitry Borodin on 07/06/2019.
//  Copyright © 2019 Dmitry Borodin. All rights reserved.
//
//

import Foundation
import CoreData


extension Photo {

    @nonobjc public class func fetchRequest() -> NSFetchRequest<Photo> {
        return NSFetchRequest<Photo>(entityName: "Photo")
    }
    
    @NSManaged public var id: String?
    @NSManaged public var title: String?
    @NSManaged public var subtitle: String?
    @NSManaged public var fullPhotoData: NSData
    @NSManaged public var smallPhotoData: NSData
    @NSManaged public var userName: String
    @NSManaged public var dateAdded: Date?

}
