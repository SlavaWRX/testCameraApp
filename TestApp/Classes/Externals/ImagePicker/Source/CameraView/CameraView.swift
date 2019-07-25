//
//  CameraView.swift
//  TestCameraApp
//
//  Created by Viacheslav Goroshniuk on 7/25/19.
//  Copyright © 2019 Viacheslav Goroshniuk. All rights reserved.
//

import UIKit
import Photos

protocol CameraViewDelegate: class {
    func shareVideo(_ url: URL, assetId: String)
}

class CameraView: UIView, CameraManDelegate {
    
    var configuration = Configuration()
    
    let cameraMan = CameraMan()
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: CameraViewDelegate?
    var startOnFrontCamera: Bool = false
    var isRecordingVideo: Bool {
        return cameraMan.stillVideoOutput?.isRecording ?? false
    }
    
    
    // MARK: - Override methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
        cameraMan.delegate = self
        cameraMan.setup(self.startOnFrontCamera)
        backgroundColor = configuration.mainColor
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        
        previewLayer?.connection?.videoOrientation = .portrait
    }
    
    func setupPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: cameraMan.session)
        
        layer.backgroundColor = configuration.mainColor.cgColor
        layer.autoreverses = true
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        self.layer.insertSublayer(layer, at: 0)
        layer.frame = self.layer.frame
        self.clipsToBounds = true
        
        previewLayer = layer
    }
    
    
    // MARK: - Camera actions
    
    func startRecordVideo() {
        cameraMan.recordVideo()
    }
    
    func stopRecordVideo(_ completion: @escaping () -> Void) {
        cameraMan.stopVideoRecordingAndSaveToLibrary { _ in
            completion()
        }
    }
    
    
    // MARK: - Private helpers
    
    func showNoCamera(_ show: Bool) {
    }
    
    
    // CameraManDelegate
    func cameraManNotAvailable(_ cameraMan: CameraMan) {
        showNoCamera(true)
    }
    
    func cameraManLibraryNotAvailable(_ cameraMan: CameraMan) {
    }
    
    func cameraManDidStart(_ cameraMan: CameraMan) {
        setupPreviewLayer()
    }
    
    func cameraManShareVideo(_ url: URL, assetId: String) {
        delegate?.shareVideo(url, assetId: assetId)
    }
}

