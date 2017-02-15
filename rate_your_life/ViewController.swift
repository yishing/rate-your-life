//
//  ViewController.swift
//  MMB
//
//  Created by Fei Liang on 10/26/16.
//  Copyright © 2016 Fei Liang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage

class ViewController: UIViewController {
    
    var userID = ""
    var userInfo: NSDictionary = [:]
    var scoresDic: NSDictionary = [:]
    var score = Float(0)
    
    var profileImage: UIImage = #imageLiteral(resourceName: "Avatar-male")

    var ref = FIRDatabaseReference.init()
    
    
    @IBOutlet weak var userIDLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!
    @IBOutlet weak var scoreLabel: UILabel!
    
    
    @IBAction func labelLongPressedGesture(_ sender: Any) {
        if ( (sender as AnyObject).state == UIGestureRecognizerState.began ) {
            print( "userLabel long pressed" )
            self.performSegue(withIdentifier: "editProfile", sender: self)
        }
    }
    
    @IBAction func scoreLongPressed(_ sender: Any) {
        if ( (sender as AnyObject).state == UIGestureRecognizerState.began ) {
            print( "score long pressed" )
            self.performSegue(withIdentifier: "showhistory", sender: self)
        }
    }
    
    
    func computeScore(scoresDic: NSDictionary) -> Float {
        var totalScore = Float(0)
        var totalWeight = Float(0)
        var finalScore = Float(0)
        for (_, scores) in scoresDic{
            for (score, weight) in (scores as! NSDictionary) {
                
                let s = Int(((score as! NSString) as String))! % 10
                
                let ws = ((weight as! NSString) as String).replacingOccurrences(of: "\"", with: "")
                let w = Float(ws)
                totalScore += w! * Float(s)
                totalWeight += w!
//                print("score is\(s) and weight is\(w)")
//                print("totalscore is \(totalScore), totalweight is \(totalWeight)")
            }
        }
        finalScore = Float(totalScore)/Float(totalWeight)
        return finalScore
    }
    
    
    func loadImage(imageAddress: String) {
        let storage = FIRStorage.storage()
        let gsRef = storage.reference(forURL: imageAddress)
        gsRef.data(withMaxSize: 1 * 1024 * 1024) { (data, error) -> Void in
            if (error != nil) {
                // Uh-oh, an error occurred!
                print("error to download the image")
            } else {
                let image = UIImage( data: data! )
                self.imageView.image = image
                self.profileImage = image!
            }
        }
        
    }
    
    
    
    
    
    
    func prepareView() {
        imageView.layer.cornerRadius = imageView.frame.width/2
        imageView.layer.borderWidth = 3
        imageView.layer.borderColor = UIColor.black.cgColor
        imageView.clipsToBounds = true
        
//        scoreLabel.layer.cornerRadius = 75
//        scoreLabel.layer.borderWidth = 3
//        scoreLabel.layer.borderColor = UIColor.black.cgColor
        if let navigationBar = self.navigationController?.navigationBar {
            navigationBar.topItem?.title = "Homepage"
            navigationBar.backgroundColor = UIColor.clear
            navigationBar.alpha = 0.5
        }
        
    }
    
    
//==========================================================================================
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        prepareView()
       
        ref = FIRDatabase.database().reference()

        userIDLabel.text = userID
       
        scoresDic = userInfo["scores"] as! NSDictionary
        
        score = computeScore(scoresDic: scoresDic)
        scoreLabel.text = NSString(format:"%.2f", score) as String
        
        
        ref.child("Users").child(userID).child("scores").observe(.value, with: { snapshot in
            
            self.scoresDic = snapshot.value as! NSDictionary
            self.score = self.computeScore(scoresDic: self.scoresDic)
            
            UIView.animate(withDuration: 1, animations: {
                self.scoreLabel.alpha = 0
            })
            
            self.scoreLabel.text = NSString(format:"%.2f", self.score) as String
            
            UIView.animate(withDuration: 1, animations: {
                self.scoreLabel.alpha = 1
            })
            
            UserDefaults().set(NSString(format:"%.2f", self.score) as String, forKey: "score")
        })
        
        ref.child("Users").child(userID).child("image").observe(.value, with: { snapshot in
            
            print( "listen for image -------" )
            if snapshot.value is NSNull {
                self.imageView.image = #imageLiteral(resourceName: "Avatar-male")
            }else{
                let imageAddress = snapshot.value as! NSString as String
                self.loadImage(imageAddress:  imageAddress )
            }
        
        
        })
        

    }

    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.isHidden = true
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }

    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "logout" ){
            let nav = segue.destination as! logViewController
            nav.defaultUserInfo.removeObject(forKey: "username")
            nav.defaultUserInfo.removeObject(forKey: "userInfo")
        }
        
        if ( segue.identifier == "editProfile" ){
            let nav = segue.destination as! userProfileController
            nav.profileImage = profileImage
            nav.username = userID
        }
    }
        
    

}

