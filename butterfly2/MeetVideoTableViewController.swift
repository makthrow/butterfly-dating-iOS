//
//  MeetVideoTableViewController.swift
//  butterfly2
//
//  Created by Alan Jaw on 8/1/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//

import UIKit
import FirebaseStorage
import AVFoundation
import AVKit
import FirebaseDatabase
import FirebaseAuth

class MeetVideoTableViewController: UITableViewController {

    let avPlayerViewController = AVPlayerViewController()
    var avPlayer:AVPlayer? = nil
    var queuePlayer = AVQueuePlayer()
    
    var overlayView = UIView()
    
    var mediaIntroQueueList = [[String: Any]]()
    
    var selectedUserAtIndexPath: Int?
    
    var currentlyPlayingVideo: Bool = false // setting this bool avoids an exception with presenting video player modally over each other on multiple user taps.
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.tableView.contentInset = UIEdgeInsetsMake(20, 0, 0, 0);
        self.refreshControl?.addTarget(self, action: #selector(MeetVideoTableViewController.handleRefresh(refreshControl:)), for: UIControlEvents.valueChanged)
        self.tableView.separatorColor = UIColor(red: 170/255, green: 170/255, blue: 170/255, alpha: 0.3)

    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(true)
        
        getUserFacebookInfoFor(userID: (Constants.userID), callback:  {
            dic in
            if dic != nil {
                let birthday = dic!["birthday"] as? String
                let name = dic!["name"] as? String
                let pictureURL = dic!["pictureURL"] as? String
                let gender = dic!["gender"] as? String
            }

        })

        getUserLocation()
        
        // check if show gender/age settings have been updated
        let defaults = UserDefaults.standard
        let needsUpdate = defaults.bool(forKey: "needToUpdateMatches")
        
        if needsUpdate == true {
            mediaIntroQueueList.removeAll()
            self.tableView.reloadData()
            defaults.set(false, forKey: "needToUpdateMatches")
        }
        
        if !getUserAdminStatusFromDefaults() {
            getLocalIntroductions()
        }
        else {
            getIntroductionsForAdmin()
        }
        getLocalIntroductions()
        avPlayerViewController.showsPlaybackControls = false
    }
    
    func getLocalIntroductions() {
        
        // DOWNLOAD LIST OF VIDEOS and TITLES, based on location
        // filters: 20 mi radius, timestamp within 24 hours, gender
        // gets list of videoIDs from media_location --- filtered by 50km radius
        var mediaLocationKeysWithinRadius = [String]()
        
        if let center = currentLocation {
            let circleQuery = Constants.geoFireMedia?.query(at: center, withRadius: 50) // in km

            circleQuery?.observe(GFEventType.keyEntered, with: { (key: String?, location: CLLocation?) in
                mediaLocationKeysWithinRadius.append(key!)
            })
        }
        
        // Nov 29 added filter for blocked IDs
        var blockList = [String]()
        getBlockList({
            list in
            blockList = list
        })
        
        // timeIntervalSince1970 takes seconds, while the timestamp from firebase is in milliseconds
        let currentTimeInMilliseconds = Date().timeIntervalSince1970 * 1000
        // filter list by the dates that are within 24 hours (86400000 milliseconds = 24 hours)
        let twentyFourHoursInMilliseconds:Double = 86400000
        let startTime = currentTimeInMilliseconds - twentyFourHoursInMilliseconds
        let endTime = currentTimeInMilliseconds

        // GENDER FILTER
        let defaults = UserDefaults.standard
        let showMen = defaults.bool(forKey: "men")
        let showWomen = defaults.bool(forKey: "women")
        
        
        let media24HourQuery = Constants.MEDIA_INFO_REF
            .queryOrdered(byChild: "timestamp")
            .queryStarting(atValue: startTime)
            .queryEnding(atValue: endTime)
        media24HourQuery.observe(FIRDataEventType.value, with: { snapshot in
            
            var newItems = [[String: Any]]()
            let snapDic = snapshot.value as? NSDictionary
            if snapDic != nil {
                
                for child in snapDic! {
                    
                    let childDic = child.value as? NSDictionary
                    let title  = childDic?["title"] as? String
                    let userID = childDic?["userID"] as? String
                    let mediaID = childDic?["mediaID"] as? String
                    let timestamp = childDic?["timestamp"] as? Double
                    let age = childDic?["age"] as? Int
                    let name = childDic?["name"] as? String
                    let gender = childDic?["gender"] as? String
                    
                    if showMen == true && showWomen == true {
                        // show all users
                    }
                    else if showMen == false && showWomen == false {
                        // show all users
                    }
                    else if showMen == false && showWomen == true {
                        if gender == "male" && userID != Constants.userID { // always show user's own intro
                            continue // exit loop for this childDic
                        }
                    }
                    else if showMen == true && showWomen == false {
                        if gender == "female" && userID != Constants.userID { // always show user's own intro
                            continue // exit loop for this childDic
                        }
                    }
                    
                    var mediaInfoDic: Dictionary<String, Any>?
                    // continue filter list by geographical radius:
                    //  key is found in the array of local mediaID from circleQuery
//                    print ("mediaLocationKeysWithinRadius: \(mediaLocationKeysWithinRadius)")
                    
                    if mediaLocationKeysWithinRadius.contains(mediaID!) && !blockList.contains(userID!){
                        
                        mediaInfoDic = [
                            "mediaID": mediaID!,
                            "timestamp": timestamp!,
                            "userID": userID!,
                            "title": title!,
                            "age": age,
                            "name": name,
                            "gender": gender
                        ]

                        newItems.append(mediaInfoDic!)
                        self.mediaIntroQueueList = newItems
                        self.tableView.reloadData()
                    }
                }
            }
        })
    }
    
