//
//  CamViewController.swift
//  butterfly2
//
//  Created by Alan Jaw on 7/28/16.
//  Copyright © 2016 Alan Jaw. All rights reserved.
//


import UIKit
import AVFoundation
import AssetsLibrary
import Photos
import MobileCoreServices
import FirebaseAuth
import CoreLocation
import RecordButton

var SessionRunningAndDeviceAuthorizedContext = "SessionRunningAndDeviceAuthorizedContext"
var CapturingStillImageContext = "CapturingStillImageContext"
var RecordingContext = "RecordingContext"

// handles introduction videos (called from HomeViewController)
class CamViewController: UIViewController, AVCaptureFileOutputRecordingDelegate  {
    
    // MARK: property
    
    var sessionQueue: DispatchQueue!
    var session: AVCaptureSession?
    var videoDeviceInput: AVCaptureDeviceInput?
    var movieFileOutput: AVCaptureMovieFileOutput?
    var stillImageOutput: AVCaptureStillImageOutput?
    
    var deviceAuthorized: Bool  = false
    var backgroundRecordId: UIBackgroundTaskIdentifier = UIBackgroundTaskInvalid
    var sessionRunningAndDeviceAuthorized: Bool {
        get {
            return (self.session?.isRunning != nil && self.deviceAuthorized )
        }
    }
    
    var runtimeErrorHandlingObserver: AnyObject?
    var lockInterfaceRotation: Bool = false

    var fileToUploadURL: URL!
    var fileToUploadDATA: Data!
    var currentMediaTypeToUpload: String?
    var uploadMediaTitle: String?
    
    @IBOutlet weak var previewView: AVCamPreviewView!
    
//    // TAKE PICTURE
//    @IBOutlet weak var snapButton: UIButton!
//    
//    // RECORD VIDEO
//    @IBOutlet weak var recordButton: UIButton!
    
    // REVERSE CAM
    @IBOutlet weak var cameraButton: UIButton!
    
    @IBOutlet weak var backButton: UIButton!
    
    var customRecordButton : RecordButton!
    var progressTimer : Timer!
    var progress : CGFloat! = 0
    
    var recordButtonSeconds: CGFloat! = 0
    var recordButtonTimer: Timer!
    var isRecording: Bool = false
    var inProcessOfRecordingOrSaving: Bool = false
    
    var holdButtonLabel: UILabel!

