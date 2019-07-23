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
    
    private let cameraView = CameraView(configuration: nil)
    private var customCameraControll = CustomCameraControllView.fromNib()
    

    override func viewDidLoad() {
        super.viewDidLoad()

        cameraView.delegate = self
        containerView.addSubview(cameraView.view)
        bottomContainerView.addSubview(customCameraControll)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        cameraView.view.frame = containerView.bounds
        customCameraControll.frame = bottomContainerView.bounds
    }

}

extension CustomVideoCameraViewController: CameraViewDelegate {
    func videoToLibrary(_ asset: PHAsset?) {
        
    }
    
    func cameraNotAvailable() {
        
    }
    
    func libraryNotAvailable() {
        
    }
    

    
    
}


