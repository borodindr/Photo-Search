//
//  UnsplashService.swift
//  Photo Search
//
//  Created by Dmitry Borodin on 06/06/2019.
//  Copyright © 2019 Dmitry Borodin. All rights reserved.
//

import Foundation

struct UnsplashService {
    private let urlString = "https://api.unsplash.com/search/photos?per_page=50&query="
    private let accessKey = "Client-ID 6d0d24c4eca664945e8752131bc607b15148688e1b50eb03ea9b2b6c634093c4"
    static var task = URLSessionDataTask()
    
    func searchPhotos(_ query: String, completion: @escaping (UnsplashResponse?, NSError?) -> Void) {
        
        guard let encodedQuery = query.addingPercentEncoding(withAllowedCharacters: .urlHostAllowed),
              let url = URL(string: urlString + encodedQuery) else {
            print("URL error")
            return
        }
        
        var request = URLRequest(url: url)
        request.addValue("v1", forHTTPHeaderField: "Accept-Version")
        request.addValue(accessKey, forHTTPHeaderField: "Authorization")
        UnsplashService.task = URLSession.shared.dataTask(with: request) { (data, response, error) in
            
            if let error = error as NSError? {
                completion(nil, error)
                return
            }
            
            if let data = data {
                do {
                    let response = try JSONDecoder().decode(UnsplashResponse.self, from: data)
                    completion(response, nil)
                } catch {
                    print(error)
                }
            }
        }
        UnsplashService.task.resume()
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

