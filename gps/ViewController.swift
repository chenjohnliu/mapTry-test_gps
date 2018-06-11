//
//  ViewController.swift
//  gps
//
//  Created by MCNLAB on 2018/5/30.
//  Copyright © 2018年 MCNLAB. All rights reserved.
//

import UIKit
import MapKit

protocol HandleMapSearch{
    func dropPinZoomIn(placemark: MKPlacemark)
}


class ViewController: UIViewController {
    var resultSearchController: UISearchController? = nil
    let locationManager = CLLocationManager()
    var selectedPin: MKPlacemark? = nil
    var destinationLatitude = 1.1
    var destinationLongitude = 1.1
    @IBOutlet weak var mapView: MKMapView!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        locationManager.delegate = self
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.requestWhenInUseAuthorization()
        locationManager.requestLocation()
        
        
        let locationSearchTable = storyboard!.instantiateViewController(withIdentifier: "LocationSearchTable") as! LocationSearchTable
        resultSearchController = UISearchController(searchResultsController: locationSearchTable)
        resultSearchController?.searchResultsUpdater = locationSearchTable
        
        
        let searchBar = resultSearchController!.searchBar
        searchBar.sizeToFit()
        searchBar.placeholder = "請輸入地名"
        navigationItem.titleView = resultSearchController?.searchBar
        
        resultSearchController?.hidesNavigationBarDuringPresentation = false
        resultSearchController?.dimsBackgroundDuringPresentation = true
        definesPresentationContext = true
        
        locationSearchTable.mapView = mapView
        locationSearchTable.handleMapSearchDelegate = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    
    func setDestination()
    {
        //create the url with NSURL
        let latitude = String(destinationLatitude)
        let longitude = String(destinationLongitude)
        let url = URL(string: "https://ntust12.000webhostapp.com/api/destination/insert.php?latitude="+latitude+"&longitude="+longitude)! //change the url
        
        //create the session object
        let session = URLSession.shared
        
        //now create the URLRequest object using the url object
        let request = URLRequest(url: url)
        
        //create dataTask using the session object to send data to the server
        let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
            
            guard error == nil else {
                return
            }
            
            guard let data = data else {
                return
            }
            
            do {
                //create json object from data
                if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                    print(json)
                }
            } catch let error {
                print(error.localizedDescription)
            }
        })
        task.resume()
    }
    
    @objc func getDirections() {
        let alert = UIAlertController(title: "您要設定這裡為目的地嗎？", message: nil, preferredStyle: UIAlertControllerStyle.alert)
        let ok = UIAlertAction(title: "確定", style: UIAlertActionStyle.default) { (UIAlertAction) in
            self.setDestination()
        }
        alert.addAction(ok)
        let cancel = UIAlertAction(title: "取消", style:UIAlertActionStyle.default, handler: nil)
        alert.addAction(cancel)
        
        
        present(alert, animated: true, completion: nil)

    }
}


extension ViewController : CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
        if status == .authorizedWhenInUse {
            locationManager.requestLocation()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if let location = locations.first {
            let span = MKCoordinateSpanMake(0.05, 0.05)
            let region = MKCoordinateRegion(center: location.coordinate, span: span)
            mapView.setRegion(region, animated: true)
            
            //create the url with NSURL
            let latitude = String(describing: location.coordinate.latitude)
            let longitude = String(describing: location.coordinate.longitude)
            let url = URL(string: "https://ntust12.000webhostapp.com/api/current_position/update.php?id=1&latitude="+latitude+"&longitude="+longitude)! //change the url
            
            //create the session object
            let session = URLSession.shared
            
            //now create the URLRequest object using the url object
            let request = URLRequest(url: url)
            
            //create dataTask using the session object to send data to the server
            let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
                
                guard error == nil else {
                    return
                }
                
                guard let data = data else {
                    return
                }
                
                do {
                    //create json object from data
                    if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
                        print(json)
                    }
                } catch let error {
                    print(error.localizedDescription)
                }
            })
            task.resume()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("error:: \(error)")
    }
}


extension ViewController: HandleMapSearch {
    func dropPinZoomIn(placemark: MKPlacemark) {
        // cache the pin
        selectedPin = placemark
        // clear existing pins
        mapView.removeAnnotations(mapView.annotations)
        let annotation = MKPointAnnotation()
        annotation.coordinate = placemark.coordinate
        annotation.title = placemark.name
        if let city = placemark.locality,
            let country = placemark.country {
            annotation.subtitle = "\(city) \(country)"
        }
        mapView.addAnnotation(annotation)
        mapView.selectAnnotation(annotation, animated: true)
        let span = MKCoordinateSpanMake(0.05, 0.05)
        let region = MKCoordinateRegionMake(placemark.coordinate, span)
        mapView.setRegion(region, animated: true)
        destinationLatitude = placemark.coordinate.latitude
        destinationLongitude = placemark.coordinate.longitude

//        let alert = UIAlertController(title: "alert", message: nil, preferredStyle: UIAlertControllerStyle.alert)
//        let ok = UIAlertAction(title: "ok", style: UIAlertActionStyle.default) { (UIAlertAction) in
//            fuck()
//        }
//        alert.addAction(ok)
//        func fuck()
//        {
//            
//        }
//        present(alert, animated: true, completion: nil)
    }
}


extension ViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if annotation is MKUserLocation {
            return nil
        }
        
        let reuseId = "pin"
        let pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuseId)
        pinView.pinTintColor = UIColor.orange
        pinView.canShowCallout = true
        
        let smallSquare = CGSize(width: 30, height: 30)
        let button = UIButton(frame: CGRect(origin: CGPoint(x:0, y:0), size: smallSquare))
        button.setBackgroundImage(UIImage(named: "pedestrian"), for: .normal)
        button.addTarget(self, action: #selector(getDirections), for: .touchUpInside)
        pinView.leftCalloutAccessoryView = button
        
        return pinView
    }
//    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
//                let alert = UIAlertController(title: "您要設定這裡為目的地嗎？", message: nil, preferredStyle: UIAlertControllerStyle.alert)
//                let ok = UIAlertAction(title: "ok", style: UIAlertActionStyle.default) { (UIAlertAction) in
//                    setDestination()
//                }
//                alert.addAction(ok)
//                let cancel = UIAlertAction(title: "取消", style:UIAlertActionStyle.default, handler: nil)
//                alert.addAction(cancel)
//                func setDestination()
//                {
//                    //create the url with NSURL
//                    let latitude = String(destinationLatitude)
//                    let longitude = String(destinationLongitude)
//                    let url = URL(string: "https://ntust12.000webhostapp.com/api/destination/insert.php?latitude="+latitude+"&longitude="+longitude)! //change the url
//
//                    //create the session object
//                    let session = URLSession.shared
//
//                    //now create the URLRequest object using the url object
//                    let request = URLRequest(url: url)
//
//                    //create dataTask using the session object to send data to the server
//                    let task = session.dataTask(with: request as URLRequest, completionHandler: { data, response, error in
//
//                        guard error == nil else {
//                            return
//                        }
//
//                        guard let data = data else {
//                            return
//                        }
//
//                        do {
//                            //create json object from data
//                            if let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers) as? [String: Any] {
//                                print(json)
//                            }
//                        } catch let error {
//                            print(error.localizedDescription)
//                        }
//                    })
//                    task.resume()
//                }
//                present(alert, animated: true, completion: nil)
//    }
}
