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
    
    public init() {}
    
    // Header
    public var headerHeight : CGFloat = 0.0
    public var tabMenuHeight : CGFloat = 44.0
    public var headerContentsView : UIView?
    
    // TabMenu
    public var tabMenuAppearance : TabMenuAppearance = TabMenuAppearance()
    
    // ScrollHeaderSupport
    public var scrollViewMinPositionY : CGFloat = 20.0
    public var scrollViewObservingType : ObservingScrollViewType = .None
    public var scrollViewObservingDelay : CGFloat = 0.5
}

public struct TabMenuAppearance {
    
    public init() {}
    
    public var backgroundColor : UIColor = UIColor.blackColor()
    
    // Title Layout
    public var titleMargin : CGFloat = 15.0
    public var titleMinWidth : CGFloat = 30.0
    
    // Title Color
    public var defaultTitleColor : UIColor = UIColor.grayColor()
    public var highlightedTitleColor : UIColor = UIColor.whiteColor()
    public var selectedTitleColor : UIColor = UIColor.whiteColor()
    
    // Title Font
    public var defaultTitleFont : UIFont = UIFont.systemFontOfSize(14)
    public var highlightedTitleFont : UIFont = UIFont.systemFontOfSize(14)
    public var selectedTitleFont : UIFont = UIFont.boldSystemFontOfSize(15)
    
    // Selected View
    public var selectedViewBackgroundColor : UIColor = UIColor.greenColor()
    public var selectedViewInsets : UIEdgeInsets = UIEdgeInsetsMake(0, 0, 0, 0)
    
    public var backgroundContentsView : UIView?
}
