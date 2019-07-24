//
//  CameraMan.swift
//  TestCameraApp
//
//  Created by Viacheslav Goroshniuk on 7/23/19.
//  Copyright © 2019 Viacheslav Goroshniuk. All rights reserved.
//

import Foundation
import PhotosUI

private let kCameraRecordingTimeKey = "kCameraRecordingTimeKey"

protocol CameraManDelegate: class {
    func cameraManNotAvailable(_ cameraMan: CameraMan)
    func cameraManDidStart(_ cameraMan: CameraMan)
    func cameraManLibraryNotAvailable(_ cameraMan: CameraMan)
    func cameraManShareVideo(_ url: URL, assetId: String)
}

class CameraMan: NSObject {
    weak var delegate: CameraManDelegate?
    
    let session = AVCaptureSession()
    let queue = DispatchQueue(label: "no.hyper.ImagePicker.Camera.SessionQueue")
    
    var backCamera: AVCaptureDeviceInput?
    var frontCamera: AVCaptureDeviceInput?
    var stillVideoOutput: AVCaptureMovieFileOutput?
    var stillCameraCaptureOutput: AVCaptureVideoDataOutput?
    
    var startOnFrontCamera: Bool = false
    private var videoCompletion: ((PHAsset?) -> Void)?
    
    private let userDefaults = UserDefaults.standard
    
    var recordingTime: Double {
        get {
            return 1
        }
    }
    
    deinit {
        stop()
    }
    
    
    // MARK: - Setup
    
    func setup(_ startOnFrontCamera: Bool = false) {
        self.startOnFrontCamera = startOnFrontCamera
        checkPermission()
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
        if let audioDevice = AVCaptureDevice.default(for: .audio),
            let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
            session.canAddInput(audioInput) {
            session.addInput(audioInput)
        }
        
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
    
    func camera(with position: AVCaptureDevice.Position) -> AVCaptureDevice? {
        let captureDeviceDiscoverySession = AVCaptureDevice.DiscoverySession(
            deviceTypes: [.builtInWideAngleCamera],
            mediaType: .video,
            position: .unspecified
        )
        
        for device in captureDeviceDiscoverySession.devices {
            if device.position == position {
                return device
            }
        }
        
        return nil
    }
    
    fileprivate func start() {
        // Devices

        let newCameraPosition: AVCaptureDevice.Position = self.startOnFrontCamera ? .front : .back
        let newCameraDevice = self.camera(with: newCameraPosition)
        guard let input = try? AVCaptureDeviceInput(device: newCameraDevice!) else {
            return
        }
        
        stillVideoOutput = AVCaptureMovieFileOutput()
        
        stillVideoOutput?.maxRecordedDuration = CMTime(seconds: 0, preferredTimescale: 180)
        print(stillVideoOutput?.maxRecordedDuration.value)
        
        stillCameraCaptureOutput = AVCaptureVideoDataOutput()
        stillCameraCaptureOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_32BGRA] as? [String : Any]
        stillCameraCaptureOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
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
    
    func saveVideo(_ url: URL, completion: ((PHAsset?) -> Void)? = nil) {
        var identifier: String?
        PHPhotoLibrary.shared().performChanges({
            guard let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) else {
                return
            }
            request.creationDate = Date()
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
    
    private func removeFileIfExists(_ filePath: URL) {
        let fileManager = FileManager.default
        if fileManager.fileExists(atPath: filePath.absoluteString) {
            do {
                try fileManager.removeItem(atPath: filePath.absoluteString)
            } catch {
                print(error)
            }
        }
    }
}

extension CameraMan: AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(captureOutput: AVCaptureFileOutput!, didStartRecordingToOutputFileAtURL fileURL: NSURL!, fromConnections connections: [AnyObject]!) {
        
    }
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        saveVideo(outputFileURL,
                  completion: { [weak self] asset in
                    print(outputFileURL)
                    self?.removeFileIfExists(outputFileURL)
                    guard let asset = asset else {
                        return
                    }
                    self?.delegate?.cameraManShareVideo(outputFileURL, assetId: asset.localIdentifier)
        })
    }
    
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        print("1")
    }
}
