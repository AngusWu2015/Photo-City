//
//  DroppablePin.swift
//  photo-city
//
//  Created by AndyWu on 2017/10/30.
//  Copyright © 2017年 AndyWu. All rights reserved.
//

import UIKit
import MapKit

class DroppablePin: NSObject, MKAnnotation {
    var coordinate: CLLocationCoordinate2D
    
    var identifier: String
    
    init(coordinate: CLLocationCoordinate2D, identifier: String) {
        self.coordinate = coordinate
        self.identifier = identifier
        super.init()
    }
}
