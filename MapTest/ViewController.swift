//
//  ViewController.swift
//  MapTest
//
//  Created by COMATOKI on 2019-07-30.
//  Copyright © 2019 COMATOKI. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import GoogleMaps
import GooglePlaces

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    
    // Google Maps API Key
    let apiKey = "AIzaSyBOhv23avprd-POQZAO-zCnYwFKfV8FqX0"//"AIzaSyAj8DEFdCP652-ZLqtd-2g6x3nH1Lx37e0"
    
    // UI
    let mapView = MKMapView()
    let indicator = UIView()
    
    let destinationButton = UIButton()
    let originButton = UIButton()
    let submitButton = UIButton()
    let chooseButton = UIButton()

    // Map
    let manager: CLLocationManager = CLLocationManager()
    var dirArray: [MKDirections] = []
    var datas: APIResponse = APIResponse()
    var originPoint: CLLocation = CLLocation(latitude: 0, longitude: 0)
    var destinationPoint: CLLocation = CLLocation(latitude: 0, longitude: 0)
    
    var isOriginButtonClicked = false
    
    var originStreetName: String = ""
    var destinationStreetName: String = ""
    
    //MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.

        setupMapView()
        checkLocationService()
        setupViewForPath()
        createIndicator()
    }
    
    //MARK: - Set up UIs and Components
    func setupMapView() {
        // make room for a View named container
        mapView.frame = CGRect(x: 0, y: 160, width: self.view.frame.width, height: self.view.frame.height - 160)
        self.view.addSubview(mapView)           // add mapView on the view originally provided
        mapView.delegate = self                 // assign its delegate
    }
    
    func checkLocationService() {
        if CLLocationManager.locationServicesEnabled() {    // to check a status of a service for location
            setLocationManager()
            checkAuthorization()
        } else {
            // display alert to the user
        }
    }
    
    func setLocationManager() {
        manager.delegate = self                             // assign its delegate
        manager.desiredAccuracy = kCLLocationAccuracyBest   // set accuracy
    }
    
    func setupViewForPath() {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: self.view.frame.width, height: 160))
        
        container.backgroundColor = .white
        self.view.addSubview(container)
        
        originButton.frame = CGRect(x: 20, y: 40, width: container.frame.width - 40, height: 20)
        originButton.backgroundColor = .black
        originButton.setTitle("Starting point", for: .normal)
        originButton.tintColor = .white
        originButton.addTarget(self, action: #selector(chooseOriginLocation), for: .touchUpInside)
        container.addSubview(originButton)
        
        destinationButton.frame = CGRect(x: 20, y: 80, width: container.frame.width - 40, height: 20)
        destinationButton.backgroundColor = .black
        destinationButton.setTitle("Destination point", for: .normal)
        destinationButton.tintColor = .white
        destinationButton.addTarget(self, action: #selector(chooseDestinationLocation), for: .touchUpInside)
        
        container.addSubview(destinationButton)
        
        submitButton.frame = CGRect(x: 20, y: 120, width: (self.view.frame.width - 40)/2, height: 30)
        submitButton.setTitle("Get the Path", for: .normal)
        submitButton.addTarget(self, action: #selector(clickGetPathButton), for: .touchUpInside)
        submitButton.backgroundColor = .gray
        submitButton.isEnabled = false
        
        chooseButton.frame = CGRect(x: submitButton.frame.origin.x + submitButton.frame.width + 10, y: 120, width: (self.view.frame.width - 60)/2, height: 30)
        chooseButton.setTitle("Reset", for: .normal)
        chooseButton.addTarget(self, action: #selector(clickResetButton), for: .touchUpInside)
        chooseButton.backgroundColor = .black
        
        container.addSubview(submitButton)
        container.addSubview(chooseButton)
    }
    
    @objc func clickGetPathButton(sender: UIButton!) {
        print("Get Path!")
        self.indicator.isHidden = true
        getPath()
        drawPath()
    }
    
    @objc func clickResetButton(sender: UIButton!) {
        self.indicator.isHidden = true
        
        originButton.setTitle("Starting point", for: .normal)
        destinationButton.setTitle("Destination point", for: .normal)
        
        submitButton.backgroundColor = .gray
        submitButton.isEnabled = false
        chooseButton.setTitle("Reset", for: .normal)
        isOriginButtonClicked = false
        
        originStreetName = ""
        destinationStreetName = ""
    }
    
    @objc func chooseOriginLocation(sender: UIButton!) {
        self.indicator.isHidden = false
        isOriginButtonClicked = true
        
    }
    
    @objc func chooseDestinationLocation(sender: UIButton!) {
        self.indicator.isHidden = false
        isOriginButtonClicked = false
    }
    
    func createIndicator() {
        self.indicator.frame = CGRect(x: self.view.center.x-5, y: self.view.center.y-5, width: 10, height: 10)
        self.view.addSubview(self.indicator)
        self.indicator.backgroundColor = .black
        self.indicator.isHidden = true
    }

    //MARK: - Get Information from Google for path
    func getPath() {

        let originStreetNameString = originStreetName
        let newOriginStreetNameString = originStreetNameString.replacingOccurrences(of: " ", with: "+")
        
        let destinationStreetNameString = destinationStreetName
        let newDestinationStreetNameString = destinationStreetNameString.replacingOccurrences(of: " ", with: "+")
        
        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(newOriginStreetNameString)&destination=\(newDestinationStreetNameString)&mode=walking&key="+apiKey

        guard let url = URL(string: urlString) else {
            return
        }
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            if let error = error {
                print("error: \(error)")
            } else {
                guard let data = data else {
                    return
                }
                do {
                    let apiResponse = try JSONDecoder().decode(APIResponse.self, from: data)
                    self.datas = apiResponse
                } catch(let err) {
                    print("ERR : \n \(err.localizedDescription)")
                }
            }
        }
        task.resume()
    }

    //MARK: - Check Authorization for using location and set user's current location
    func checkAuthorization() {
        switch CLLocationManager.authorizationStatus() {    //  get the authrization's status and deal with all statuses
            
            case .denied :                                  // the user not allows using the location
                print("Denied")
                break
            case .restricted:                               // the user is might controlled using phone from their parents
                print("Restricted")
                break
            case .notDetermined :                           // the app launchs first time - wait for the decision
                print("not Determined")
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse :                     // the user agree to use location service while using the app
                mapView.showsUserLocation = true
                centerViewOnUserLocation()
                break
            case .authorizedAlways :                        // we always ask for the using location
                                                            // while using the app so it wiil be not used but we need it
                mapView.showsUserLocation = true            // because the user can changed the status at Settings
                centerViewOnUserLocation()
                break
        }
    }
    
    //Display current location & get which floor the user is staying
    func centerViewOnUserLocation() {
        if let location = manager.location?.coordinate {
            let region = MKCoordinateRegion.init(center: location, latitudinalMeters: 500, longitudinalMeters: 500)
            mapView.setRegion(region, animated: true)
            if let floor: CLFloor = manager.location?.floor {
                print("floor : \(floor.level)") //2146959360
            }
        }
    }

    //MARK: - Draw Path Methods
    func drawPath() {
        let request = setDataForDrawRoute()
        let directions = MKDirections(request: request)
        resetMapView(withNew: directions)
        directions.calculate { [unowned self] (response, error) in
        guard let response = response else { return }
        for route in response.routes {
            self.mapView.addOverlay(route.polyline)
            self.mapView.setVisibleMapRect(route.polyline.boundingMapRect, animated: true)
            }} 
    }
    
    func setDataForDrawRoute() -> MKDirections.Request {
        let startingLocation = MKPlacemark(coordinate: originPoint.coordinate)
        let destinationLocation = MKPlacemark(coordinate: destinationPoint.coordinate)
        
        let request = MKDirections.Request()
        request.source = MKMapItem(placemark: startingLocation)
        request.destination = MKMapItem(placemark: destinationLocation)
        request.transportType = .walking
        request.requestsAlternateRoutes = true
            
        return request
    }
    
    func resetMapView(withNew directions: MKDirections) {
        mapView.removeOverlays(mapView.overlays)
        dirArray.append(directions)
        let _ = dirArray.map { $0.cancel() }
    }

    //MARK: - CLLocationManagerDelegate
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        // to handle if the user changed the authorization 
        checkAuthorization()
    }
    
    //MARK: - MKMapViewDelegate
    // MapKit will call this method when it realizes there is an MKOverlay object in the region that the map view is displaying.
    func mapView(_ mapView: MKMapView, rendererFor overlay: MKOverlay) -> MKOverlayRenderer {
        let renderer = MKPolylineRenderer(overlay: overlay as! MKPolyline)
        renderer.strokeColor = .black
        
        return renderer
    }

    func mapView(_ mapView: MKMapView, regionDidChangeAnimated animated: Bool) {
        if !(self.indicator.isHidden) {
            let center = getLocation(mapView: mapView)
            
            let geoCode = CLGeocoder()
        
            geoCode.reverseGeocodeLocation(center) { (placemarks, err) in

            if let error = err {
                print(error.localizedDescription)
                return
            }
            
            guard let placemark = placemarks?.first else {
                return
            }
            
            let streetNum = placemark.subThoroughfare ?? ""
            let streetName = placemark.thoroughfare ?? ""

            DispatchQueue.main.async {
                
                if self.isOriginButtonClicked {
                    self.originButton.setTitle("\(streetNum) \(streetName)", for: .normal)
                    self.originStreetName = "\(streetNum) \(streetName)"
                    self.originPoint = center
                    if self.destinationStreetName != "" {
                        self.submitButton.backgroundColor = .black
                        self.submitButton.isEnabled = true
                    } else {
                        self.submitButton.backgroundColor = .gray
                        self.submitButton.isEnabled = false
                    }
                } else {
                    self.destinationButton.setTitle("\(streetNum) \(streetName)", for: .normal)
                    self.destinationStreetName = "\(streetNum) \(streetName)"
                    self.destinationPoint = center
                    if self.originStreetName != "" {
                        self.submitButton.backgroundColor = .black
                        self.submitButton.isEnabled = true
                    } else {
                        self.submitButton.backgroundColor = .gray
                        self.submitButton.isEnabled = false
                    }
                }
            }
        }
        }
    }
    
    func getLocation(mapView: MKMapView) -> CLLocation {
        let latitude = mapView.centerCoordinate.latitude
        let longitude  = mapView.centerCoordinate.longitude
        
        return CLLocation(latitude: latitude, longitude: longitude)
    }
    
}

