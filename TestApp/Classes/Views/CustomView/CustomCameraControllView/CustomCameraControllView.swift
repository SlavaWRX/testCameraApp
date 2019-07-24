//
//  CustomCameraControllView.swift
//  TestCameraApp
//
//  Created by Viacheslav Goroshniuk on 7/23/19.
//  Copyright © 2019 Viacheslav Goroshniuk. All rights reserved.
//

import UIKit

protocol CustomCameraControllViewDelegate: class {
    func customCameraControllViewDidTapRecordButton(_ view: CustomCameraControllView)
}

class CustomCameraControllView: UIView {

    @IBOutlet weak var bottomView: UIView!
    @IBOutlet weak var cameraButton: UIButton!
    
    weak var delegate: CustomCameraControllViewDelegate?
    
    
    // MARK: - Override methods
    
    override func awakeFromNib() {
        super.awakeFromNib()
        
    }
    
    
    // MARK: - Action methods

    @IBAction func recordButtonTapped(_ sender: Any) {
        delegate?.customCameraControllViewDidTapRecordButton(self)
    }
}
