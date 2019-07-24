//
//  CustomVideoCameraViewController.swift
//  TestCameraApp
//
//  Created by Viacheslav Goroshniuk on 7/23/19.
//  Copyright © 2019 Viacheslav Goroshniuk. All rights reserved.
//

import UIKit
import Photos

class CustomVideoCameraViewController: UIViewController {
    
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var bottomContainerView: UIView!
    @IBOutlet weak var timerContainerView: UIView!
    @IBOutlet weak var timerLabel: UILabel!
    
    private let cameraView = CameraView(configuration: nil)
    private var cameraMan = CameraMan()
    private var startRecordTime: TimeInterval = 0.0
    private var customCameraControll = CustomCameraControllView.fromNib()
    
    private var minutes = 0
    private var seconds = 0
    private weak var timer: Timer?
    
    var recordingTime = 0.0
    
    // MARK: - Intance intialization
    
    convenience init(recordTime: Double) {
        self.init(nibName: nil, bundle: nil)
        self.recordingTime = recordTime
    }
    
    
    // MARK: - Override methods
    
    override func viewDidLoad() {
        super.viewDidLoad()

        configureUI()
        saveRecordingTime(recordingTime)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        cameraView.view.frame = containerView.bounds
        customCameraControll.frame = bottomContainerView.bounds
    }
    
    
    // MARK: - Private methods
    
    private func saveRecordingTime(_ time: Double) {
        
    }
    
    private func configureUI() {
        cameraView.delegate = self
        customCameraControll.delegate = self
        containerView.addSubview(cameraView.view)
        bottomContainerView.addSubview(customCameraControll)
        timerContainerView.backgroundColor = UIColor.black
        timerLabel.text = String(format: "%02d:%02d", minutes, seconds)
    }
    
    private func timerTick(){
        seconds += 1
        
        if seconds == 60{
            seconds = 0
            minutes += 1
        }
        
        let timeNow = String(format: "%02d:%02d", minutes, seconds)
        timerLabel.text = timeNow
    }
    
    private func  stopTimer() {
        timer?.invalidate()
    }
    
    private func startRecordingTime() {
        let timeNow = String(format: "%02d:%02d", minutes, seconds)
        timerLabel.text = timeNow
        
        stopTimer()
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.timerTick()
        }
    }
    
    private func userDidTapRecordButton() {
        if cameraView.isRecordingVideo {
            cameraView.stopRecordVideo {
            }
            stopTimer()
        } else {
            cameraView.startRecordVideo()
            startRecordingTime()
        }
    }
    
    private func shareVideo(_ assetId: [String], shareUrl: URL) {
        let videoLink = NSURL(fileURLWithPath: shareUrl.absoluteString)
        let objectsToShare = [videoLink]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        present(activityViewController, animated: true, completion: nil)
        activityViewController.completionWithItemsHandler = { (activity, success, items, error) in
            PHPhotoLibrary.shared().performChanges( {
                let imageAssetToDelete = PHAsset.fetchAssets(withLocalIdentifiers: assetId, options: nil)
                PHAssetChangeRequest.deleteAssets(imageAssetToDelete)
                print(imageAssetToDelete)
            }, completionHandler: { success, error in
                if success {
                    print("success")
                } else {
                    print("error")
                }
            })
            self.dismiss(animated: true, completion: nil)
        }
    }

}

extension CustomVideoCameraViewController: CameraViewDelegate {
    func shareVideo(_ url: URL, assetId: String) {
        shareVideo([assetId], shareUrl: url)
    }
    
    func videoToLibrary(_ asset: PHAsset?) {

    }
    
    func cameraNotAvailable() {
        
    }
    
    func libraryNotAvailable() {
        
    }
}

extension CustomVideoCameraViewController: CustomCameraControllViewDelegate {
    func customCameraControllViewDidTapRecordButton(_ view: CustomCameraControllView) {
        userDidTapRecordButton()
    }
}


