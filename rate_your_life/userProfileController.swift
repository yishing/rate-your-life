//
//  userProfileController.swift
//  MMB
//
//  Created by Fei Liang on 11/22/16.
//  Copyright © 2016 Fei Liang. All rights reserved.
//

import UIKit
import FirebaseDatabase
import FirebaseStorage

class userProfileController: UIViewController, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    var ref = FIRDatabaseReference.init()
    var username: String = ""
    var profileImage: UIImage = #imageLiteral(resourceName: "Avatar-male")
    
    var savedPostText = ""
    
    @IBOutlet weak var profileImageView: UIImageView!
    @IBOutlet weak var usernameLabel: UILabel!
    @IBOutlet weak var updatePostButton: UIButton!
    @IBOutlet weak var editPostButton: UIButton!
    @IBOutlet weak var postTextView: UITextView!
    @IBOutlet weak var changePasswordButton: UIButton!
    @IBOutlet weak var cancelPostButton: UIButton!
    
    
    
    
 //button event
//===============================================
    
    @IBAction func logoutPressed(_ sender: Any) {
        
        self.performSegue(withIdentifier: "logout", sender: self)
    }
    
    
    @IBAction func pressImageGesture(_ sender: Any) {
        print( "image tap pressed" )
        let picker =  UIImagePickerController()
        picker.delegate = self
        picker.allowsEditing = true
    
        present(picker, animated: true, completion: nil)
    }
    
    @IBAction func editPostPressed(_ sender: Any) {
        updatePostButton.isHidden = false
        cancelPostButton.isHidden = false
        editPostButton.isHidden = true
        
        postTextView.isSelectable = true
        postTextView.isEditable = true
        
        savedPostText = postTextView.text
        postTextView.becomeFirstResponder()
        postTextView.selectAll(nil)
        
    }
    
    @IBAction func updatePostPressed(_ sender: Any) {
        editPostButton.isHidden = false
        updatePostButton.isHidden = true
        cancelPostButton.isHidden = true
        
        postTextView.isSelectable = false
        postTextView.isEditable = false
        
        if (postTextView.text == "") {
            postTextView.text = "This guy is too cool to leave any post !"
        }
        
        ref.child("Users").child(username).child("post").setValue(postTextView.text)
    }
    
    
    @IBAction func cancelPostPressed(_ sender: Any) {
        editPostButton.isHidden = false
        updatePostButton.isHidden = true
        cancelPostButton.isHidden = true
        
        postTextView.isSelectable = false
        postTextView.isEditable = false
        
        postTextView.text = savedPostText
    }
    
    @IBAction func changePasswordPressed(_ sender: Any) {
        ref.child("Users").child(username).child("password").observeSingleEvent(of: .value, with: {snapshot in
            let old_password = snapshot.value as! String
//            print(old_password)
            
            self.changePassword(old_password: old_password)
            
        })
    }
    
    func changePassword(old_password: String){
        let changePasswordAlert = UIAlertController(title: "Change Password", message: "Please put in your new password", preferredStyle: .alert)
        
        changePasswordAlert.addTextField(configurationHandler: { (textField : UITextField!) -> Void in
            textField.placeholder = "your old password"
            textField.isSecureTextEntry = true
            textField.text = ""
        })
        
        changePasswordAlert.addTextField(configurationHandler: { (textField : UITextField!) -> Void in
            textField.placeholder = "your new password"
            textField.isSecureTextEntry = true
            textField.text = ""
        })
        
        changePasswordAlert.addTextField(configurationHandler: { (textField : UITextField!) -> Void in
            textField.placeholder = "confirm your new password"
            textField.isSecureTextEntry = true
            textField.text = ""
        })
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        
        let comfirmAction = UIAlertAction(title: "Confirm", style: .default, handler: { alert -> Void in
            let oldTextField = changePasswordAlert.textFields![0] as UITextField
            let newTextField = changePasswordAlert.textFields![1] as UITextField
            let newConfirmTextField = changePasswordAlert.textFields![2] as UITextField
            if ( old_password == oldTextField.text! ) &&  (newTextField.text == newConfirmTextField.text ) && ((newConfirmTextField.text?.characters.count)! > 5){
                self.ref.child("Users").child(self.username).child("password").setValue(newTextField.text)
            }else{
                oldTextField.text = ""
                newTextField.text = ""
                newConfirmTextField.text = ""
                changePasswordAlert.message = "Invalid update"
                self.present(changePasswordAlert, animated: true, completion: nil)
            }
            
        })
        
        changePasswordAlert.addAction(comfirmAction)
        changePasswordAlert.addAction(cancelAction)
        
        
        self.present(changePasswordAlert, animated: true, completion: nil)
    }
    
    
    
//===============================================
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [String : Any]) {
        
        var selectedImageFromPicker: UIImage?
        
        if let editedImage = info["UIImagePickerControllerEditedImage"] as? UIImage {
            selectedImageFromPicker = editedImage
        }else if let originalImage = info[ "UIImagePickerControllerOriginalImage" ] as? UIImage {
            selectedImageFromPicker = originalImage
        }
        
        if let selectedImage = selectedImageFromPicker {
            profileImageView.image = selectedImage
        
            let storageRef = FIRStorage.storage().reference().child("images").child(username).child("profileImage.png")
            if let uploadData = UIImagePNGRepresentation(selectedImage) {
                storageRef.put( uploadData, metadata: nil, completion: {
                    (metadata, error) in
                    if error != nil {
                        print(error!)
                        return
                    }
                    print(metadata! )
                    let userImageRef = self.ref.child( "Users" ).child( self.username ).child("image")
                    if let profileImageURL = metadata?.downloadURL()?.absoluteString{
                        userImageRef.setValue(profileImageURL)
                    }
                })
            }
            
        }
        
        
        dismiss( animated: true, completion: nil )
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        print( "picker cancelled" )
        dismiss( animated: true, completion: nil )
    }
    
    
    func prepareView() {
        print("profile for: ")
        print(UserDefaults().string(forKey: "loginID")!)
        usernameLabel.text = username
        profileImageView.image = profileImage
        
        // prepare post view
        updatePostButton.isHidden = true
        cancelPostButton.isHidden = true
        postTextView.isEditable = false
        postTextView.isSelectable = false
        
        updatePostButton.layer.borderWidth = 1
        cancelPostButton.layer.borderWidth = 1
        editPostButton.layer.borderWidth = 1
        
        updatePostButton.layer.borderColor = UIColor.black.cgColor
        cancelPostButton.layer.borderColor = UIColor.black.cgColor
        editPostButton.layer.borderColor = UIColor.black.cgColor
        
        updatePostButton.layer.cornerRadius = 5
        cancelPostButton.layer.cornerRadius = 5
        editPostButton.layer.cornerRadius = 5
        
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "logout" ){
            let nav = segue.destination as! logViewController
            nav.defaultUserInfo.removeObject(forKey: "username")
            nav.defaultUserInfo.removeObject(forKey: "userInfo")
        }
    }

// =================================================================
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        ref = FIRDatabase.database().reference()
        prepareView()
        
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(logViewController.dismissKeyboard))
        view.addGestureRecognizer(tap)
        

    }
    
    func dismissKeyboard() {
        //Causes the view (or one of its embedded text fields) to resign the first responder status.
        view.endEditing(true)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = true
        self.navigationController?.navigationBar.isHidden = false
        
        ref.child("Users").child(username).observeSingleEvent(of: .value, with: { snapshot in
            let userProfileInfo = snapshot.value as! NSDictionary
            self.postTextView.text = userProfileInfo["post"] as! String
        })
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
