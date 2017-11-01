//
//  Constants.swift
//  photo-city
//
//  Created by AndyWu on 2017/10/31.
//  Copyright © 2017年 AndyWu. All rights reserved.
//

import Foundation

let apiKey = "a346b3e975bd3c6cbc8aa0dfd3bc24b5"

func flockrUrl(forApiKey key: String, withAnntation annotation: DroppablePin, andNumverOfPhotos number: Int) -> String {
    let urlString = "https://api.flickr.com/services/rest/?method=flickr.photos.search&api_key=\(apiKey)&lat=\(annotation.coordinate.latitude)&lon=\(annotation.coordinate.longitude)&radius=1&radius_units=mi&per_page=\(number)&format=json&nojsoncallback=1"
    return urlString
}


