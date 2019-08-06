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
import Firebase

class ViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate, GMSMapViewDelegate, UITextFieldDelegate, UITableViewDelegate, UITableViewDataSource {
    //Latitude: 43.6544, longitude: -79.3828 //Eaton Centre
    
    // Google Maps API Key
    let apiKey = "AIzaSyBOhv23avprd-POQZAO-zCnYwFKfV8FqX0"//"AIzaSyAj8DEFdCP652-ZLqtd-2g6x3nH1Lx37e0"
    
    var googleMaps: GMSMapView?
    
    // UI
    let mapView = MKMapView()
    let indicator = UIView()
    
    let destinationButton = UIButton()
    let originButton = UIButton()
    let submitButton = UIButton()
    let chooseButton = UIButton()

    let sampleButton = UIButton()
    
    var searchingTextField = UITextField()
    
    var searchingTableView = UITableView()
    let identifierForTableViewCell: String = "searchingCell"
    
    var keyboardHeight: CGFloat = 0

    // Map
    let manager: CLLocationManager = CLLocationManager()
    var dirArray: [MKDirections] = []
    var datas: APIResponse = APIResponse()
    var originPoint: CLLocation = CLLocation(latitude: 0, longitude: 0)
    var destinationPoint: CLLocation = CLLocation(latitude: 0, longitude: 0)
    
    var isOriginButtonClicked = false
    
    var originStreetName: String = ""
    var destinationStreetName: String = ""
    
    var marker = GMSMarker()
    
    // DB
    var db: Firestore!
    var storeList: [String:[String:Any]] = [:]
    var copiedStoreList: [String] = []
    var selectedStore: String = ""

