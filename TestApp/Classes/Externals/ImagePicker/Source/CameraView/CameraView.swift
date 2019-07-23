//
//  CameraView.swift
//  TestCameraApp
//
//  Created by Viacheslav Goroshniuk on 7/23/19.
//  Copyright © 2019 Viacheslav Goroshniuk. All rights reserved.
//

import UIKit
import PhotosUI
import AVFoundation

protocol CameraViewDelegate: class {
    func videoToLibrary(_ asset: PHAsset?)
    func cameraNotAvailable()
    func libraryNotAvailable()
}

class CameraView: UIViewController, CameraManDelegate {

    var configuration = Configuration()
    
    let cameraMan = CameraMan()
    
    var previewLayer: AVCaptureVideoPreviewLayer?
    weak var delegate: CameraViewDelegate?
    var startOnFrontCamera: Bool = false
    var isRecordingVideo: Bool {
        return cameraMan.stillVideoOutput?.isRecording ?? false
    }
    
    
    
    public init(configuration: Configuration? = nil) {
        if let configuration = configuration {
            self.configuration = configuration
        }
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        view.backgroundColor = configuration.mainColor
        
        cameraMan.delegate = self
        cameraMan.setup(self.startOnFrontCamera)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        previewLayer?.connection?.videoOrientation = .portrait
    }
    
    func setupPreviewLayer() {
        let layer = AVCaptureVideoPreviewLayer(session: cameraMan.session)
        
        layer.backgroundColor = configuration.mainColor.cgColor
        layer.autoreverses = true
        layer.videoGravity = AVLayerVideoGravity.resizeAspectFill
        
        view.layer.insertSublayer(layer, at: 0)
        layer.frame = view.layer.frame
        view.clipsToBounds = true
        
        previewLayer = layer
    }
    
    
    // MARK: - Camera actions
    
    func startRecordVideo() {
        cameraMan.recordVideo()
    }
    
    func stopRecordVideo(_ completion: @escaping () -> Void) {
        cameraMan.stopVideoRecordingAndSaveToLibrary { [weak self] asset in
            self?.delegate?.videoToLibrary(asset)
            completion()
        }
    }
    
    
    // MARK: - Private helpers
    
    func showNoCamera(_ show: Bool) {
        
    }
    
    
    // CameraManDelegate
    func cameraManNotAvailable(_ cameraMan: CameraMan) {
        showNoCamera(true)
        delegate?.cameraNotAvailable()
    }
    
    func cameraManLibraryNotAvailable(_ cameraMan: CameraMan) {
        delegate?.libraryNotAvailable()
    }
    
    func cameraManDidStart(_ cameraMan: CameraMan) {
        setupPreviewLayer()
    }

}
