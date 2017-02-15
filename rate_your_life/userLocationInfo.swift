//
//  userLocationInfo.swift
//  MMB
//
//  Created by Fei Liang on 12/3/16.
//  Copyright © 2016 Fei Liang. All rights reserved.
//

import Foundation
import MapKit


class PointOfUser: NSObject, MKAnnotation {
    
    let title: String?
    let locationName: String
    let coordinate: CLLocationCoordinate2D
    
    init(title: String, locationName: String, coordinate: CLLocationCoordinate2D) {
        
        self.title = title
        self.locationName = locationName
        self.coordinate = coordinate
        
        super.init()
        
    }
    
    var subtitle: String? {
        return locationName
    }
    
    
}