    // MARK: Override methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // custom recordButton https://github.com/samuelbeek/recordbutton
        let recordButtonRect = CGRect(x: 0, y: 0, width: 70, height: 70)
        customRecordButton = RecordButton(frame: recordButtonRect)
        customRecordButton.center.y = self.view.bounds.height - 70
        customRecordButton.progressColor = UIColor.red
        customRecordButton.closeWhenFinished = false
        customRecordButton.center.x = self.view.center.x
        customRecordButton.addTarget(self, action: #selector(record), for: .touchDown)
        customRecordButton.addTarget(self, action: #selector(stop), for: UIControlEvents.touchUpInside)
        self.view.addSubview(customRecordButton)
        
        holdButtonLabel = UILabel(frame: CGRect(x: 0, y: 0, width: 400, height: 30))
        holdButtonLabel.center.y = self.view.bounds.height - 150
        holdButtonLabel.center.x = self.view.center.x
        holdButtonLabel.textAlignment = .center
        
        holdButtonLabel.text = "Hold for 1 second to record"
        holdButtonLabel.textColor = UIColor.white
        self.view.addSubview(holdButtonLabel)
        
        let session: AVCaptureSession = AVCaptureSession()
        self.session = session
        
        self.previewView.session = session
        
        self.checkDeviceAuthorizationStatus()
        
        let sessionQueue: DispatchQueue = DispatchQueue(label: "session queue",attributes: [])
        
        self.sessionQueue = sessionQueue
        
        sessionQueue.async(execute: {

            self.backgroundRecordId = UIBackgroundTaskInvalid
            
            let videoDevice: AVCaptureDevice! = CamViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: AVCaptureDevicePosition.front) // start in reverse cam
            var error: NSError? = nil
            
            var videoDeviceInput: AVCaptureDeviceInput?
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: videoDevice)
            } catch let error1 as NSError {
                error = error1
                videoDeviceInput = nil
            } catch {
                fatalError()
            }
            
            if (error != nil) {
                print(error)
                self.presentCameraMicAccessErrorAlert(error: error!)
            }
            
            if session.canAddInput(videoDeviceInput){
                session.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
                DispatchQueue.main.async(execute: {
                    // Why are we dispatching this to the main queue?
                    // Because AVCaptureVideoPreviewLayer is the backing layer for AVCamPreviewView and UIView can only be manipulated on main thread.
                    // Note: As an exception to the above rule, it is not necessary to serialize video orientation changes on the AVCaptureVideoPreviewLayer’s connection with other session manipulation.
                    
                    // always keep the orientation portrait
                    let orientation: AVCaptureVideoOrientation =  AVCaptureVideoOrientation.portrait
                    
                    (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = orientation
                    
                })
                
            }
            
            
            let audioDevice: AVCaptureDevice = AVCaptureDevice.devices(withMediaType: AVMediaTypeAudio).first as! AVCaptureDevice
            
            var audioDeviceInput: AVCaptureDeviceInput?
            
            do {
                audioDeviceInput = try AVCaptureDeviceInput(device: audioDevice)
            } catch let error2 as NSError {
                error = error2
                audioDeviceInput = nil
            } catch {
                fatalError()
            }
            
            if error != nil{
                print (error)
                self.presentCameraMicAccessErrorAlert(error: error!)
            }
            
            if session.canAddInput(audioDeviceInput){
                session.addInput(audioDeviceInput)
            }
            
            
            
            let movieFileOutput: AVCaptureMovieFileOutput = AVCaptureMovieFileOutput()
            if session.canAddOutput(movieFileOutput){
                session.addOutput(movieFileOutput)
                
                
                let connection: AVCaptureConnection? = movieFileOutput.connection(withMediaType: AVMediaTypeVideo)
                let stab = connection?.isVideoStabilizationSupported
                if (stab != nil) {
                    //deprecated in iOS 8.0
                    //connection!.enablesVideoStabilizationWhenAvailable = true
                    connection!.preferredVideoStabilizationMode = AVCaptureVideoStabilizationMode.auto                }
                
                self.movieFileOutput = movieFileOutput
                
            }
            
            let stillImageOutput: AVCaptureStillImageOutput = AVCaptureStillImageOutput()
            if session.canAddOutput(stillImageOutput){
                stillImageOutput.outputSettings = [AVVideoCodecKey: AVVideoCodecJPEG]
                session.addOutput(stillImageOutput)
                
                self.stillImageOutput = stillImageOutput
            }
            
            
        })
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        self.tabBarController?.tabBar.isHidden = true
        
        self.checkDeviceAuthorizationStatus()
        getUserLocation()
        
