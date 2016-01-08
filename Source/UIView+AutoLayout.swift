//
//  UIView+AutoLayout.swift
//  ViewPagerController
//
//  Created by xxxAIRINxxx on 2016/01/05.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//

import Foundation
import UIKit

public extension UIView {
    
    public func checkTranslatesAutoresizing(withView: UIView?, toView: UIView?) {
        if self.translatesAutoresizingMaskIntoConstraints == true {
            self.translatesAutoresizingMaskIntoConstraints = false
        }
        
        if let _withView = withView {
            if _withView.translatesAutoresizingMaskIntoConstraints == true {
                _withView.translatesAutoresizingMaskIntoConstraints = false
            }
        }
        
        if let _toView = toView {
            if _toView.translatesAutoresizingMaskIntoConstraints == true {
                _toView.translatesAutoresizingMaskIntoConstraints = false
            }
        }
    }
    
    public func addPin(withView:UIView, attribute:NSLayoutAttribute, toView:UIView?, constant:CGFloat) -> NSLayoutConstraint {
        checkTranslatesAutoresizing(withView, toView: toView)
        return addPinConstraint(self, withItem: withView, toItem: toView, attribute: attribute, constant: constant)
    }
    
    public func addPin(withView:UIView, isWithViewTop:Bool, toView:UIView?, isToViewTop:Bool, constant:CGFloat) -> NSLayoutConstraint {
        checkTranslatesAutoresizing(withView, toView: toView)
        return addConstraint(
            self,
            relation: .Equal,
            withItem: withView,
            withAttribute: (isWithViewTop == true ? .Top : .Bottom),
            toItem: toView,
            toAttribute: (isToViewTop == true ? .Top : .Bottom),
            constant: constant
        )
    }
    
    public func allPin(subView: UIView) {
        checkTranslatesAutoresizing(subView, toView: nil)
        addPinConstraint(self, withItem: subView, toItem: self, attribute: .Top, constant: 0.0)
        addPinConstraint(self, withItem: subView, toItem: self, attribute: .Bottom, constant: 0.0)
        addPinConstraint(self, withItem: subView, toItem: self, attribute: .Left, constant: 0.0)
        addPinConstraint(self, withItem: subView, toItem: self, attribute: .Right, constant: 0.0)
    }
    
    // MARK: NSLayoutConstraint
    
    public func addPinConstraint(parentView: UIView, withItem:UIView, toItem:UIView?, attribute:NSLayoutAttribute, constant:CGFloat) -> NSLayoutConstraint {
        return addConstraint(
            parentView,
            relation: .Equal,
            withItem: withItem,
            withAttribute: attribute,
            toItem: toItem,
            toAttribute: attribute,
            constant: constant
        )
    }
    
    public func addWidthConstraint(view: UIView, constant:CGFloat) -> NSLayoutConstraint {
        return addConstraint(
            view,
            relation: .Equal,
            withItem: view,
            withAttribute: .Width,
            toItem: nil,
            toAttribute: .Width,
            constant: constant
        )
    }
    
    public func addHeightConstraint(view: UIView, constant:CGFloat) -> NSLayoutConstraint {
        return addConstraint(
            view,
            relation: .Equal,
            withItem: view,
            withAttribute: .Height,
            toItem: nil,
            toAttribute: .Height,
            constant: constant
        )
    }
    
    public func addConstraint(addView: UIView, relation: NSLayoutRelation, withItem:UIView, withAttribute:NSLayoutAttribute, toItem:UIView?, toAttribute:NSLayoutAttribute, constant:CGFloat) -> NSLayoutConstraint {
        let constraint = NSLayoutConstraint(
            item: withItem,
            attribute: withAttribute,
            relatedBy: relation,
            toItem: toItem,
            attribute: toAttribute,
            multiplier: 1.0,
            constant: constant
        )
        
        addView.addConstraint(constraint)
        
        return constraint
    }
}
