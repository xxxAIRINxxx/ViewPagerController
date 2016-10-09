//
//  UIColor+RGBA.swift
//  ViewPagerController
//
//  Created by xxxAIRINxxx on 2016/01/05.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//

import Foundation
import UIKit

public struct RGBA {
    var red : CGFloat = 0.0
    var green : CGFloat = 0.0
    var blue : CGFloat = 0.0
    var alpha  : CGFloat = 0.0
}

public extension UIColor {
    
    public func getRGBAStruct() -> RGBA {
        let components = self.cgColor.components
        let colorSpaceModel = self.cgColor.colorSpace?.model
        
        if colorSpaceModel?.rawValue == CGColorSpaceModel.rgb.rawValue && self.cgColor.numberOfComponents == 4 {
            return RGBA(
                red: components![0],
                green: components![1],
                blue: components![2],
                alpha: components![3]
            )
        } else if colorSpaceModel?.rawValue == CGColorSpaceModel.monochrome.rawValue && self.cgColor.numberOfComponents == 2 {
            return RGBA(
                red: components![0],
                green: components![0],
                blue: components![0],
                alpha: components![1]
            )
        } else {
            return RGBA()
        }
    }
}
