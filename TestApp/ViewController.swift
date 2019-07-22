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
    
    let imagePickerController = UIImagePickerController()
    
    
    // MARK: - Override methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    
    // MARK: - Action methods
    
    @IBAction func runCameraButtonTapped(_ sender: Any) {
        imagePickerController.sourceType = .camera
        imagePickerController.allowsEditing = true
        imagePickerController.delegate = self
        imagePickerController.mediaTypes = UIImagePickerController.availableMediaTypes(for: .camera)!
        imagePickerController.cameraCaptureMode = .video
        present(imagePickerController, animated: true)
    }
    
    
    
    // MARK: - Session
    
    func shareVideo(_ assetId: [String], shareUrl: String) {
        let videoLink = NSURL(fileURLWithPath: shareUrl)
        let objectsToShare = [videoLink]
        let activityViewController = UIActivityViewController(activityItems: objectsToShare, applicationActivities: nil)
        imagePickerController.present(activityViewController, animated: true, completion: nil)
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

extension ViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let mediaType = info[UIImagePickerController.InfoKey.mediaType] as? String, mediaType == (kUTTypeMovie as String),
            let url = info[UIImagePickerController.InfoKey.mediaURL] as? URL, UIVideoAtPathIsCompatibleWithSavedPhotosAlbum(url.path) else {
                return
        }
        
        var identifier: String?
        PHPhotoLibrary.shared().performChanges({
            guard let request = PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url) else {
                return
            }
            identifier = request.placeholderForCreatedAsset?.localIdentifier
        }, completionHandler:  { (_, _) in
            guard let identifier = identifier else {
                return
            }
            
            DispatchQueue.main.async {
                self.shareVideo([identifier], shareUrl: url.path)
            }
        })
    }
}

