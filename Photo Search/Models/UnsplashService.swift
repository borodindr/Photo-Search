//
//  UnsplashService.swift
//  Photo Search
//
//  Created by Dmitry Borodin on 06/06/2019.
//  Copyright © 2019 Dmitry Borodin. All rights reserved.
//

import Foundation


struct UnsplashService {
    let urlString = "https://api.unsplash.com/search/photos?per_page=50&query="
    let accessKey = "Client-ID 6d0d24c4eca664945e8752131bc607b15148688e1b50eb03ea9b2b6c634093c4"
    
    
    func searchPhotos(_ query: String, completionHandler: @escaping (UnsplashResponse?, Error?) -> Void) {
        
        guard let url = URL(string: urlString + query) else {
            print("URL error")
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("v1", forHTTPHeaderField: "Accept-Version")
        request.addValue(accessKey, forHTTPHeaderField: "Authorization")
        
        URLSession.shared.dataTask(with: request) { (data, response, error) in
            if let error = error {
                completionHandler(nil, error)
                return
            }
            if let data = data {
                do {
//                    print(String(data: data, encoding: .utf8))
                    let response = try JSONDecoder().decode(UnsplashResponse.self, from: data)
                    completionHandler(response, nil)
                } catch {
                    print(error)
                }
            }
        }.resume()
    }
    
    
}

struct UnsplashResponse: Decodable {
    var results: [PhotoData]
}

struct PhotoData: Decodable {
    var description: String?
    var alt_description: String?
    var urls: PhotoUrl
    var user: User
}

struct PhotoUrl: Decodable {
    var full: String
    var small: String
}

struct User: Decodable {
    var name: String
}

