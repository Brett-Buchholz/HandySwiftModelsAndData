//
//  LocationManager.swift
//  HandySwiftModelsAndData
//
//  Created by Brett Buchholz on 10/27/24.
//

import Foundation
import MapKit //Note that MapKit includes CoreLocation

@MainActor
@Observable
class LocationManager: NSObject {
    var location: CLLocation?
    var region = MKCoordinateRegion()
    
    private let locationManager = CLLocationManager()
    
    override init() {
        super.init()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.distanceFilter = kCLDistanceFilterNone
        locationManager.requestAlwaysAuthorization()
        locationManager.startUpdatingLocation() //Remember to update the Info.plist
        locationManager.delegate = self
    }
}

extension LocationManager: @preconcurrency CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        guard let location = locations.last else { return }
        self.location = location
        self.region = MKCoordinateRegion(center: location.coordinate, latitudinalMeters: 5000, longitudinalMeters: 5000)
    }
}


