//
//  IntroTableViewController.swift
//  butterfly2
//
//  Created by Alan Jaw on 9/13/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import UIKit
import FirebaseStorage
import AVFoundation
import AVKit
import FirebaseDatabase
import FirebaseAuth

fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


class IntroTableViewController: UITableViewController {
    
    let avPlayerViewController = AVPlayerViewController()
    var avPlayer:AVPlayer? = nil
    var queuePlayer = AVQueuePlayer()
    
    var overlayView = UIView()
    
    var lastVideoIndex: Int = 0
    var currentVideoIndex: Int = 0
    
    var meetMedia = [MeetMedia]()
    var blockedUserList:[String] = []
    
    var selectedUserAtIndexPath: Int?
    
    var currentlyPlayingVideo: Bool = false // setting this bool avoids an exception with presenting video player modally over each other on multiple user taps.
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Uncomment the following line to preserve selection between presentations
        // self.clearsSelectionOnViewWillAppear = false

        // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
        // self.navigationItem.rightBarButtonItem = self.editButtonItem()
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
        self.tableView.separatorColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 0.3)

        self.refreshControl?.addTarget(self, action: #selector(IntroTableViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        getMeetMedia({
            meetMedia in
            self.meetMedia = meetMedia
            self.tableView.reloadData()
        })
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(true)
        currentlyPlayingVideo = false
    }

    // MARK: - Table view data source

    override func numberOfSections (in tableView: UITableView) -> Int {
        if meetMedia.count > 0  {
            return meetMedia.count
        }
        else {
            return 0
        }
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "videoIntroCell", for: indexPath)
        
        let unread = meetMedia[(indexPath as NSIndexPath).section].unread
        
        // custom red: 200, 21, 137
        // 200 149 186
        if (unread) {
//            cell.textLabel?.textColor = UIColor(red: 200/255, green: 21/255, blue: 137/255, alpha: 1)
            
            cell.textLabel?.textColor = UIColor.red
        }
        else {
//            cell.textLabel?.textColor = UIColor(red: 200/255, green: 149/255, blue: 186/255, alpha: 1)
            cell.textLabel?.textColor = UIColor.red

        }

        cell.textLabel?.font = UIFont(name: "Helvetica", size: 20.0)
        cell.textLabel?.text = meetMedia[(indexPath as NSIndexPath).section].title
        
        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedCell = tableView.cellForRow(at: indexPath)
        
        selectedUserAtIndexPath = (indexPath as NSIndexPath).section
        // download and show video
        playVideoAtCell((indexPath as NSIndexPath).section)
        currentlyPlayingVideo = true // don't present avPlayer in playVideoAtCell if user has already tapped

    }
    
    func playVideoAtCell(_ cellNumber: Int) {
        if (currentlyPlayingVideo) {return}

        let mediaID = meetMedia[cellNumber].mediaID

        updateMeetMediaReadFor(mediaID)
            
        getDownloadURL(cellNumber, mediaID: mediaID) { (url) in
                
            self.avPlayer = AVPlayer(url: url)
            self.avPlayerViewController.player = self.avPlayer
            self.avPlayerViewController.showsPlaybackControls = false
                
            NotificationCenter.default.addObserver(self, selector: #selector(self.videoItemFinished(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.avPlayer?.currentItem)
                
            self.present(self.avPlayerViewController, animated: true) { () -> Void in
                    self.avPlayerViewController.player?.play()
                    
            }
        }
    }
    
    func getDownloadURL (_ cellNumber: Int, mediaID: String, callback: @escaping (URL) -> ()) {
        
        
        Constants.storageMediaRef.child("\(mediaID)").downloadURL(completion: { (URL, error) in
            
            if error != nil {
                self.showVideoErrorAlert()
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }
            }

            else {
                if let downloadURL = URL {
                    callback (downloadURL)
                }
            }
            
        })
        
    }

    func videoItemFinished (_ notification: Notification) {
        addContentOverlayView()
    }

    func addContentOverlayView() {
        
        overlayView.frame = CGRect(x: 0,y: 0,width: avPlayerViewController.view.bounds.width, height: avPlayerViewController.view.bounds.height)
        overlayView.isHidden = false
        overlayView.backgroundColor = UIColor.clear
        
        let passButton = UIButton(frame:CGRect(x: 40,y: avPlayerViewController.view.bounds.height - 150,width: 60,height: 60))
        passButton.setTitle("Pass", for:UIControlState())
        passButton.addTarget(self, action:#selector(dismissVideo), for:.touchUpInside)
        //        btnNext.layer.borderColor = UIColor ( red: 0.0, green: 0.0, blue: 1.0, alpha: 0.670476140202703 ).CGColor
        //        btnNext.layer.borderWidth = 1.0
        passButton.setImage(UIImage(named: "Meet_Cancel_75"), for: UIControlState.normal)
        overlayView.addSubview(passButton)
        
        let bottomMiddleRect = CGRect(x: (avPlayerViewController.view.bounds.width/2) - 30, y:avPlayerViewController.view.bounds.height - 70, width: 70, height: 70)
        let reportButton = UIButton(frame:bottomMiddleRect)
        reportButton.setTitle("", for: UIControlState())
        reportButton.setImage(UIImage(named: "meet_Flag_2_25"), for: .normal)
        reportButton.addTarget(self, action:#selector(showReportAction), for: .touchUpInside)
        overlayView.addSubview(reportButton)
        
        
        let replayButton = UIButton(frame:CGRect(x: 0,y: 10,width: avPlayerViewController.view.bounds.width, height: avPlayerViewController.view.bounds.height - 190))
        replayButton.setTitle("", for:UIControlState())
        replayButton.addTarget(self, action:#selector(replayVideo), for:.touchUpInside)
        overlayView.addSubview(replayButton)
        
        let meetButton = UIButton(frame:CGRect(x: avPlayerViewController.view.bounds.width - 100,y:avPlayerViewController.view.bounds.height - 150,width: 60,height: 60))
        meetButton.setTitle("Meet", for:UIControlState())
        meetButton.addTarget(self, action:#selector(meetPerson), for:.touchUpInside)
        meetButton.setImage(UIImage(named: "Meet_Ok_75"), for: UIControlState.normal)
        overlayView.addSubview(meetButton)
        
        avPlayerViewController.view.addSubview(overlayView);
        
    }

    func dismissVideo() {
        currentlyPlayingVideo = false
        overlayView.isHidden = true
        dismiss(animated: true, completion: nil)
    }

    func replayVideo() {
        overlayView.isHidden = true
        avPlayerViewController.player?.currentItem?.seek(to: kCMTimeZero)
        avPlayerViewController.player?.play()
    }

    func meetPerson() {
        
        let currentUserID = Constants.userID
        let fromUserID = userIDFromMatch(selectedUserAtIndexPath!)
        
        checkIfMatched(currentUserID: Constants.userID, withUserID: fromUserID) {
            exists in
            if exists {
                print ("Matched: \(exists)")
                self.showErrorMatchAlert(reason: "Already Matched")
            }
            else {
                if let newMatchDic = self.setupNewMatchToSave(fromUserID, userID: currentUserID) {
                    setupNewChatWith(fromUserID)
                    self.showMeetPersonAlert()
                }
                else {
                    self.showErrorMatchAlert(reason: nil)
                }
            }
        }
    }

    
    func showReportAction() {

        let alertController = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        let reportAction = UIAlertAction(title: "Report this User",
                                       style: .default) { [unowned self](action: UIAlertAction) -> Void in

                                        self.reportUser()
        }
    
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
        }
        alertController.addAction(reportAction)
        alertController.addAction(cancelAction)
        topMostController().present(alertController, animated: true, completion: nil)

    }
    
    func reportUser() {
        
        let reportUserVC:ReportUserViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ReportUser") as! ReportUserViewController
        
        reportUserVC.userIDToReport = userIDFromMatch(selectedUserAtIndexPath!)

        topMostController().present(reportUserVC, animated: false, completion: nil)

    }
    
    func showMeetPersonAlert() {
        
        let alertController = UIAlertController(title: "You've Matched! Say Hello?", message: nil, preferredStyle: .alert)
        
        let chatAction = UIAlertAction(title: "Chat Now",
                                       style: .default) { [unowned self](action: UIAlertAction) -> Void in
            // transition to chat tab , opening up new conversation with matched user
//            
//                                        for controller in (self.tabBarController?.viewControllers)! {
//                                            if controller.isKindOfClass(MatchesTableViewController) {
//                                                self.tabBarController?.selectedViewController = controller
//                                            }
//                                        }
                                        self.tabBarController?.selectedIndex = 3
                                        self.dismissVideo()
        }
        let laterAction = UIAlertAction(title: "Later", style: .cancel) { (action) -> Void in
            self.dismissVideo()
        }
        alertController.addAction(chatAction)
        alertController.addAction(laterAction)
        topMostController().present(alertController, animated: true, completion: nil)
    }

    func setupNewMatchToSave(_ fromUserID: String?, userID: String?)-> Dictionary<String, AnyObject>? {

        if (fromUserID != nil && userID != nil) && (fromUserID != userID) {
            var matchDic: Dictionary<String, AnyObject>?
            /*
             matches table: {
             { userID1 }
             { userID2 }
             { timestamp}
             */
            
            matchDic = [
                "timestamp": Constants.firebaseServerValueTimestamp as AnyObject,
                "userID1": userID! as AnyObject,
                "userID2": fromUserID! as AnyObject
            ]
            
            return matchDic
        }
        return nil

    }
    
    func userIDFromMatch(_ selectedUserAtIndexPath: Int) -> String {
        let fromUserID = meetMedia[selectedUserAtIndexPath].fromUserID
        
        return fromUserID
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        
        getMeetMedia({
            meetMedia in
            self.meetMedia = meetMedia
            self.tableView.reloadData()
        })
        refreshControl.endRefreshing()
    }
    
    func configureTabBar() {
        guard let tabBarItem = self.tabBarItem else { return }
        
        tabBarItem.badgeValue = "\(meetMedia.count)"
    }
    
    
    func showErrorMatchAlert(reason: String?) {
        var title = "Error Matching"
        var message = "We ran into an error matching you two. Sorry!"
        if reason == "Already Matched" {
            message = "You're already matched! Go say Hi"
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel) { (action) in
            self.dismissVideo()
        }
        alertController.addAction(okAction)
        topMostController().present(alertController, animated: true, completion: nil)
        
        
    }

    func showVideoErrorAlert() {
        let title = "Error"
        var message = "We ran into an error showing this video"
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Aww, OK...", style: .cancel) { (action) in
            self.currentlyPlayingVideo = false
        }
        alertController.addAction(okAction)
        topMostController().present(alertController, animated: true, completion: nil)
        
    }
}
