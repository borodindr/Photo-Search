//
//  Photo+CoreDataClass.swift
//  Photo Search
//
//  Created by Dmitry Borodin on 06/06/2019.
//  Copyright © 2019 Dmitry Borodin. All rights reserved.
//
//

import Foundation
import CoreData
import UIKit

@objc(Photo)
public class Photo: NSManagedObject {
    
    var smallPhoto: UIImage? {
        get {
            let data = smallPhotoData as Data
            return UIImage(data: data)
        } set {
            guard let imageData = newValue?.pngData() as NSData? else { return }
            smallPhotoData = imageData
        }
    }
    
    var fullPhoto: UIImage? {
        get {
            let data = fullPhotoData as Data
            return UIImage(data: data)
        } set {
            guard let imageData = newValue?.pngData() as NSData? else { return }
            fullPhotoData = imageData
        }
    }
    
    var smallPhotoURLString: String?

    var fullPhotoURLString: String?
    
    func setFrom(photoData: PhotoData) {
        self.title = photoData.description
        self.subtitle = photoData.alt_description
        self.smallPhotoURLString = photoData.urls.small
        self.fullPhotoURLString = photoData.urls.full
        self.userName = photoData.user.name
    }
    
    //Dublicates Photo object from different context
    func setFrom(photoEntity: Photo) {
        self.title = photoEntity.title
        self.subtitle = photoEntity.subtitle
        self.smallPhotoData = photoEntity.smallPhotoData
        self.fullPhotoData = photoEntity.fullPhotoData
        self.userName = photoEntity.userName
        self.dateAdded = Date()
    }
    
    //loads small of large image from saved url
    func loadImage(size imageSize: ImageSize, completion: @escaping (UIImage?, NSError?) -> Void) {
        var urlString: String
        switch imageSize {
        case .full:
            urlString = self.fullPhotoURLString ?? ""
        case .small:
            urlString = self.smallPhotoURLString ?? ""
        }
        
        guard let url = URL(string: urlString) else {
            return
        }
        
        URLSession.shared.dataTask(with: url) { [unowned self] (data, response, error) in
            if let error = error as NSError? {
                completion(nil, error)
                return
            }
            if let data = data {
                if let newImage = UIImage(data: data) {
                    switch imageSize {
                    case .full:
                        self.fullPhotoData = data as NSData
                    case .small:
                        self.smallPhotoData = data as NSData
                    }
                    DispatchQueue.main.async {
                        completion(newImage, nil)
                    }
                }
            }
        }.resume()
    }
    
    enum ImageSize {
        case small
        case full
    }
}
