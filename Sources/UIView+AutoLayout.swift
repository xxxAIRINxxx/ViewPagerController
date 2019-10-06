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
    
    public func checkTranslatesAutoresizing(_ withView: UIView?, toView: UIView?) {
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
    
    public func addPin(_ withView:UIView, attribute:NSLayoutConstraint.Attribute, toView:UIView?, constant:CGFloat) -> NSLayoutConstraint {
        checkTranslatesAutoresizing(withView, toView: toView)
        return addPinConstraint(self, withItem: withView, toItem: toView, attribute: attribute, constant: constant)
    }
    
    public func addPin(_ withView:UIView, isWithViewTop:Bool, toView:UIView?, isToViewTop:Bool, constant:CGFloat) -> NSLayoutConstraint {
        checkTranslatesAutoresizing(withView, toView: toView)
        return addConstraint(
            self,
            relation: .equal,
            withItem: withView,
            withAttribute: (isWithViewTop == true ? .top : .bottom),
            toItem: toView,
            toAttribute: (isToViewTop == true ? .top : .bottom),
            constant: constant
        )
    }
    
    public func allPin(_ subView: UIView) {
        checkTranslatesAutoresizing(subView, toView: nil)
        _ = addPinConstraint(self, withItem: subView, toItem: self, attribute: .top, constant: 0.0)
        _ = addPinConstraint(self, withItem: subView, toItem: self, attribute: .bottom, constant: 0.0)
        _ = addPinConstraint(self, withItem: subView, toItem: self, attribute: .left, constant: 0.0)
        _ = addPinConstraint(self, withItem: subView, toItem: self, attribute: .right, constant: 0.0)
    }
    
    // MARK: NSLayoutConstraint
    
    public func addPinConstraint(_ parentView: UIView, withItem:UIView, toItem:UIView?, attribute:NSLayoutConstraint.Attribute, constant:CGFloat) -> NSLayoutConstraint {
        return addConstraint(
            parentView,
            relation: .equal,
            withItem: withItem,
            withAttribute: attribute,
            toItem: toItem,
            toAttribute: attribute,
            constant: constant
        )
    }
    
    public func addWidthConstraint(_ view: UIView, constant:CGFloat) -> NSLayoutConstraint {
        return addConstraint(
            view,
            relation: .equal,
            withItem: view,
            withAttribute: .width,
            toItem: nil,
            toAttribute: .width,
            constant: constant
        )
    }
    
    public func addHeightConstraint(_ view: UIView, constant:CGFloat) -> NSLayoutConstraint {
        return addConstraint(
            view,
            relation: .equal,
            withItem: view,
            withAttribute: .height,
            toItem: nil,
            toAttribute: .height,
            constant: constant
        )
    }
    
    public func addConstraint(_ addView: UIView, relation: NSLayoutConstraint.Relation, withItem:UIView, withAttribute:NSLayoutConstraint.Attribute, toItem:UIView?, toAttribute:NSLayoutConstraint.Attribute, constant:CGFloat) -> NSLayoutConstraint {
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