        self.sessionQueue.async(execute: {
            
            self.addObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", options: [.old , .new] , context: &SessionRunningAndDeviceAuthorizedContext)
            self.addObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", options:[.old , .new], context: &CapturingStillImageContext)
            self.addObserver(self, forKeyPath: "movieFileOutput.recording", options: [.old , .new], context: &RecordingContext)
            
            NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange(_:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.videoDeviceInput?.device)
            
            
            weak var weakSelf = self
            
            self.runtimeErrorHandlingObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.AVCaptureSessionRuntimeError, object: self.session, queue: nil, using: {
                (note: Notification?) in
                let strongSelf: CamViewController = weakSelf!
                strongSelf.sessionQueue.async(execute: {
                    if let sess = strongSelf.session{
                        sess.startRunning()
                    }
                    
                })
                
            })
            
            self.session?.startRunning()
            
        })
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        self.sessionQueue.async(execute: {
            
            if let sess = self.session{
                sess.stopRunning()
                
                NotificationCenter.default.removeObserver(self, name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: self.videoDeviceInput?.device)
                NotificationCenter.default.removeObserver(self.runtimeErrorHandlingObserver!)
                
                self.removeObserver(self, forKeyPath: "sessionRunningAndDeviceAuthorized", context: &SessionRunningAndDeviceAuthorizedContext)
                
                self.removeObserver(self, forKeyPath: "stillImageOutput.capturingStillImage", context: &CapturingStillImageContext)
                self.removeObserver(self, forKeyPath: "movieFileOutput.recording", context: &RecordingContext)
            }
        })
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
    override var prefersStatusBarHidden : Bool {
        return true
    }
    
    override func willRotate(to toInterfaceOrientation: UIInterfaceOrientation, duration: TimeInterval) {
        
        (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation = AVCaptureVideoOrientation(rawValue: toInterfaceOrientation.rawValue)!
        
        //        if let layer = self.previewView.layer as? AVCaptureVideoPreviewLayer{
        //            layer.connection.videoOrientation = self.convertOrientation(toInterfaceOrientation)
        //        }
        
    }
    
    override var shouldAutorotate : Bool {
        return !self.lockInterfaceRotation
    }
    //    observeValueForKeyPath:ofObject:change:context:
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {

        if context == &CapturingStillImageContext{
            let isCapturingStillImage: Bool = (change![NSKeyValueChangeKey.newKey]! as AnyObject).boolValue
            if isCapturingStillImage {
                self.runStillImageCaptureAnimation()
            }
            
        }else if context  == &RecordingContext{
            let isRecording: Bool = (change![NSKeyValueChangeKey.newKey]! as AnyObject).boolValue
            
            DispatchQueue.main.async(execute: {
                
                if isRecording {
//                    self.recordButton.titleLabel!.text = "Stop"
//                    self.recordButton.isEnabled = true
                    //                    self.snapButton.enabled = false
                    self.cameraButton.isEnabled = false
                    self.backButton.isEnabled = false
                    
                }else{
                    //                    self.snapButton.enabled = true
                    
//                    self.recordButton.titleLabel!.text = "Record"
//                    self.recordButton.isEnabled = true
                    self.cameraButton.isEnabled = true
                    self.backButton.isEnabled = true

                }
       
            })
        }
            
        else {
            return super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
        
    }
    
    
    // MARK: Selector
    func subjectAreaDidChange(_ notification: Notification){
        let devicePoint: CGPoint = CGPoint(x: 0.5, y: 0.5)
        self.focusWithMode(AVCaptureFocusMode.continuousAutoFocus, exposureMode: AVCaptureExposureMode.continuousAutoExposure, point: devicePoint, monitorSubjectAreaChange: false)
    }
    
    // MARK:  Custom Function
    
    func focusWithMode(_ focusMode:AVCaptureFocusMode, exposureMode:AVCaptureExposureMode, point:CGPoint, monitorSubjectAreaChange:Bool){
        
        self.sessionQueue.async(execute: {
            let device: AVCaptureDevice! = self.videoDeviceInput!.device
            
            do {
                try device.lockForConfiguration()
                
                if device.isFocusPointOfInterestSupported && device.isFocusModeSupported(focusMode){
                    device.focusMode = focusMode
                    device.focusPointOfInterest = point
                }
                if device.isExposurePointOfInterestSupported && device.isExposureModeSupported(exposureMode){
                    device.exposurePointOfInterest = point
                    device.exposureMode = exposureMode
                }
                device.isSubjectAreaChangeMonitoringEnabled = monitorSubjectAreaChange
                device.unlockForConfiguration()
                
            }catch{
                print(error)
            }
        })
    }
    
    class func setFlashMode(_ flashMode: AVCaptureFlashMode, device: AVCaptureDevice){
        
        if device.hasFlash && device.isFlashModeSupported(flashMode) {
            var error: NSError? = nil
            do {
                try device.lockForConfiguration()
                device.flashMode = flashMode
                device.unlockForConfiguration()
                
            } catch let error1 as NSError {
                error = error1
                print(error)
            }
        }
    }
    
    func runStillImageCaptureAnimation(){
        DispatchQueue.main.async(execute: {
            self.previewView.layer.opacity = 0.0
            print("opacity 0")
            UIView.animate(withDuration: 0.25, animations: {
                self.previewView.layer.opacity = 1.0
                print("opacity 1")
            })
        })
    }
    
    class func deviceWithMediaType(_ mediaType: String, preferringPosition:AVCaptureDevicePosition)->AVCaptureDevice{
        
        var devices = AVCaptureDevice.devices(withMediaType: mediaType);
        var captureDevice: AVCaptureDevice = devices![0] as! AVCaptureDevice;
        
        for device in devices!{
            if (device as AnyObject).position == preferringPosition{
                captureDevice = device as! AVCaptureDevice
                break
            }
        }
        
        return captureDevice
        
    }
    
    func checkDeviceAuthorizationStatus(){
        let mediaType:String = AVMediaTypeVideo;
        
        AVCaptureDevice.requestAccess(forMediaType: mediaType, completionHandler: { (granted: Bool) in
            if granted{
                self.deviceAuthorized = true;
            }else{
                
                DispatchQueue.main.async(execute: {
                    self.presentCameraMicAccessErrorAlert(error: nil)
                })
                
                self.deviceAuthorized = false;
            }
        })
        
    }
    
    
    // MARK: File Output Delegate
    func capture(_ captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAt outputFileURL: URL!, fromConnections connections: [Any]!, error: Error!) {
        
        if(error != nil){
            print(error)
        }
        
        self.lockInterfaceRotation = false
        
        // Note the backgroundRecordingID for use in the ALAssetsLibrary completion handler to end the background task associated with this recording. This allows a new recording to be started, associated with a new UIBackgroundTaskIdentifier, once the movie file output's -isRecording is back to NO — which happens sometime after this method returns.
        
        let backgroundRecordId: UIBackgroundTaskIdentifier = self.backgroundRecordId
        self.backgroundRecordId = UIBackgroundTaskInvalid
        
        self.fileToUploadURL = outputFileURL
        self.presentAddCommentAlert()
    }
    
    func saveVideo(outputFileURL: URL) {
        
        PHPhotoLibrary.requestAuthorization { (authorizationStatus) in
            switch authorizationStatus {
            case .notDetermined: self.presentSaveErrorAlert()
            case .restricted: self.presentSaveErrorAlert()
            case .denied: self.presentSaveErrorAlert()
            case .authorized:
                
                PHPhotoLibrary.shared().performChanges({
                let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
                }, completionHandler: { (success, error) in
                    
                    if !success { NSLog("error creating asset: \(error)") }
                    else {
                        DispatchQueue.main.async(execute: {
                            self.presentFinishedSavingAlert()
                        })
                    }
            })
            }
        }
    }

    //MARK: Actions
    
    func startMovieRecord() {
        self.sessionQueue.async(execute: {
            if !self.movieFileOutput!.isRecording{
                self.lockInterfaceRotation = true
                
                if UIDevice.current.isMultitaskingSupported {
                    self.backgroundRecordId = UIApplication.shared.beginBackgroundTask(expirationHandler: {})
                    
                }
                
                self.movieFileOutput!.connection(withMediaType: AVMediaTypeVideo).videoOrientation =
                    AVCaptureVideoOrientation(rawValue: (self.previewView.layer as! AVCaptureVideoPreviewLayer).connection.videoOrientation.rawValue )!
                
                // Turning OFF flash for video recording
                CamViewController.setFlashMode(AVCaptureFlashMode.off, device: self.videoDeviceInput!.device)
                
                let outputFilePath  =
                    URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("movie.mp4")
                
                self.movieFileOutput!.startRecording( toOutputFileURL: outputFilePath, recordingDelegate: self)
            }
        })
    }
    
    func stopMovieRecord() {
        self.sessionQueue.async(execute: {
            self.movieFileOutput!.stopRecording()
        })
    }
    
    @IBAction func changeCamera(_ sender: AnyObject) {
        
        self.cameraButton.isEnabled = false
//        self.recordButton.isEnabled = false
//        self.snapButton.isEnabled = false
        
        self.sessionQueue.async(execute: {
            
            let currentVideoDevice:AVCaptureDevice = self.videoDeviceInput!.device
            let currentPosition: AVCaptureDevicePosition = currentVideoDevice.position
            var preferredPosition: AVCaptureDevicePosition = AVCaptureDevicePosition.unspecified
            
            switch currentPosition{
            case AVCaptureDevicePosition.front:
                preferredPosition = AVCaptureDevicePosition.back
            case AVCaptureDevicePosition.back:
                preferredPosition = AVCaptureDevicePosition.front
            case AVCaptureDevicePosition.unspecified:
                preferredPosition = AVCaptureDevicePosition.back
                
            }
            
            let device:AVCaptureDevice = CamViewController.deviceWithMediaType(AVMediaTypeVideo, preferringPosition: preferredPosition)
            
            var videoDeviceInput: AVCaptureDeviceInput?
            
            do {
                videoDeviceInput = try AVCaptureDeviceInput(device: device)
            } catch _ as NSError {
                videoDeviceInput = nil
            } catch {
                fatalError()
            }
            
            self.session!.beginConfiguration()
            
            self.session!.removeInput(self.videoDeviceInput)
            
            if self.session!.canAddInput(videoDeviceInput){
                
                NotificationCenter.default.removeObserver(self, name:NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object:currentVideoDevice)
                
                CamViewController.setFlashMode(AVCaptureFlashMode.auto, device: device)
                
                NotificationCenter.default.addObserver(self, selector: #selector(self.subjectAreaDidChange(_:)), name: NSNotification.Name.AVCaptureDeviceSubjectAreaDidChange, object: device)
                
                self.session!.addInput(videoDeviceInput)
                self.videoDeviceInput = videoDeviceInput
                
            }else{
                self.session!.addInput(self.videoDeviceInput)
            }
            
            self.session!.commitConfiguration()
            
            
            
            DispatchQueue.main.async(execute: {
//                self.recordButton.isEnabled = true
//                self.snapButton.isEnabled = true
                self.cameraButton.isEnabled = true
            })
            
        })

    }
    
    @IBAction func focusAndExposeTap(_ gestureRecognizer: UIGestureRecognizer) {
        
        print("focusAndExposeTap")
        let devicePoint: CGPoint = (self.previewView.layer as! AVCaptureVideoPreviewLayer).captureDevicePointOfInterest(for: gestureRecognizer.location(in: gestureRecognizer.view))
        
        print(devicePoint)
        
        self.focusWithMode(AVCaptureFocusMode.autoFocus, exposureMode: AVCaptureExposureMode.autoExpose, point: devicePoint, monitorSubjectAreaChange: true)
        
    }
    @IBAction func backButton(_ sender: UIButton) {
        tabBarController?.selectedViewController = tabBarController?.viewControllers?[1]
    }

    func countSecondsOfButtonPressed () {
        recordButtonSeconds = recordButtonSeconds + (CGFloat(0.05))
        print ("record button pressed for: \(recordButtonSeconds) seconds")
    }
    
    // Mark: RECORD BUTTON
    func record() {
        self.setTabBarSwipe(enabled: false)

        recordButtonTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(countSecondsOfButtonPressed), userInfo: nil, repeats: true)
  
        self.progressTimer = Timer.scheduledTimer(timeInterval: 0.05, target: self, selector: #selector(updateProgress), userInfo: nil, repeats: true)
    }
    
    func updateProgress() {

        let maxDuration = CGFloat(5) // max duration of the recordButton

        // only start video recording after 1 second of hold down button. this prevents recording on accidental taps. DO NOT change this unless you have good reason to.
        if recordButtonSeconds >= 1 {
            
            holdButtonLabel.isHidden = true
            
            progress = progress + (CGFloat(0.05) / maxDuration)
            customRecordButton.setProgress(progress)

            if !isRecording && !inProcessOfRecordingOrSaving {
                print ("Started Recording")
                isRecording = true
                inProcessOfRecordingOrSaving = true
                startMovieRecord()
            }
        }
        
        if progress >= 1 {
            stop()
        }

    }
    
    func stop() {
        self.progressTimer.invalidate()
        progress = 0
        customRecordButton.setProgress(progress)
        
        recordButtonTimer.invalidate()
        recordButtonSeconds = 0
        
        stopMovieRecord()
        isRecording = false
        
        holdButtonLabel.isHidden = false
        
        self.setTabBarSwipe(enabled: true)

    }

    // MARK: ALERTS
    func presentAddCommentAlert() {
        
        let alertController = UIAlertController(title: "Enter Title", message: nil, preferredStyle: .alert)
        
        let uploadAction = UIAlertAction(title: "Upload",
                                       style: .default) { [unowned self](action: UIAlertAction) -> Void in
                                        
                                        self.uploadMediaTitle = alertController.textFields![0].text ?? "untitled"
                                        uploadVideoToMediaInfo(self.fileToUploadURL, title: self.uploadMediaTitle ?? "\(Constants.userID)")
                                        self.uploadAlert()
                                                                            
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) -> Void in
            self.fileToUploadURL = nil
            self.inProcessOfRecordingOrSaving = false
            self.stop()
        }
        
        alertController.addTextField {
            (comment) -> Void in
            comment.placeholder = "Add a Comment"
        }
        
        alertController.addAction(uploadAction)
        alertController.addAction(cancelAction)
        topMostController().present(alertController, animated: true, completion: nil)
    }
    
    func uploadAlert() {
        
        let alertController = UIAlertController(title: "Upload success", message: "Your introduction will be viewable for 24 hours. Save to Phone?", preferredStyle: .alert)
        
        let cancelSaveAction = UIAlertAction(title: "Don't Save", style: .cancel) { (action) -> Void in
            self.inProcessOfRecordingOrSaving = false
//            self.dismiss(animated: true, completion: nil)
        }
        let saveAction = UIAlertAction(title: "Save to Phone",
                                        style: .default) { [unowned self](action: UIAlertAction) -> Void in
                                            self.saveVideo(outputFileURL: self.fileToUploadURL)
        }
        
        alertController.addAction(cancelSaveAction)
        alertController.addAction(saveAction)
        topMostController().present(alertController, animated: true, completion: nil)
    }
    
    func presentFinishedSavingAlert() {
        let alertController = UIAlertController(title: "Successfully Saved to Phone", message: nil, preferredStyle: .alert)

        let okAction = UIAlertAction(title: "OK", style: .cancel) { (action) -> Void in
//            self.dismiss(animated: true, completion: nil)
            self.inProcessOfRecordingOrSaving = false
        }

        alertController.addAction(okAction)
        topMostController().present(alertController, animated: true, completion: nil)
    }
    
    func presentSaveErrorAlert() {
        let alertController = UIAlertController(title: "We had trouble saving to your phone", message: "Enable Photos Access in Settings", preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: "OK", style: .cancel) { (action) -> Void in
            self.inProcessOfRecordingOrSaving = false
        }
        
        alertController.addAction(okAction)
        topMostController().present(alertController, animated: true, completion: nil)
    }
    
    func presentCameraMicAccessErrorAlert (error: Error?) {
        let alertController: UIAlertController = UIAlertController(
            title: "Butterfly needs access to the camera and mic so we can show you off!",
            message: "Go to Settings -> Butterfly and Allow Access To Camera and Microphone",
            preferredStyle: UIAlertControllerStyle.alert);
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (alertAction) in
            
            // go directly to Butterfly settings
            if let appSettings = URL(string: UIApplicationOpenSettingsURLString) {
                self.dismiss(animated: true, completion: nil)

                UIApplication.shared.openURL(appSettings)
            }
        }
        
        let action: UIAlertAction = UIAlertAction(title: "Cancel", style: UIAlertActionStyle.cancel, handler: {
            (action2: UIAlertAction) in
            self.dismiss(animated: true, completion: nil)
        } )
        
        alertController.addAction(action)
        alertController.addAction(settingsAction)
        
        self.present(alertController, animated: true, completion: nil);

    }
}


