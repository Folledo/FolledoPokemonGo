//
//  MapViewController.swift
//  FolledoPokemonGo
//
//  Created by Samuel Folledo on 4/19/18.
//  Copyright © 2018 Samuel Folledo. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation

class MapViewController: UIViewController, ARControllerDelegate {
    
    @IBOutlet weak var mapView: MKMapView!
    
    var targets = [ARItem]()
    let locationManager = CLLocationManager() //p.3
    var userLocation: CLLocation? //p.4
    
    var selectedAnnotation: MKAnnotation?//p.15 will be used to remove it from MapView
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        mapView.userTrackingMode = MKUserTrackingMode.followWithHeading //userTrackingMode = he mode used to track the user location.
        //MKUserTrackingMode = The mode used to track the user location on the map. 3 UserTrackingMode
        //none = The map does not follow the user location.
        //follow = The map follows the user location.
        //followWithHeading = The map follows the user location and rotates when the heading changes.
        
        if CLLocationManager.authorizationStatus() == .notDetermined { //ask permission. If forgotten, mapView will fail to locate the user. Always required for any location services
            locationManager.requestWhenInUseAuthorization()
        }
        
        setUpLocations()
        
    }
    
    
    func setUpLocations() { //p.2
        let firstTarget = ARItem(itemDescription: "wolf", location: CLLocation(latitude: 40.525206, longitude: -74.441388), itemNode: nil) //wolf in 0,0
        targets.append(firstTarget)
        
        let secondTarget = ARItem(itemDescription: "wolf", location: CLLocation(latitude: 40.525206, longitude: -74.441388), itemNode: nil) //wolf in 0,0
        targets.append(secondTarget)
        
        let thirdTarget = ARItem(itemDescription: "dragon", location: CLLocation(latitude: 40.525206, longitude: -74.441388), itemNode: nil) //dragon in 0,0
        targets.append(thirdTarget)
        
        for item in targets { //p. 3 iterate through all items inside the targets array and add annotation for each target
            let annotation = MapAnnotation(location: item.location.coordinate, item: item)
            self.mapView.addAnnotation(annotation)
        }
        
    }
}

extension MapViewController: MKMapViewDelegate { //p. 4 call this method each time MapView updates the location of the device, and store location to use in another method
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        self.userLocation = userLocation.location
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        let coordinate = view.annotation!.coordinate //p. 5 get the coordinate of the seleced annotation
        
        if let userCoordinate = userLocation { //p. 5 make sure the optional userLocation is populated
            if userCoordinate.distance(from: CLLocation(latitude: coordinate.latitude, longitude: coordinate.longitude)) < 50 { //p. 5 make sure tapped item is within range of the users location
                let storyboard = UIStoryboard(name: "Main", bundle: nil)
                
                if let viewController = storyboard.instantiateViewController(withIdentifier: "ARViewController") as? ViewController { //p.5 instantiate an instance of ARViewController from the storyboard
                    
    //p.15 #1 sets the delegate of ViewController to MapViewController
                    viewController.delegate = self
                    
                    if let mapAnnotation = view.annotation as? MapAnnotation {  //p.5 checks if the tapped annoation is a MapAnnotation
                        
                        viewController.target = mapAnnotation.item //p.8 before you present the viewController, you store a reference to the ARItem of the tapped annotation. So viewController knows what kind of enemy you're facing
                        
                        viewController.userLocation = mapView.userLocation.location! //p.11 To pass the user's location along to viewController
                        
    //p.15 #2 then save the selected annotation
                        selectedAnnotation = view.annotation
                        
                        self.present(viewController, animated: true, completion: nil) //p.5 present viewController
                    }
                }
            }
        }
    }
    
//protocol method p.15
    func viewController(controller: ViewController, tappedTarget: ARItem) {
        self.dismiss(animated: true, completion: nil) //p.15 #1 dismiss the augmented reality view
        let index = self.targets.index(where: {$0.itemDescription == tappedTarget.itemDescription}) //p.15 #2 then remove the target from the target list
        self.targets.remove(at: index!)
        
        if selectedAnnotation != nil {
            mapView.removeAnnotation(selectedAnnotation!) //p.15 #3 finally you remove the annotation from the map
        }
    }
    
}
