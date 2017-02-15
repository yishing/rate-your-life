//
//  historyViewController.swift
//  MMB
//
//  Created by Fei Liang on 12/2/16.
//  Copyright © 2016 Fei Liang. All rights reserved.
//

import UIKit
import FirebaseDatabase

class historyViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    
    var historyArray: [String] = []
    var ref = FIRDatabaseReference.init()
    var historyHandle = FIRDatabaseHandle.init()
    var scoreColorDic = ["1":UIColor.red, "2":UIColor.yellow, "3":UIColor.green, "4":UIColor.blue, "5":UIColor.black]
    var selectedUserName = ""
    
    @IBOutlet weak var historyTableView: UITableView!
    
//=============================================================================
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return historyArray.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let historyCell = tableView.dequeueReusableCell(withIdentifier: "historycell", for: indexPath) as! historyTableViewCell
        print(historyArray[indexPath.row])
        let record = historyArray[indexPath.row]
        let recordArray = record.components(separatedBy: ";")
        let score = recordArray[0]
        let date = recordArray[1]
        let name = recordArray[2]
        
        historyCell.historyRecordLabel.text = name
        historyCell.historyTimeLabel.text = date
        historyCell.historyScoreLabel.text = score
        
        historyCell.historyScoreLabel.textColor = UIColor.white
        historyCell.historyScoreLabel.backgroundColor = scoreColorDic[score]
        historyCell.historyScoreLabel.layer.cornerRadius = historyCell.historyScoreLabel.frame.width/2
        historyCell.historyScoreLabel.layer.borderColor = scoreColorDic[score]?.cgColor
        historyCell.historyScoreLabel.layer.borderWidth = 1
        historyCell.historyScoreLabel.layer.masksToBounds = true
        
//        historyCell.historyRecordLabel.isHidden = true
//        historyCell.textLabel?.text = historyArray[indexPath.row]
        return historyCell
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableViewAutomaticDimension
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        //        print(userslist[indexPath.row])
        let record = historyArray[indexPath.row]
        let recordArray = record.components(separatedBy: ";")
        let name = recordArray[2]
        selectedUserName = name
        
        self.performSegue(withIdentifier: "otheruser", sender: self)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if( segue.identifier == "otheruser" ){
            
            let nav = segue.destination as! otherUserViewController
            nav.username = selectedUserName
        }
    }
    
   
//=============================================================================
    override func viewDidLoad() {
        super.viewDidLoad()
        
//        NotificationCenter.default.addObserver(self, selector:"doYourStuff", name:
//            NSNotification.Name.UIApplicationWillEnterForeground, object: nil)
        
        ref = FIRDatabase.database().reference()
        // Do any additional setup after loading the view.
        historyTableView.delegate = self
        historyTableView.dataSource = self
        historyTableView.rowHeight = UITableViewAutomaticDimension
        
        if let navigationBar = self.navigationController?.navigationBar {
            navigationBar.topItem?.title = "History"
            navigationBar.backgroundColor = UIColor.white
        }
        
        historyHandle = ref.child("Users").child(UserDefaults().string(forKey: "loginID")!).child("history").observe(.value, with: {snapshot in
            if let histories = snapshot.value as? NSArray {
                self.historyArray = histories.copy() as! [String]
            }else{
                
            }
            print("The history is: ")
            
            print(self.historyArray)
            self.historyTableView.reloadData()
            self.tabBarController?.tabBar.items?.last?.badgeValue = "new"
        })

    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.tabBarController?.tabBar.isHidden = false
        self.navigationController?.navigationBar.isHidden = false
        self.tabBarController?.tabBar.items?.last?.badgeValue = nil
//        historyHandle = ref.child("Users").child(UserDefaults().string(forKey: "loginID")!).child("history").observe(.value, with: {snapshot in
//            if let histories = snapshot.value as? NSArray {
//                self.historyArray = histories.copy() as! [String]
//            }else{
//                
//            }
//            print("The history is: ")
//            print(self.historyArray)
//           self.historyTableView.reloadData()
//        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        ref.removeObserver(withHandle: historyHandle)
        self.tabBarController?.tabBar.items?.last?.badgeValue = nil

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
