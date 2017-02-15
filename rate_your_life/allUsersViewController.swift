//
//  allUsersViewController.swift
//  
//
//  Created by Fei Liang on 11/14/16.
//
//

import UIKit
import FirebaseDatabase
import FirebaseStorage

class allUsersViewController: UIViewController,UITableViewDelegate, UITableViewDataSource {
   
    var ref = FIRDatabaseReference.init()
    var users: NSDictionary = [:]
    var userslist: [String] = []
    var userScorelist: [String: Float] = [:]
    var userID = ""
    var selectedUserName = ""
    var alluserHandle = FIRDatabaseHandle.init()
    var userFriends: [String] = []

    
    
    @IBOutlet weak var allUsersTableView: UITableView!

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return userslist.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        print("in cellForRow at \(indexPath)")
        

        let userCell = tableView.dequeueReusableCell(withIdentifier: "alluserscell", for: indexPath) as! allUsersCellController

//        userCell.cellUserName.text = myArray[indexPath.row] as? String
        userCell.cellUserName.text = userslist[indexPath.row]
        userCell.cellUserScore.text = NSString(format:"%.2f", userScorelist[userslist[indexPath.row]]!) as String
        
        userCell.cellUserScore.layer.cornerRadius = 20
        userCell.cellUserScore.layer.borderWidth = 1
        userCell.cellUserScore.layer.borderColor = UIColor.black.cgColor
        
        userCell.cellImage.image = #imageLiteral(resourceName: "Avatar-male")
        userCell.cellImage.layer.cornerRadius = userCell.cellImage.layer.frame.width/2
        userCell.cellImage.layer.borderWidth = 1
        userCell.cellImage.layer.borderColor = UIColor.black.cgColor
        userCell.cellImage.clipsToBounds = true
        
        
        return userCell
        
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        print(userslist[indexPath.row])
        
        selectedUserName = userslist[ indexPath.row ]
        
        self.performSegue(withIdentifier: "otheruser", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "otheruser" ){

            let nav = segue.destination as! otherUserViewController
            nav.username = selectedUserName
        }
    }
    
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
    
    
//==================================================================
    func computeScore(scoresDic: NSDictionary) -> Float {
        var totalScore = Float(0)
        var totalWeight = Float(0)
        var finalScore = Float(0)
//        print(scoresDic)
        for (_, scores) in scoresDic{
            
            let myMirror = Mirror(reflecting: scores)
            if  (String(describing: myMirror.subjectType) == "Array<AnyObject>") {
//                print ("<<<<<<<<<<")
            }
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
    
    

//==================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
    
        allUsersTableView.dataSource = self
        allUsersTableView.delegate = self
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
//        self.userScorelist[UserDefaults().string(forKey: "loginID")!] = nil
//        print(self.userScorelist)
//        self.allUsersTableView.reloadData()
        
        if let navigationBar = self.navigationController?.navigationBar {
            navigationBar.topItem?.title = "All Users"
            navigationBar.backgroundColor = UIColor.white
        }
        
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.isHidden = false
        
        alluserHandle = ref.child("Users").observe(.value, with: { snapshot in
            self.userslist = []
            self.userScorelist = [:]
            self.users = snapshot.value as! NSDictionary
            
            for (user, userInfo) in self.users {
                if (user as! String) != UserDefaults().string(forKey: "loginID"){
                    self.userslist.append(user as! String)
                    if let scoreDic = (userInfo as! NSDictionary)["scores"]! as? NSDictionary{
                        let score = self.computeScore(scoresDic: scoreDic)
                        self.userScorelist[user as! String] = score
                    }else{
                    }

                }

            }
            
            self.allUsersTableView.reloadData()
            
        })
        self.allUsersTableView.reloadData()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        ref.removeObserver(withHandle: alluserHandle)
        print("all users' observe remove")
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
