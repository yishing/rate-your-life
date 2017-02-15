//
//  friendsViewController.swift
//  MMB
//
//  Created by Fei Liang on 11/30/16.
//  Copyright © 2016 Fei Liang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage

class friendsViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var ref = FIRDatabaseReference.init()
    var friendsHandle = FIRDatabaseHandle.init()
    var friendsArray: [String] = []
    
    var friendScoreDic: [String: Float] = [:]
    var friendImageAddressDic: [String: String] = [:]
    var friendPostDic: [String: String] = [:]
    
    var selectedUserName = ""
    var selectedUserPost = ""
    
    @IBOutlet weak var friendsTableView: UITableView!
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return friendsArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let friendCell = tableView.dequeueReusableCell(withIdentifier: "friendCell", for: indexPath) as! friendTableViewCell
        if friendsArray.isEmpty{
            
        }else{
            // set image
            let storage = FIRStorage.storage()
            print(friendImageAddressDic)
            if let imageAddress = friendImageAddressDic[ friendsArray[indexPath.row] ]{
                let gsRef = storage.reference(forURL: imageAddress)
                gsRef.data(withMaxSize: 1 * 1024 * 1024) { (data, error) -> Void in
                    if (error != nil) {
                        // Uh-oh, an error occurred!
                        print("error to download the image")
                    } else {
                        friendCell.userImage.image = UIImage( data: data! )!
                    }
                }
                friendCell.userImage.layer.cornerRadius = friendCell.userImage.frame.size.height/2
                friendCell.userImage.layer.borderWidth = 1
                friendCell.userImage.layer.borderColor = UIColor.black.cgColor
                friendCell.userImage.clipsToBounds = true
            }
            //set name
            friendCell.userNameLabel.text = friendsArray[indexPath.row]
            
            //set score
            friendCell.userScoreLabel.text = NSString(format:"%.2f", friendScoreDic[friendsArray[indexPath.row]]!) as String
            friendCell.userScoreLabel.layer.cornerRadius = friendCell.userScoreLabel.layer.frame.width/2
            friendCell.userScoreLabel.layer.borderWidth = 1
            friendCell.userScoreLabel.layer.borderColor = UIColor.black.cgColor
            
            //set post
            friendCell.userDescriptionLabel.text = friendPostDic[ friendsArray[indexPath.row] ]
        }
        return friendCell
    }
    
    // select to perform segue
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //        print(userslist[indexPath.row])
        
        selectedUserName = friendsArray[ indexPath.row ]
        selectedUserPost = friendPostDic[ selectedUserName ]!
        self.performSegue(withIdentifier: "friendToOther", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "friendToOther" ){
            
            let nav = segue.destination as! friendOtherUserViewController
            nav.username = selectedUserName
            nav.post = selectedUserPost
        }
    }
    
    //swipe to delete
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        var friendToRemove = ""
        let removefirend = UITableViewRowAction(style: .default, title: "Remove friend"){
            
            action, indexPath in
            friendToRemove = self.friendsArray[ indexPath.row ]
            
            // add selected user to friend
            self.removeFriend(friendToRemove: friendToRemove, indexPath: indexPath)
            
        }
        return [removefirend]
    }
    
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool {
        return true
    }

//==========================================================================================
    func removeFriend( friendToRemove: String, indexPath: IndexPath ){
        print("friend to remove \(friendToRemove)")
        let friendRef = ref.child("Users").child(UserDefaults().string(forKey: "loginID")!).child("friends")
        var friendDic: [String: String] = [:]
        friendsArray.remove(at: indexPath.row)
        for (index, name) in friendsArray.enumerated(){
            friendDic[String(index)] = name
        }
        print(friendDic)
        friendRef.setValue(friendDic)
        self.friendsTableView.reloadData()
    }
    
    
    func computeScore(scoresDic: NSDictionary) -> Float {
        var totalScore = Float(0)
        var totalWeight = Float(0)
        var finalScore = Float(0)
        //        print(scoresDic)
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


//==========================================================================================
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        friendsTableView.delegate = self
        friendsTableView.dataSource = self
        
        //deal with the navigation bar
        
        
        ref = FIRDatabase.database().reference()

    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        if let navigationBar = self.navigationController?.navigationBar {
            navigationBar.topItem?.title = "Friends"
            navigationBar.backgroundColor = UIColor.white
        }
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.isHidden = false
        
        ref.child("Users").child(UserDefaults().string(forKey: "loginID")!).child("friends").observeSingleEvent(of: .value, with: { snapshot in
            if let friendsListInDatabase = snapshot.value as? NSArray {
               self.friendsArray = friendsListInDatabase.copy() as! [String]
                
                self.ref.child("Users").observeSingleEvent(of: .value, with: { snapshot in
                    let users = snapshot.value as! NSDictionary
                    for (user, userInfo) in users {
                        if self.friendsArray.contains(user as! String){
                            if let scoreDic = (userInfo as! NSDictionary)["scores"]! as? NSDictionary{
                                let score = self.computeScore(scoresDic: scoreDic)
                                self.friendScoreDic[user as! String] = score
                            }
                            self.friendImageAddressDic[user as! String] = (userInfo as! NSDictionary)["image"]! as? String
                            self.friendPostDic[user as! String] = (userInfo as! NSDictionary)["post"]! as? String
                        }
                    }
                    print(self.friendsArray)
                    print(self.friendScoreDic)
                    print(self.friendImageAddressDic)
                    self.friendsTableView.reloadData()
                })
            }else{
                print("you have no friends")
            }
            
        })
        
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
