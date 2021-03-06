//
//  Utils.swift
//  DomoArigato
//
//  Created by FLK on 24/10/2015.
//  Copyright © 2015 FLKone. All rights reserved.
//

import Foundation
import UIKit

func delay(delay:Double, closure:()->()) {
    dispatch_after(
        dispatch_time(
            DISPATCH_TIME_NOW,
            Int64(delay * Double(NSEC_PER_SEC))
        ),
        dispatch_get_main_queue(), closure)
}

func imageViewWithImageName(name: String) -> UIImageView {
    let image = UIImage(named: name)
    let imageView = UIImageView(image: image)
    imageView.contentMode = .Center
    imageView.tintColor = UIColor.whiteColor()
    
    return imageView
}

// From https://gist.github.com/JadenGeller/1ff15b9958400f18f2c1
extension Bool {
    init<T : IntegerType>(_ integer: T){
        self.init(integer != 0)
    }
}
