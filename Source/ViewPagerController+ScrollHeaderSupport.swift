//
//  ViewPagerController+ScrollHeaderSupport.swift
//  ViewPagerController
//
//  Created by xxxAIRINxxx on 2016/01/05.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//

import Foundation
import UIKit

extension ViewPagerController {
    
    // MARK: - Override (KVO)
   
    override public func observeValueForKeyPath(keyPath: String?, ofObject object: AnyObject?, change: [String : AnyObject]?, context: UnsafeMutablePointer<Void>) {
        if (keyPath == "contentOffset") {
            
            let old = change?[NSKeyValueChangeOldKey]?.CGPointValue
            let new = change?[NSKeyValueChangeNewKey]?.CGPointValue
            
            guard let _old = old, _new = new else { return }
            
            switch self.scrollViewObservingType {
            case .Header:
                self.updateHeaderViewHeight(_old, currentOffset: _new)
            case .NavigationBar:
                self.updateNavigationBarHeight(_old, currentOffset: _new)
            case .None:
                break
            }
        }
    }
    
    // MARK: - Public Functions
    
    public func resetHeaderViewHeight(animated: Bool) {
        self.headerViewHeightConstraint.constant = self.headerViewHeight
        UIView.animateWithDuration(animated ? 0.25 : 0, animations: {
            self.view.layoutIfNeeded()
        })
    }
    
    public func resetNavigationBarHeight(animated: Bool) {
        if let _navigationBar = self.targetNavigationBar {
            self.viewTopConstraint.constant = 0
            UIView.animateWithDuration(animated ? 0.25 : 0, animations: {
                _navigationBar.frame.origin.y = self.navigationBarBaselineOriginY()
               self.view.layoutIfNeeded()
            })
        }
    }
    
    // MARK: - Private Functions
    
    private func updateHeaderViewHeight(prevOffset: CGPoint, currentOffset: CGPoint) {
        let maxHeaderHeight = self.headerViewHeight
        let minHeaderHeight = self.scrollViewMinPositionY
        
        if prevOffset.y == currentOffset.y { return }
        
        if prevOffset.y <= currentOffset.y {
            // down scrolling
            if currentOffset.y <= 0 { return }
            
            let diff = currentOffset.y - prevOffset.y
            if (self.headerViewHeightConstraint.constant - diff) < minHeaderHeight {
                if self.headerViewHeightConstraint.constant == minHeaderHeight { return }
                self.headerViewHeightConstraint.constant = minHeaderHeight
            } else {
                self.headerViewHeightConstraint.constant -= diff * self.scrollViewObservingDelay
            }
        } else {
            // up scrolling
            if currentOffset.y > self.headerViewHeight { return }
            
            let diff = prevOffset.y - currentOffset.y
            if (self.headerViewHeightConstraint.constant + diff) > maxHeaderHeight {
                if self.headerViewHeightConstraint.constant == maxHeaderHeight { return }
                self.headerViewHeightConstraint.constant = maxHeaderHeight
            } else {
                self.headerViewHeightConstraint.constant += diff * self.scrollViewObservingDelay
            }
        }
        self.view.layoutIfNeeded()
        self.didChangeHeaderViewHeightHandler?(self.headerViewHeightConstraint.constant)
    }
    
    private func updateNavigationBarHeight(prevOffset: CGPoint, currentOffset: CGPoint) {
        if let _navigationBar = self.targetNavigationBar {
            let minHeaderHeight = self.scrollViewMinPositionY
            let baselineOriginY = self.navigationBarBaselineOriginY()
            let visibleBarHeight = _navigationBar.frame.size.height + _navigationBar.frame.origin.y
            let minNavigatonBarOriginY = -(_navigationBar.frame.size.height - minHeaderHeight)
            
            if prevOffset.y == currentOffset.y { return }
            
            if prevOffset.y <= currentOffset.y {
                // down scrolling
                if currentOffset.y <= 0 { return }
                let diff = currentOffset.y - prevOffset.y
                
                if (visibleBarHeight - diff) < minHeaderHeight {
                    _navigationBar.frame.origin.y = minNavigatonBarOriginY
                    self.viewTopConstraint.constant = minNavigatonBarOriginY - baselineOriginY
                } else {
                    _navigationBar.frame.origin.y -= diff * self.scrollViewObservingDelay
                    self.viewTopConstraint.constant -= diff * self.scrollViewObservingDelay
                }
            } else {
                // up scrolling
                if currentOffset.y > (baselineOriginY + _navigationBar.frame.size.height) { return }
                
                let diff = prevOffset.y - currentOffset.y
                if (_navigationBar.frame.origin.y + diff) > baselineOriginY {
                    _navigationBar.frame.origin.y = baselineOriginY
                    self.viewTopConstraint.constant = 0
                } else {
                    _navigationBar.frame.origin.y += diff * self.scrollViewObservingDelay
                    self.viewTopConstraint.constant += diff * self.scrollViewObservingDelay
                }
            }
            self.view.layoutIfNeeded()
            self.didChangeHeaderViewHeightHandler?(visibleBarHeight)
        }
    }
    
    private func navigationBarBaselineOriginY() -> CGFloat {
        return UIApplication.sharedApplication().statusBarFrame.size.height
    }
}
