//
//  ViewController.swift
//  TestApp
//
//  Created by Viacheslav Goroshniuk on 7/22/19.
//  Copyright © 2019 Viacheslav Goroshniuk. All rights reserved.
//

import UIKit
import Photos
import MobileCoreServices

class ViewController: UIViewController {
    
    // MARK: - Override methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
    }
    
    
    // MARK: - Action methods
    
    @IBAction func openCameraButtonTapped(_ sender: Any) {
        let customCameraController = CameraViewController(recordTime: 3, frameRate: .thirty)
        present(customCameraController, animated: true, completion: nil)
    }
}

