//
//  nearbyViewController.swift
//  MMB
//
//  Created by Fei Liang on 11/24/16.
//  Copyright © 2016 Fei Liang. All rights reserved.
//

import UIKit
import CoreLocation
import FirebaseDatabase
import FirebaseStorage

class nearbyViewController: UIViewController, CLLocationManagerDelegate, UITableViewDelegate, UITableViewDataSource  {

    
    let locationManager = CLLocationManager()
    
    var myCoodinate: CLLocation = CLLocation(latitude: 0.0, longitude: 0.0)
    
    var ref = FIRDatabaseReference.init()
    var username = ""
    var usersLocationDic: [String: Double] = [:]
    var userScoreDic: [String: Float] = [:]
    var userImageDic: [String: String] = [:]
    var userslist: [String] = []
    var selectedUserName = ""
    var nearbyuserHandle = FIRDatabaseHandle.init()
    var distanceRange = Double(200)
    
    var usersLocations: [CLLocation] = []
    
    
// ===========================================================
    @IBOutlet weak var myPositionLabel: UILabel!
    
    @IBOutlet weak var nearbyUsersTableView: UITableView!
    
    @IBOutlet weak var distanceRangeSlider: UISlider!
    
    @IBOutlet weak var distanceRangeLabel: UILabel!
    
    @IBAction func changeDistanceRangePressed(_ sender: Any) {
        self.performSegue(withIdentifier: "showinmap", sender: self)
    }

    
    @IBAction func sliderValueChangded(_ sender: Any) {
        distanceRangeLabel.text = String( format: "%.2f", distanceRangeSlider.value ) + " M"
    }
    
    
    
    
// ===========================================================
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        
        let mylatitude = locations[0].coordinate.latitude
        let mylongitude = locations[0].coordinate.longitude
        myCoodinate = CLLocation(latitude: mylatitude, longitude: mylongitude)
        
        let locationRef = ref.child("Users").child(username).child("location")
//        let latitudeRef = locationRef.child("latitude")
//        let longitudeRef = locationRef.child("longitude")
//        latitudeRef.setValue(mylatitude)
//        longitudeRef.setValue(mylongitude)
        let locationDic = ["latitude": mylatitude, "longitude": mylongitude]
        locationRef.setValue(locationDic)
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userslist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let userCell = tableView.dequeueReusableCell(withIdentifier: "nearbyUsersCell", for: indexPath) as! nearbyUsersCell
        
        //        userCell.cellUserName.text = myArray[indexPath.row] as? String
        userCell.usernameLabel.text = userslist[indexPath.row]
        userCell.userScoreLabel.text = NSString(format:"%.2f", userScoreDic[userslist[indexPath.row]]!) as String
        
        userCell.userScoreLabel.layer.cornerRadius = userCell.userScoreLabel.frame.size.height/2
        userCell.userScoreLabel.layer.borderWidth = 1
        userCell.userScoreLabel.layer.borderColor = UIColor.black.cgColor
        
        let storage = FIRStorage.storage()
        let imageAddress = userImageDic[ userslist[indexPath.row] ]! as String
        let gsRef = storage.reference(forURL: imageAddress)
        gsRef.data(withMaxSize: 1 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                // Uh-oh, an error occurred!
                print("error to download the image")
            } else {
                userCell.userImageView.image = UIImage( data: data! )!
            }
        }
        userCell.userImageView.layer.cornerRadius = userCell.userImageView.frame.size.height/2
        userCell.userImageView.layer.borderWidth = 1
        userCell.userImageView.layer.borderColor = UIColor.black.cgColor
        userCell.userImageView.clipsToBounds = true
        
        userCell.userDistanceLabel.text = NSString(format: "%.2f", usersLocationDic[userslist[indexPath.row]]!) as String + " M"
        
        return userCell
        
    }
    
    //select to segue score page
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //        print(userslist[indexPath.row])
        
        selectedUserName = userslist[ indexPath.row ]
        
        self.performSegue(withIdentifier: "nearbyuser", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "nearbyuser" ){
            
            let nav = segue.destination as! otherUserViewController
            nav.username = selectedUserName
        }
//        if( segue.identifier == "showinmap" ){
        
//            let nav = segue.destination as! mapViewController
//            nav.myCoodinate = myCoodinate
//            nav.usersLocations = usersLocations
//            nav.userslist = userslist
            
//        }
    }
    
    //add friend
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var userToAddFriend = ""
        let addfirend = UITableViewRowAction(style: .default, title: "Add friend"){
            
            action, indexPath in
            userToAddFriend = self.userslist[ indexPath.row ]
            
            // add selected user to friend
            self.addFriend(userToAddFriend: userToAddFriend)
            
        }
        return [addfirend]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        
        return true
    }


// ==========================================================
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
    
    func addFriend(userToAddFriend: String){
        ref.child("Users").child(UserDefaults().string(forKey: "loginID")!).child("friends").observeSingleEvent(of: .value, with: { snapshot in
            
            print("adding friend to \(UserDefaults().string(forKey:"loginID")!)")
            if let friendsListInDatabase = snapshot.value as? NSArray {
                print("you have friends: ")
                print(friendsListInDatabase)
                if friendsListInDatabase.contains(userToAddFriend){
                    print("you have already had this friend: \(userToAddFriend)")
                }else{
                    print("adding \(userToAddFriend)")
                    let friendCount = friendsListInDatabase.count
                    let friendRef = self.ref.child("Users").child(UserDefaults().string(forKey:"loginID")!).child("friends").child(String(friendCount))
                    friendRef.setValue(userToAddFriend)
                }
            }else{
                let friendRef = self.ref.child("Users").child(UserDefaults().string(forKey:"loginID")!).child("friends").child("0")
                friendRef.setValue(userToAddFriend)
            }
            
        })
    }

    
    func prepare(){
        if let navigationBar = self.navigationController?.navigationBar {
            navigationBar.topItem?.title = "Nearby Users"
            navigationBar.backgroundColor = UIColor.white
        }
        
//        distanceRangeSlider.
    }
// ==========================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ref = FIRDatabase.database().reference()
        // Do any additional setup after loading the view.
        username = UserDefaults().string(forKey: "loginID")!
//        print(username)
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        nearbyUsersTableView.delegate = self
        nearbyUsersTableView.dataSource = self
        
        prepare()
    
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.isHidden = false
        
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
                        print(thisUserInfo.object(forKey: "location")!)
                        let thisUserLocation = thisUserInfo["location"] as! NSDictionary
                        let thisUserLatitude = thisUserLocation["latitude"]
                        let thisUserLongitude = thisUserLocation["longitude"]
                        let otherCoodinate = CLLocation(latitude: thisUserLatitude as! CLLocationDegrees, longitude: thisUserLongitude as! CLLocationDegrees)
                        let myDistance = self.myCoodinate.distance(from: otherCoodinate) as Double
//                        if myDistance < self.distanceRange {
                        if myDistance < Double(self.distanceRangeSlider.value) {
                            self.usersLocations.append( otherCoodinate )
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
                        print("\(user) has no location")
                    }
                }
            }
            self.nearbyUsersTableView.reloadData()
            
        })
//        self.allUsersTableView.reloadData()
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
