//
//  CustomVideoCameraViewModel.swift
//  TestCameraApp
//
//  Created by Viacheslav Goroshniuk on 7/24/19.
//  Copyright © 2019 Viacheslav Goroshniuk. All rights reserved.
//

import Foundation

class CustomVideoCameraViewModel {
    
    var recordingTime: Double
    var frameRate: Double
    
    init(recordTime: Double, frameRate: Double) {
        self.recordingTime = recordTime
        self.frameRate = frameRate
    }
    
}
