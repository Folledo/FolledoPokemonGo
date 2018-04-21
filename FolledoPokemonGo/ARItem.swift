//
//  ARItem.swift
//  FolledoPokemonGo
//
//  Created by Samuel Folledo on 4/19/18.
//  Copyright © 2018 Samuel Folledo. All rights reserved.
//

import Foundation
import CoreLocation
import SceneKit

struct ARItem {
    let itemDescription: String
    let location: CLLocation
    
    var itemNode: SCNNode?
    
    
}
