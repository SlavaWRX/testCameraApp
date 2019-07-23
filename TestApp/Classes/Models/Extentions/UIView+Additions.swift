//
//  UIView+Additions.swift
//  TestCameraApp
//
//  Created by Viacheslav Goroshniuk on 7/23/19.
//  Copyright © 2019 Viacheslav Goroshniuk. All rights reserved.
//

import UIKit

extension UIView {
    public class func getNib() -> UINib? {
        let classString : String = NSStringFromClass(self.classForCoder())
        if let className = classString.components(separatedBy: ".").last {
            return UINib(nibName:className , bundle: nil)
        }
        return nil
    }
    
    public class func getReuseIdentifier() -> String {
        return NSStringFromClass(self)
    }
    
    static var reusableIdentifier: String {
        return "\(self.classForCoder())" + "_identifier"
    }
    
    static var nibForClass: UINib? {
        return UINib.init(nibName: "\(self.classForCoder())", bundle: nil)
    }
    
    public class var nibName: String {
        let name = "\(self)".components(separatedBy: ".").first ?? ""
        return name
    }
    
    public class var nib: UINib? {
        if let _ = Bundle.main.path(forResource: nibName, ofType: "nib") {
            return UINib(nibName: nibName, bundle: nil)
        } else {
            return nil
        }
    }
    
    public class func fromNib(_ nibNameOrNil: String? = nil) -> Self {
        return fromNib(nibNameOrNil, type: self)
    }
    
    public class func fromNib<T : UIView>(_ nibNameOrNil: String? = nil, type: T.Type) -> T {
        let v: T? = fromNib(nibNameOrNil, type: T.self)
        return v!
    }
    
    public class func fromNib<T : UIView>(_ nibNameOrNil: String? = nil, type: T.Type) -> T? {
        var view: T?
        let name: String
        if let nibName = nibNameOrNil {
            name = nibName
        } else {
            name = nibName
        }
        let nibViews = Bundle.main.loadNibNamed(name, owner: nil, options: nil)!
        for v in nibViews {
            if let tog = v as? T {
                view = tog
            }
        }
        return view
    }
}
