//
//  mapViewController.swift
//  MMB
//
//  Created by Fei Liang on 12/3/16.
//  Copyright © 2016 Fei Liang. All rights reserved.
//

import UIKit
import MapKit
import CoreLocation
import FirebaseDatabase

class mapViewController: UIViewController, CLLocationManagerDelegate, MKMapViewDelegate {
    
    var ref = FIRDatabaseReference.init()
    var nearbyuserHandle = FIRDatabaseHandle.init()
    
    var username: String = ""
    var userslist: [String] = []
    var myCoodinate: CLLocation = CLLocation(latitude: 38.64782789986266, longitude: -90.30471171969812)
    let regionRadius: CLLocationDistance = 200.0
    var usersLocations: [String:CLLocation] = [:]
    
    var usersLocationDic: [String: Double] = [:]
    var userScoreDic: [String: Float] = [:]
    var userImageDic: [String: String] = [:]
    var distanceRange = 200.0
    var othername: String = ""
    var scoreColorDic = ["1":UIColor.cyan, "2":UIColor.yellow, "3":UIColor.green, "4":UIColor.blue, "5":UIColor.black]

    var userAnnotation = MKPointAnnotation()
    
    let locationManager = CLLocationManager()

    @IBOutlet weak var usersMapView: MKMapView!
    @IBOutlet weak var mapSwitch: UISwitch!
    
//==============================================================
    @IBAction func mapChangedPressed(_ sender: Any) {
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(myCoodinate.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        usersMapView.setRegion(coordinateRegion, animated: true)
        
        if(mapSwitch.isOn){
            usersMapView.mapType = MKMapType.standard
        } else {
            usersMapView.mapType = MKMapType.satellite
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let mylatitude = locations[0].coordinate.latitude
        let mylongitude = locations[0].coordinate.longitude
        myCoodinate = CLLocation(latitude: mylatitude, longitude: mylongitude)
        
        let locationRef = ref.child("Users").child(username).child("location")
        let locationDic = ["latitude": mylatitude, "longitude": mylongitude]
        locationRef.setValue(locationDic)
        
        centerMapOnLocation(location: myCoodinate)
        self.usersMapView.showsUserLocation = true
        
    }
    
    
    
//================================================================
    func centerMapOnLocation(location: CLLocation) {
        
        usersMapView.setCenter(myCoodinate.coordinate, animated: true)
        
    }
    
    func computeScore(scoresDic: NSDictionary) -> Float {
        var totalScore = Float(0)
        var totalWeight = Float(0)
        var finalScore = Float(0)
        for (_, scores) in scoresDic{
            
            let myMirror = Mirror(reflecting: scores)
            if  (String(describing: myMirror.subjectType) == "Array<AnyObject>") {
            }
            for (score, weight) in (scores as! NSDictionary) {
                
                let s = Int(((score as! NSString) as String))! % 10
                
                let ws = ((weight as! NSString) as String).replacingOccurrences(of: "\"", with: "")
                let w = Float(ws)
                totalScore += w! * Float(s)
                totalWeight += w!
            }
        }
        finalScore = Float(totalScore)/Float(totalWeight)
        return finalScore
    }
    
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation)
        -> MKAnnotationView? {
            if annotation is MKUserLocation {
                return nil
            }
            
            let reuserId = "pin"
            var pinView = mapView.dequeueReusableAnnotationView(withIdentifier: reuserId)
                as? MKPinAnnotationView
            if pinView == nil {
                //创建一个大头针视图
                pinView = MKPinAnnotationView(annotation: annotation, reuseIdentifier: reuserId)
                pinView?.canShowCallout = true
        
                //设置大头针颜色
                pinView?.pinTintColor = UIColor.red
                //设置大头针点击注释视图的右侧按钮样式
                pinView?.rightCalloutAccessoryView = UIButton(type: .detailDisclosure)
            }else{
                pinView?.annotation = annotation
            }
            
            return pinView
    }
    
    func mapView(_ mapView: MKMapView, annotationView view: MKAnnotationView,
                 calloutAccessoryControlTapped control: UIControl) {
        othername = ((view.annotation?.title)!)!
        self.performSegue(withIdentifier: "mapuser", sender: self)
        
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "mapuser" ){
            
            let nav = segue.destination as! otherUserViewController
            print(othername)
            nav.username = othername
        }
    }
    
//======================================================
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
        
        username = UserDefaults().string(forKey: "loginID")!
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        self.usersMapView.delegate = self
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        let coordinateRegion = MKCoordinateRegionMakeWithDistance(myCoodinate.coordinate, regionRadius * 2.0, regionRadius * 2.0)
        usersMapView.setRegion(coordinateRegion, animated: true)
        
        nearbyuserHandle = ref.child("Users").observe(.value, with: { snapshot in
            self.usersLocationDic = [:]
            self.userScoreDic = [:]
            self.userImageDic = [:]
            self.userslist = []
            
            
            
            let users = snapshot.value as! NSDictionary
            for (user, userInfo ) in users{
                if (user as! String) != UserDefaults().string(forKey: "loginID"){
                    let thisUserInfo = userInfo as! NSDictionary
                    if (thisUserInfo.object(forKey: "location") != nil) {
                        //                        print("\(user) has location")
                        
                        let thisUserLocation = thisUserInfo["location"] as! NSDictionary
                        let thisUserLatitude = thisUserLocation["latitude"]
                        let thisUserLongitude = thisUserLocation["longitude"]
                        let otherCoodinate = CLLocation(latitude: thisUserLatitude as! CLLocationDegrees, longitude: thisUserLongitude as! CLLocationDegrees)
                        let myDistance = self.myCoodinate.distance(from: otherCoodinate) as Double
                        if myDistance < self.distanceRange {
                            self.usersLocations[user as! String] = otherCoodinate
                            self.usersLocationDic[user as! String] = myDistance
                            self.userslist.append(user as! String)
                            if let scoreDic = (userInfo as! NSDictionary)["scores"]! as? NSDictionary{
                                let score = self.computeScore(scoresDic: scoreDic)
                                self.userScoreDic[user as! String] = score
                            }else{
                            }
                            if let imageAddress = (userInfo as! NSDictionary)["image"]! as? NSString{
                                self.userImageDic[user as! String] = imageAddress as String
                            }else{
                            }
                        }
                        
                    }else{
//                        print("\(user) has no location")
                    }
                }
            }
            self.usersMapView.removeAnnotations(self.usersMapView.annotations)
            for user in self.userslist{
                let objectAnnotation = MKPointAnnotation()
                //设置大头针的显示位置
                objectAnnotation.coordinate = (self.usersLocations[user]?.coordinate)!
                //设置点击大头针之后显示的标题
                objectAnnotation.title = user
                //设置点击大头针之后显示的描述
                objectAnnotation.subtitle = (NSString(format:"%.2f", self.userScoreDic[user]!) as String) as String
                //添加大头针
                self.usersMapView.addAnnotation(objectAnnotation)
                
            }
            
            
        })

    }

    override func viewDidDisappear(_ animated: Bool) {
        locationManager.stopUpdatingLocation()
        ref.removeObserver(withHandle: nearbyuserHandle)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}
