//
//  logViewController.swift
//  MMB
//
//  Created by Fei Liang on 10/26/16.
//  Copyright © 2016 Fei Liang. All rights reserved.
//

import UIKit
import FirebaseDatabase

class logViewController: UIViewController {


    var ref = FIRDatabaseReference.init()
    var loginID = ""
    var userInfo: NSDictionary = [:]
    
    var defaultUserInfo = UserDefaults.standard
    
    @IBOutlet weak var userName: UITextField!
    @IBOutlet weak var UserPassword: UITextField!
    
    @IBOutlet weak var chooseSegController: UISegmentedControl!
    @IBOutlet weak var loginButton: UIButton!
    @IBOutlet weak var registerButton: UIButton!
    
    // ----------------------  sign in and sign up ---------------------------------------
    
    @IBAction func chooseLoginOrRegister(_ sender: AnyObject) {
        if chooseSegController.selectedSegmentIndex == 0{
            loginButton.isHidden = false
            registerButton.isHidden = true
        }else{
            loginButton.isHidden = true
            registerButton.isHidden = false
        }
        
        
    }
    
    
    @IBOutlet weak var login_error: UILabel!
    
    @IBAction func loginPressed(_ sender: AnyObject) {
        let username = userName.text?.trimmingCharacters(in: CharacterSet.whitespacesAndNewlines)
        
        
        
        if username != "" && username != "Invalid Name."{
//            print("username is not null " + username! as Any)
            
            

            if UserPassword.text != ""{
                ref.child("Users").observeSingleEvent(of: .value, with: {snapshot in

                    let users = snapshot.value as! NSDictionary
                    if users.object(forKey: username!) != nil{
//                        print("user in database")
                        let correctPassword = (users[username!] as! NSDictionary)["password"]! as! String
//                        print(correctPassword)
//                        print(self.UserPassword.text!)
                        
                        if correctPassword == self.UserPassword.text! {
                            
                            self.userInfo = users[username!] as! NSDictionary
                            self.loginID = username!
                            
                            self.defaultUserInfo.removeObject(forKey: "username")
                            self.defaultUserInfo.removeObject(forKey: "userInfo")
                            self.defaultUserInfo.set(self.userInfo, forKey: "userInfo")
                            self.defaultUserInfo.set(username, forKey: "username")
                            UserDefaults().set(username, forKey: "loginID")
//                            print("UserDefaults of loginID:")
//                            print( UserDefaults().string(forKey: "loginID")! )
                            
                            // look for friends
//                            if users.object(forKey: "")
                            
                            
                            
                            self.performSegue(withIdentifier: "login", sender: self)
                            
                        }else{
//                            print("wrong passowrd")
//                            self.login_error.text="please check your password or username"
                            self.showAlertView(title: "Wrong password", message: "Please check your password")
                        }
                        
                    }else{
                        self.showAlertView(title: "User does not exist", message: "Please check your username")
//                        print("phil not in database")
//                        self.login_error.text="please check your password or username"
                    }
                })
            }
        }else{
//            print("username is null" )
            showAlertView(title: "Invalid username", message: "check your username")
//            login_error.text="please check your password or username"
        }
    }
    
    
    @IBAction func registerPressed(_ sender: AnyObject) {
        print("press register")
        let username = userName.text
        let password = UserPassword.text
        
        let characterset = CharacterSet(charactersIn: "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLKMNOPQRSTUVWXYZ0123456789")
        if username != "" && password != "" || username == "Invalid Name" {
            if password?.rangeOfCharacter(from: characterset.inverted) != nil || username?.rangeOfCharacter(from: characterset.inverted) != nil {
                showAlertView(title: "Invaild character", message: "Please use only numbers and letters")
//                login_error.text="invalid character!!!"
            }else
            if (password?.characters.count)!<6 || (username?.characters.count)!<5{
//                 login_error.text="password or username too short!!!!" 
                showAlertView(title: "You are too short", message: "Too short to register")
                }
            else{
                ref.child("Users").observeSingleEvent(of: .value, with: {snapshot in
                    
                    
                    self.chooseSegController.isEnabled = false
                    let users = snapshot.value as! NSDictionary
                    
                    
                    
                    // check whether the username has existed
                    if users.object(forKey: username!) != nil{
                        //                    print("username has been used")
                        self.chooseSegController.isEnabled = true
                    }else{
                        
                        let newUserRef = self.ref.child( "Users" ).child( username! )
                        
                        let nicknameRef = newUserRef.child("nickname")
                        nicknameRef.setValue(username!)
                        
                        let passwordRef = newUserRef.child("password")
                        passwordRef.setValue(password)
                        
                        let scoresRef = newUserRef.child("scores")
                        let initialScoreRef = scoresRef.child("initial")
                        let scoreRef = initialScoreRef.child("11")
                        scoreRef.setValue("10")
                        
                        let imageRef = newUserRef.child("image")
                        imageRef.setValue("https://firebasestorage.googleapis.com/v0/b/meowmeowb-c4898.appspot.com/o/images%2FAvatar-male.png?alt=media&token=d618d69f-33b5-46b0-a6f7-b9db7e38bebb")
                        
                        let postRef = newUserRef.child("post")
                        postRef.setValue("Hello World! \(username!)")
                        
                        self.chooseSegController.isEnabled = true
                        
                        
                        
                    }
                })
            }
            
            }else{
//                print("fill the username and password to register")
             showAlertView(title: "Invalid username and password", message: "please check your password or username")
//             login_error.text="please check your password or username"
            }
        }

  
    
//==================================================================
    func showAlertView(title: String, message: String){
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let cancelAction = UIAlertAction(title: "Confirm", style: .cancel, handler: nil)
        alert.addAction(cancelAction)
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    func prepareView(){
        loginButton.layer.cornerRadius = 5
        registerButton.layer.cornerRadius = 5
        loginButton.layer.borderWidth = 2
        registerButton.layer.borderWidth = 2
        loginButton.layer.borderColor = UIColor.white.cgColor
        registerButton.layer.borderColor = UIColor.white.cgColor
        registerButton.isHidden = true
        
//        self.navigationController?.setNavigationBarHidden(false, animated: false)
        self.navigationController?.setToolbarHidden(true, animated: false)

    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }
    
//==================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
        prepareView()
        ref = FIRDatabase.database().reference()
        
//        self.defaultUserInfo.removeObject(forKey: "username")
//        self.defaultUserInfo.removeObject(forKey: "userInfo")

        // Do any additional setup after loading the view.
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(logViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        self.navigationController?.navigationBar.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(true)
//        print("---------------------")
        if let defaultID = defaultUserInfo.value(forKey: "username"){
            self.loginID = (defaultID as! NSString) as String
            self.userInfo = defaultUserInfo.value(forKey: "userInfo") as! NSDictionary
//            print(self.loginID)
//            print(self.userInfo)
            self.performSegue(withIdentifier: "login", sender: self)
        }
//        print("---------------------")
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "login" ){
            let tabview = segue.destination as! UITabBarController
            let nav = tabview.viewControllers?[0] as! UINavigationController
            let dest = nav.topViewController as! ViewController
            dest.userInfo = userInfo
            dest.userID = loginID
            
            
        }
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