    func getIntroductionsForAdmin() {
        
        // special query only available for admins/staff
        
        // DOWNLOAD LIST OF VIDEOS and TITLES
        // filters: no geographical radius, timestamp within 72 hours

        var mediaLocationKeysWithinRadius = [String]()
        
        if let center = currentLocation {
            let circleQuery = Constants.geoFireMedia?.query(at: center, withRadius: 50) // in km
            
            circleQuery?.observe(GFEventType.keyEntered, with: { (key: String?, location: CLLocation?) in
                mediaLocationKeysWithinRadius.append(key!)
            })
        }
        
        // timeIntervalSince1970 takes seconds, while the timestamp from firebase is in milliseconds
        let currentTimeInMilliseconds = Date().timeIntervalSince1970 * 1000
        let twentyFourHoursInMilliseconds:Double = 86400000
        let startTime = currentTimeInMilliseconds - (twentyFourHoursInMilliseconds * 3)
        let endTime = currentTimeInMilliseconds
        
        // GENDER FILTER
        let defaults = UserDefaults.standard
        let showMen = defaults.bool(forKey: "men")
        let showWomen = defaults.bool(forKey: "women")
        
        let media72HourQuery = Constants.MEDIA_INFO_REF
            .queryOrdered(byChild: "timestamp")
            .queryStarting(atValue: startTime)
            .queryEnding(atValue: endTime)
        media72HourQuery.observe(FIRDataEventType.value, with: { snapshot in
            
            var newItems = [[String: Any]]()
            let snapDic = snapshot.value as? NSDictionary
            if snapDic != nil {
                
                for child in snapDic! {
                    
                    let childDic = child.value as? NSDictionary
                    let title  = childDic?["title"] as? String
                    let userID = childDic?["userID"] as? String
                    let mediaID = childDic?["mediaID"] as? String
                    let timestamp = childDic?["timestamp"] as? Double
                    let age = childDic?["age"] as? Int
                    let name = childDic?["name"] as? String
                    let gender = childDic?["gender"] as? String
                    
                    if showMen == true && showWomen == true {
                        // show all users
                    }
                    else if showMen == false && showWomen == false {
                        // show all users
                    }
                    else if showMen == false && showWomen == true {
                        if gender == "male" && userID != Constants.userID { // always show user's own intro {
                            continue // exit loop for this childDic
                        }
                    }
                    else if showMen == true && showWomen == false {
                        if gender == "female" && userID != Constants.userID {// always show user's own intro {
                            continue // exit loop for this childDic
                        }
                    }
            
                    var mediaInfoDic: Dictionary<String, Any>?

                        mediaInfoDic = [
                            "mediaID": mediaID!,
                            "timestamp": timestamp!,
                            "userID": userID!,
                            "title": title!,
                            "age": age,
                            "name": name,
                            "gender": gender
                        ]
                        
                        newItems.append(mediaInfoDic!)
                        self.mediaIntroQueueList = newItems
                        self.tableView.reloadData()
    
                }
            }
        })
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        if mediaIntroQueueList.count > 0  {
            return mediaIntroQueueList.count
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
        
        // custom purple
        let purpleUIColor = UIColor(red: 52/255, green: 0/255, blue: 127/255, alpha: 1)
        
        cell.textLabel?.textColor = purpleUIColor

        cell.textLabel?.highlightedTextColor = UIColor.white
        
        cell.textLabel?.font = UIFont(name: "Helvetica", size: 20.0)
//        cell.textLabel?.backgroundColor = UIColor(red: 52/255, green: 0/255, blue: 127/255, alpha: 1)
        let title = mediaIntroQueueList[(indexPath as NSIndexPath).section]["title"] as? String
        let name = mediaIntroQueueList[(indexPath as NSIndexPath).section]["name"] as? String
        let userID = mediaIntroQueueList[(indexPath as NSIndexPath).section]["userID"] as? String
        
        if userID == Constants.userID {
            // this is the user's own introduction video.
            cell.textLabel?.text = "You: \(title ?? "")"
            cell.textLabel?.textColor = UIColor.red

        }
        else {
            cell.textLabel?.text = "\(name ?? ""): \(title ?? "")"
        }

        return cell
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        let selectedCell = tableView.cellForRow(at: indexPath)
        
        selectedUserAtIndexPath = (indexPath as NSIndexPath).section
        
        // download and show video
        playVideoAtCell(selectedUserAtIndexPath!)

        currentlyPlayingVideo = true // don't present avPlayer in playVideoAtCell if user has already tapped

    }

    func playVideoAtCell(_ cellNumber: Int) {

        if (currentlyPlayingVideo) {return}
        
        getDownloadURL(cellNumber) { (url) in
            self.avPlayer = AVPlayer(url: url)
            self.avPlayerViewController.player = self.avPlayer
            self.avPlayerViewController.showsPlaybackControls = false
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.videoItemFinished(_:)), name: NSNotification.Name.AVPlayerItemDidPlayToEndTime, object: self.avPlayer?.currentItem)
            
            self.present(self.avPlayerViewController, animated: true) { () -> Void in
//                self.addContentOverlayView() // think about adding this later

                self.avPlayerViewController.player?.play()
            }
        }
    }
    
    
    func getDownloadURL (_ cellNumber: Int, callback: @escaping (URL) -> ()) {
        let mediaID = mediaIntroQueueList[cellNumber]["mediaID"] as? String
        
        Constants.storageMediaRef.child("\(mediaID!)").downloadURL(completion: { (URL, error) in
            if error != nil {
                self.showVideoErrorAlert()
                if let indexPath = self.tableView.indexPathForSelectedRow {
                    self.tableView.deselectRow(at: indexPath, animated: true)
                }
                
            }
            if let downloadURL = URL {
                callback (downloadURL)
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
        passButton.addTarget(self, action:#selector(MeetVideoTableViewController.closeVideo), for:.touchUpInside)
        //        btnNext.layer.borderColor = UIColor ( red: 0.0, green: 0.0, blue: 1.0, alpha: 0.670476140202703 ).CGColor
        //        btnNext.layer.borderWidth = 1.0
        passButton.setImage(UIImage(named: "Meet_Cancel_75"), for: UIControlState.normal)
        overlayView.addSubview(passButton)

        let bottomMiddleRect = CGRect(x: (avPlayerViewController.view.bounds.width/2) - 30, y:avPlayerViewController.view.bounds.height - 70, width: 70, height: 70)
        let reportButton = UIButton(frame:bottomMiddleRect)
        reportButton.setTitle("", for: UIControlState())
        reportButton.setImage(UIImage(named: "meet_Flag_2_25"), for: .normal)
        reportButton.addTarget(self, action:#selector(showReportAction), for: .touchUpInside)
        let toUserID = mediaIntroQueueList[selectedUserAtIndexPath!]["userID"] as! String
        overlayView.addSubview(reportButton)
        
        if toUserID == Constants.userID {
            reportButton.isHidden = true
        }
        
        let replayButton = UIButton(frame:CGRect(x: 0,y: 10,width: avPlayerViewController.view.bounds.width, height: avPlayerViewController.view.bounds.height - 190))
        replayButton.setTitle("", for:UIControlState())
        replayButton.addTarget(self, action:#selector(MeetVideoTableViewController.replayVideo), for:.touchUpInside)
        overlayView.addSubview(replayButton)
        
        let meetButton = UIButton(frame:CGRect(x: avPlayerViewController.view.bounds.width - 100,y:avPlayerViewController.view.bounds.height - 150,width: 60,height: 60))
        meetButton.setTitle("Meet", for:UIControlState())
        meetButton.addTarget(self, action:#selector(MeetVideoTableViewController.sendMeet), for:.touchUpInside)
        meetButton.setImage(UIImage(named: "Meet_Ok_75"), for: UIControlState.normal)
        overlayView.addSubview(meetButton)
        
        avPlayerViewController.view.addSubview(overlayView);
        
    }
    
    func sendMeet() {
        
        let toUserID = mediaIntroQueueList[selectedUserAtIndexPath!]["userID"] as! String
        // check if user is sending a video to himself..
        if toUserID != Constants.userID {
            currentlyPlayingVideo = false
            
            let sendMeetCamVC = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "SendMeetCamViewController") as! SendMeetCamViewController
            sendMeetCamVC.toUserID = toUserID
            
            topMostController().present(sendMeetCamVC, animated: true, completion: nil)
        }
        else {
            showMeetErrorAlert(reason: "Self Meet")
        }

    }
    
    
    func closeVideo() {
        overlayView.isHidden = true
        
        overlayView.removeFromSuperview()

        currentlyPlayingVideo = false
        dismiss(animated: true, completion: nil)
        return

    }
    
    func replayVideo() {
        overlayView.isHidden = true
        avPlayerViewController.player?.currentItem?.seek(to: kCMTimeZero)
        avPlayerViewController.player?.play()
    }
    
    func handleRefresh(refreshControl: UIRefreshControl) {
        
        mediaIntroQueueList.removeAll()
        getUserLocation()
        
        if !getUserAdminStatusFromDefaults() {
            getLocalIntroductions()
        }
        else {
            getIntroductionsForAdmin()
        }

        getLocalIntroductions()
        self.tableView.reloadData()
        refreshControl.endRefreshing()
    }
    
    
    func showReportAction() {
        
        let toUserID = mediaIntroQueueList[selectedUserAtIndexPath!]["userID"] as! String
        
        if toUserID == Constants.userID {
            let title = "Error"
            var message = "You Can't Report Yourself"

            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "Aww, OK...", style: .cancel) { (action) in
                self.closeVideo()
            }
            alertController.addAction(okAction)
            topMostController().present(alertController, animated: true, completion: nil)
        }
        else {
            
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
        

        
    }
    
    func reportUser() {
        let reportUserVC:ReportUserViewController = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "ReportUser") as! ReportUserViewController
        
        reportUserVC.userIDToReport = userIDFromMatch(selectedUserAtIndexPath!)
        
        topMostController().present(reportUserVC, animated: false, completion: nil)
        
    }
    
    func userIDFromMatch(_ selectedUserAtIndexPath: Int) -> String {
        let userID = mediaIntroQueueList[selectedUserAtIndexPath]["userID"] as! String
        return userID
    }
    
    //MARK: Alerts
    
    func showMeetErrorAlert(reason: String?) {
        let title = "Error"
        var message = "We ran into an error"
        if reason == "Self Meet" {
            message = "You can't meet yourself!"
        }
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "Aww, OK...", style: .cancel) { (action) in
            self.closeVideo()
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
