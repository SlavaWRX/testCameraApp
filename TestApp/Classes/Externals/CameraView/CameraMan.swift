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

enum FrameRates: Double {
    case thirty = 30
    case sixty = 60
}

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
    
    var recordingTime: Double? {
        didSet {
            updateRecordTime()
        }
    }
    
    var frameRate: FrameRates? {
        didSet {
            updateFrameRate()
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
    
    var currentInput: AVCaptureDeviceInput? {
        return session.inputs.first as? AVCaptureDeviceInput
    }
    
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
    
    private func updateRecordTime() {
        if let recordTime = recordingTime {
            stillVideoOutput?.maxRecordedDuration = CMTime(seconds: recordTime, preferredTimescale: 180)
        } else {
            stillVideoOutput?.maxRecordedDuration = CMTime.positiveInfinity
        }
    }
    
    private func updateFrameRate() {
        let newCameraDevice = self.camera(with: .back)
        if let frameRate = frameRate {
            newCameraDevice?.set(frameRate: frameRate.rawValue)
        } else {
            newCameraDevice?.set(frameRate: 30)
        }
    }
    
    fileprivate func start() {
        // Devices
        
        let newCameraPosition: AVCaptureDevice.Position = self.startOnFrontCamera ? .front : .back
        let newCameraDevice = self.camera(with: newCameraPosition)
        guard let input = try? AVCaptureDeviceInput(device: newCameraDevice!) else {
            return
        }
        
        // Inputs
        
        addInput(input)
        
        // Outputs
        
        stillVideoOutput = AVCaptureMovieFileOutput()
        
        updateRecordTime()
        updateFrameRate()

        stillCameraCaptureOutput = AVCaptureVideoDataOutput()
        stillCameraCaptureOutput?.videoSettings = [kCVPixelBufferPixelFormatTypeKey as AnyHashable: kCVPixelFormatType_32BGRA] as? [String : Any]
        stillCameraCaptureOutput?.setSampleBufferDelegate(self, queue: DispatchQueue.main)
        
        if let videoOutput = stillVideoOutput,
            session.canAddOutput(videoOutput) {
            session.addOutput(videoOutput)
        }
        
        if let audioDevice = AVCaptureDevice.default(for: .audio),
            let audioInput = try? AVCaptureDeviceInput(device: audioDevice),
            session.canAddInput(audioInput) {
            session.addInput(audioInput)
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
}

extension CameraMan: AVCaptureFileOutputRecordingDelegate, AVCaptureVideoDataOutputSampleBufferDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        saveVideo(outputFileURL,
                  completion: { [weak self] asset in
                    guard let asset = asset else {
                        return
                    }
                    self?.delegate?.cameraManShareVideo(outputFileURL, assetId: asset.localIdentifier)
        })
    }
}

extension AVCaptureDevice {
    func set(frameRate: Double) {
        guard let range = activeFormat.videoSupportedFrameRateRanges.first,
            range.minFrameRate...range.maxFrameRate ~= frameRate
            else {
                print("Requested FPS is not supported by the device's activeFormat !")
                return
        }
        
        do { try lockForConfiguration()
            activeVideoMinFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            activeVideoMaxFrameDuration = CMTimeMake(value: 1, timescale: Int32(frameRate))
            unlockForConfiguration()
        } catch {
            print("LockForConfiguration failed with error: \(error.localizedDescription)")
        }
    }
}
