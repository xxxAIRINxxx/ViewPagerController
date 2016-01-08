//
//  ViewPagerControllerAppearance.swift
//  ViewPagerController
//
//  Created by xxxAIRINxxx on 2016/01/06.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//

import Foundation
import UIKit

public struct ViewPagerControllerAppearance {
    
    // Header
    var headerHeight : CGFloat = 0.0
    var tabMenuHeight : CGFloat = 44.0
    var headerContentsView : UIView?
    
    // TabMenu
    var tabMenuAppearance : TabMenuAppearance = TabMenuAppearance()
    
    // ScrollHeaderSupport
    var scrollViewMinPositionY : CGFloat = 20.0
    var scrollViewObservingType : ObservingScrollViewType = .None
    var scrollViewObservingDelay : CGFloat = 0.5
}

public struct TabMenuAppearance {
    
    var backgroundColor : UIColor = UIColor.blackColor()
    
    // Title Layout
    var titleMargin : CGFloat = 15.0
    var titleMinWidth : CGFloat = 30.0
    
    // Title Color
    var defaultTitleColor : UIColor = UIColor.grayColor()
    var highlightedTitleColor : UIColor = UIColor.whiteColor()
    var selectedTitleColor : UIColor = UIColor.whiteColor()
    
    // Title Font
    var defaultTitleFont : UIFont = UIFont.systemFontOfSize(14)
    var highlightedTitleFont : UIFont = UIFont.systemFontOfSize(14)
    var selectedTitleFont : UIFont = UIFont.boldSystemFontOfSize(15)
    
    // Selected View
    var selectedViewBackgroundColor : UIColor = UIColor.greenColor()
    var selectedViewInsets : UIEdgeInsets = UIEdgeInsetsMake(10, 5, 10, 5)
    
    var backgroundContentsView : UIView?
}
