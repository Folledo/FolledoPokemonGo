//
//  MapAnnotation.swift
//  FolledoPokemonGo
//
//  Created by Samuel Folledo on 4/19/18.
//  Copyright © 2018 Samuel Folledo. All rights reserved.
//

import MapKit

class MapAnnotation: NSObject, MKAnnotation { //creates a class MapAnnotation that implements MKAnnotation
    
    let coordinate: CLLocationCoordinate2D //MKAnnotation requires a var coordinates
    let title: String? //and an optional title
    let item: ARItem
    
    init(location: CLLocationCoordinate2D, item: ARItem) {
        self.coordinate = location
        self.item = item
        self.title = item.itemDescription
    }
    
}