    //camera(withLatitude: 43.6544, longitude: -79.3828, zoom: 20.0) //Eaton Centre
    var currentLocation: CLLocationCoordinate2D = CLLocationCoordinate2D(latitude: 43.6544, longitude: -79.3828)

    
    //MARK: - viewDidLoad
    override func viewDidLoad() {
        super.viewDidLoad()

        checkLocationService()

        setDB()
        getCollection()

        setTextField()
        setTableView()
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillAppear),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillDisappear),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    func setGoogleMaps() {
        googleMaps = GMSMapView(frame: CGRect(x: 0, y: self.view.bounds.size.height * 0.2, width: self.view.bounds.size.width, height: self.view.bounds.size.height * 0.7))
        var camera = GMSCameraPosition.camera(withLatitude: 43.6544, longitude: -79.3828, zoom: 20.0)
        
        self.googleMaps?.delegate = self
        self.googleMaps?.isMyLocationEnabled = true
        self.googleMaps?.settings.myLocationButton = true
        self.googleMaps?.settings.compassButton = false

        self.googleMaps?.isIndoorEnabled = true
        self.googleMaps?.settings.indoorPicker = true
//        self.googleMaps?.settings.rotateGestures = false
//        self.googleMaps?.settings.setAllGesturesEnabled(false)
//        self.googleMaps?.settings.consumesGesturesInView = true
//        self.googleMaps?.setMinZoom(16, maxZoom: 20)
//        self.googleMaps?.animate(toViewingAngle: -20)
//        self.googleMaps?.isBuildingsEnabled = false
//        self.googleMaps?.settings.zoomGestures = false
//        self.googleMaps?.settings.scrollGestures = false

        guard let googleMaps = self.googleMaps else {
            return
        }
        self.view.addSubview(googleMaps)
        
        if let location = manager.location?.coordinate {
            currentLocation = location
            camera = GMSCameraPosition.camera(withLatitude: location.latitude, longitude: location.longitude, zoom: 16.0)
        }
        googleMaps.camera = camera
    }

    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        let location = locations.last
        
        let camera = GMSCameraPosition.camera(withLatitude: (location?.coordinate.latitude)!, longitude: (location?.coordinate.longitude)!, zoom: 17.0)
        
        guard let googleMaps = googleMaps else {
            return
        }
        googleMaps.animate(to: camera)
        
        //Finally stop updating location otherwise it will come again and again in this delegate
        self.manager.stopUpdatingLocation()
    }
    
    func checkLocationService() {
        if CLLocationManager.locationServicesEnabled() {    // to check a status of a service for location
            checkAuthorization()
        } else {
            // display alert to the user
        }
    }
    
    func setLocationManager() {
        manager.delegate = self                             // assign its delegate
        manager.desiredAccuracy = kCLLocationAccuracyBest   // set accuracy
        manager.startUpdatingLocation()
    }
    
    //MARK: - Firebase - Get DB
    private func setDB() {
        let settings = FirestoreSettings()
        Firestore.firestore().settings = settings
        db = Firestore.firestore()
    }
    
    private func getCollection() {
        db.collection("eatonCentre").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                for document in querySnapshot!.documents {
                    print("\(document.documentID) => \(document.data())")
                    let emp:[String:Any] = document.data()
                    self.storeList[document.documentID] = emp

                }
            }
        }
    }
    
    //MARK: - Create and Manage TextField
    func setTextField() {
        searchingTextField.frame = CGRect(x: 10, y: 30, width: self.view.bounds.size.width-20, height: 50)
        searchingTextField.placeholder = "Store name"
        searchingTextField.layer.cornerRadius = 15.0
        searchingTextField.layer.borderWidth = 0.1
        searchingTextField.layer.borderColor = UIColor.lightGray.cgColor
        searchingTextField.delegate = self
        searchingTextField.returnKeyType = .done
        searchingTextField.textAlignment = .center
        searchingTextField.clearButtonMode = .always
        searchingTextField.clearButtonMode = .whileEditing
        self.view.addSubview(searchingTextField)
        
        searchingTextField.addTarget(self, action: #selector(typeRecords(_ :)), for: .editingChanged)

    }

    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        if textField.text == "" {
            textField.resignFirstResponder()
            searchingTableView.isHidden = true
            
        }else {
            searchingTableView.isHidden = false
        }
        
        return true
    }
    
    @objc func typeRecords(_ textField: UITextField) {
        marker.map = nil
        
        searchingTableView.isHidden = false
        
        self.copiedStoreList.removeAll()
        
        if textField.text?.count != 0 {
            for store in storeList.keys {
                if let storeToSearch = textField.text{
                    let range = store.lowercased().range(of: storeToSearch, options: .caseInsensitive, range: nil, locale: nil)
                    if range != nil {
                        self.copiedStoreList.append(store)
                    }
                }
            }
        }
        searchingTableView.reloadData()
    }
    
    //MARK: - Create and Manage TableView
    func setTableView() {
        searchingTableView.frame = CGRect(x: 0, y: 80, width: self.view.bounds.size.width, height: self.view.bounds.size.height-80)
        
        searchingTableView.delegate = self
        searchingTableView.dataSource = self
        
        searchingTableView.register(UITableViewCell.self, forCellReuseIdentifier: identifierForTableViewCell)

        searchingTableView.alpha = 0.9
        
        self.view.addSubview(searchingTableView)
        searchingTableView.isHidden = true
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.copiedStoreList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: identifierForTableViewCell) else {
            return UITableViewCell()
        }

        cell.textLabel?.text = copiedStoreList[indexPath.row]
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        marker.map = nil
        
        tableView.deselectRow(at: indexPath, animated: true)
        selectedStore = copiedStoreList[indexPath.row]
        print(selectedStore)
        guard let dic = storeList[selectedStore] else {
            return
        }
        guard let dic2: Any = dic["place_id"] else {
            return
        }
        
        searchingTextField.text = selectedStore
        
        getPath(currentLocation, dic2)
        
        //lat, lon
        guard let lat: Any = dic["lat"] else {
            return
        }
        
        guard let lon: Any = dic["lon"] else {
            return
        }
        
        addMarker(lat, lon)
    }
    
    func addMarker(_ lat: Any, _ lon: Any) {
        
        let latitudeStr = String(describing: lat)
        guard let latitude = Double(latitudeStr) else {
            return
        }
        
        let longitudeStr = String(describing: lon)
        guard let longitude = Double(longitudeStr) else {
            return
        }
        
        let position = CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
        marker = GMSMarker(position: position)
        marker.title = selectedStore
        //image download url
        //https://www.flaticon.com/free-icon/bag_138271#term=shopping%20bag&page=1&position=8
        marker.icon = UIImage(named: "bag")
        marker.map = googleMaps
        
        setCamera(latitude,longitude)
    }
    
    func setCamera(_ lat: Double, _ lon: Double) {
        let current = CLLocationCoordinate2D(latitude: currentLocation.latitude, longitude: currentLocation.longitude)
        let destination = CLLocationCoordinate2D(latitude: lat,longitude: lon)
        let bounds = GMSCoordinateBounds(coordinate: current, coordinate: destination)
        
        guard let googleMaps = googleMaps else {
            return
        }
        
        let camera = googleMaps.camera(for: bounds, insets: UIEdgeInsets())!
        
        
        googleMaps.camera = camera
    }
    
    //MARK: - Notification for the keyboard's action
    @objc func keyboardWillAppear(_ notification: Notification) {
        if let keyboardFrame: NSValue = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue {
            let keyboardRectangle = keyboardFrame.cgRectValue
            let keyboardHeight = keyboardRectangle.height
            searchingTableView.frame.size.height = self.view.frame.height - (searchingTextField.frame.origin.y + searchingTextField.frame.size.height + keyboardHeight)
        }
    }
    
    @objc func keyboardWillDisappear(_ notification: Notification) {
        searchingTableView.frame.size.height = self.view.bounds.size.height - 80
    }

    //MARK: - Get Information from Google Maps API for path
    func getPath(_ current: CLLocationCoordinate2D, _ place_id: Any) {
        
        let placeId: String = String(describing: place_id)
        
//////////Example - requesting a direction to Google Maps API
//        origin=24+Sussex+Drive+Ottawa+ON
//        origin=41.43206,-81.38992
//        origin=place_id:ChIJ3S-JXmauEmsRUcIaWtf4MzE
//        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(newOriginStreetNameString)&destination=\(newDestinationStreetNameString)&mode=walking&key="+apiKey

        let urlString = "https://maps.googleapis.com/maps/api/directions/json?origin=\(current.latitude),\(current.longitude)&destination=place_id:\(placeId)&region=ca&mode=walking&key="+apiKey

        guard let url = URL(string: urlString) else {
            return
        }
        
        let task = URLSession.shared.dataTask(with: url) { (data, response, error) in
            guard error == nil else {
                print(error!.localizedDescription)
                return
            }
            
            guard let data = data else {
                return
            }

            guard let jsonResult = try? JSONSerialization.jsonObject(with: data, options: .allowFragments) as? [String: Any], let jsonResponse = jsonResult else {
                print("error in JSONSerialization")
                return
            }
            
            guard let routes = jsonResponse["routes"] as? [Any] else {
                return
            }
                    
            guard let route = routes[0] as? [String: Any] else {
                return
            }
            
            guard let overview_polyline = route["overview_polyline"] as? [String: Any] else {
                return
            }
            
            guard let polyLineString = overview_polyline["points"] as? String else {
                return
            }
            
            //Call this method to draw path on map
            self.drawPath(from: polyLineString)
            }
        
        

            task.resume()
    }
    
    func drawPath(from polyStr: String){
        let path = GMSPath(fromEncodedPath: polyStr)
        let polyline = GMSPolyline(path: path)
        polyline.strokeWidth = 1.0
        polyline.strokeColor = UIColor.black
        polyline.map = googleMaps
        
        DispatchQueue.main.async {
            self.searchingTableView.isHidden = true
            self.searchingTextField.resignFirstResponder()
        }

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
                setGoogleMaps()
                break
            case .authorizedAlways :                        // we always ask for the using location
                                                            // while using the app so it wiil be not used but we need it
                mapView.showsUserLocation = true            // because the user can changed the status at Settings
                setGoogleMaps()
                break
        }
    }
}

