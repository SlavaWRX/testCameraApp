//
//  CameraMan.swift
//  TestCameraApp
//
//  Created by Viacheslav Goroshniuk on 7/23/19.
//  Copyright © 2019 Viacheslav Goroshniuk. All rights reserved.
//

import Foundation
import PhotosUI

protocol CameraManDelegate: class {
    func cameraManNotAvailable(_ cameraMan: CameraMan)
    func cameraManDidStart(_ cameraMan: CameraMan)
    func cameraManLibraryNotAvailable(_ cameraMan: CameraMan)
}

class CameraMan: NSObject {
    weak var delegate: CameraManDelegate?
    
    let session = AVCaptureSession()
    let queue = DispatchQueue(label: "no.hyper.ImagePicker.Camera.SessionQueue")
    
    var backCamera: AVCaptureDeviceInput?
    var frontCamera: AVCaptureDeviceInput?
    var stillVideoOutput: AVCaptureMovieFileOutput?
    
    var startOnFrontCamera: Bool = false
    private var videoCompletion: ((PHAsset?) -> Void)?
    
    deinit {
        stop()
    }
    
    
    // MARK: - Setup
    
    func setup(_ startOnFrontCamera: Bool = false) {
        self.startOnFrontCamera = startOnFrontCamera
        checkPermission()
    }
    
    func setupDevices() {
        // Input
//        let deviceDiscoverySession = AVCaptureDevice.DiscoverySession.init(deviceTypes: [AVCaptureDevice.DeviceType.builtInWideAngleCamera], mediaType: .video, position: .back)
        AVCaptureDevice
            .devices()
            .filter {
                return $0.hasMediaType(AVMediaType.video)
            }.forEach {
                switch $0.position {
                case .front:
                    self.frontCamera = try? AVCaptureDeviceInput(device: $0)
                case .back:
                    self.backCamera = try? AVCaptureDeviceInput(device: $0)
                default:
                    break
                }
        }
        
        // Output
        
    }
    
    func addInput(_ input: AVCaptureDeviceInput) {
        if session.canAddInput(input) {
            session.addInput(input)
        }
    }
    
    
    // MARK: - Permission
    
    func checkPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: AVMediaType.video)
        
        switch status {
        case .authorized:
            start()
        case .notDetermined:
            requestPermission()
        default:
            delegate?.cameraManNotAvailable(self)
        }
        
        let libraryStatus = PHPhotoLibrary.authorizationStatus()
        switch libraryStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { _ in }
        case .denied:
            delegate?.cameraManLibraryNotAvailable(self)
        default:
            break
        }
    }
    
    func requestPermission() {
        AVCaptureDevice.requestAccess(for: AVMediaType.video) { granted in
            DispatchQueue.main.async {
                if granted {
                    self.start()
                } else {
                    self.delegate?.cameraManNotAvailable(self)
                }
            }
        }
    }
    
    
    // MARK: - Session
    
    fileprivate func start() {
        // Devices
        setupDevices()
        
        guard let input = (self.startOnFrontCamera) ? frontCamera ?? backCamera : backCamera else {
                return
        }
        
        addInput(input)
        
        if let videoOutput = stillVideoOutput,
            session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        queue.async {
            self.session.startRunning()
            
            DispatchQueue.main.async {
                self.delegate?.cameraManDidStart(self)
            }
        }
    }
    
    func stop() {
        self.session.stopRunning()
    }
    
    func recordVideo() {
        if let videoOutput = stillVideoOutput,
            session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        let tmpURL = URL(fileURLWithPath: NSTemporaryDirectory())
        let filePath = tmpURL.appendingPathComponent("temp.mov")
        
        stillVideoOutput?.startRecording(to: filePath,
                                         recordingDelegate: self)
        AudioServicesPlaySystemSound(1117)
    }
    
    func stopVideoRecordingAndSaveToLibrary(_ completion: ((PHAsset?) -> Void)? = nil) {
        guard let stillVideoOutput = stillVideoOutput,
            stillVideoOutput.isRecording else {
                return
        }
        stillVideoOutput.stopRecording()
        videoCompletion = completion
        AudioServicesPlaySystemSound(1118)
    }
    
    func saveVideo(_ url: URL, location: CLLocation?, completion: ((PHAsset?) -> Void)? = nil) {
        var identifier: String?
        PHPhotoLibrary.shared().performChanges({
            guard let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) else {
                return
            }
            request.creationDate = Date()
            if let location = location {
                request.location = location
            }
            identifier = request.placeholderForCreatedAsset?.localIdentifier
        }, completionHandler: { (_, _) in
            var asset: PHAsset?
            if let identifier = identifier {
                let assets = PHAsset.fetchAssets(withLocalIdentifiers: [identifier], options: nil)
                asset = assets.firstObject
            }
            
            DispatchQueue.main.async {
                completion?(asset)
            }
        })
    }
}

extension CameraMan: AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {

    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        
    }
}
