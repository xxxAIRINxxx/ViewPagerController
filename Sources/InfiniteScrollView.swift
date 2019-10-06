//
//  InfiniteScrollView.swift
//  ViewPagerController
//
//  Created by xxxAIRINxxx on 2016/01/05.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//
// @see : https://github.com/bteapot/BTInfiniteScrollView

import Foundation
import UIKit

public enum XPosition: Int {
    case start
    case middle
    case end
}

public struct InfiniteItem {
    let index : Int
    let thickness : CGFloat
    let view : UIView
    
    public init(_ index: Int, _ thickness: CGFloat, _ view: UIView) {
        self.index = index
        self.thickness = thickness
        self.view = view
    }
}

public protocol InfiniteScrollViewDataSource: class {
    
    func totalItemCount() -> Int
    
    func viewForIndex(_ index: Int) -> UIView
    
    func thicknessForIndex(_ index: Int) -> CGFloat
}

public protocol InfiniteScrollViewDelegate: class {
    
    func updateContentOffset(_ delta: CGFloat)
    
    func infiniteScrollViewWillBeginDecelerating(_ scrollView: UIScrollView)
    
    func infiniteScrollViewWillBeginDragging(_ scrollView: UIScrollView)
    
    func infinitScrollViewDidScroll(_ scrollView: UIScrollView)
    
    func infiniteScrollViewDidEndCenterScrolling(_ item: InfiniteItem)
    
    func infiniteScrollViewDidShowCenterItem(_ item: InfiniteItem)
}

public final class InfiniteScrollView: UIScrollView {

    public weak var infiniteDataSource : InfiniteScrollViewDataSource!
    public weak var infiniteDelegate : InfiniteScrollViewDelegate?
    
    public fileprivate(set) var items : [InfiniteItem] = []
    
    public var scrolling : Int = 0
    fileprivate var lastReportedItemIndex : Int = Int.min
    fileprivate var isUserScrolling = false
    
    // MARK: - Constructor
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    fileprivate func commonInit() {
        self.delegate = self
        self.autoresizesSubviews = false
        self.bounces = false
        self.showsHorizontalScrollIndicator = false
        self.panGestureRecognizer.maximumNumberOfTouches = 1
    }
    
    // MARK: - Override
    
    override public var frame: CGRect {
        get { return super.frame }
        set {
            if newValue.isEmpty { return }
            
            let bounds = self.bounds
            let oldVisibleCenterX = bounds.origin.x + bounds.size.width / 2.0
            
            super.frame = newValue
            
            let newBounds = self.bounds
            if newBounds.size.width * 5 > self.contentSize.width || newBounds.size.height < self.contentSize.height {
                super.contentSize = CGSize(width: newBounds.width * 5, height: newBounds.size.height)
            }
            
            let newVisibleCenterX = newBounds.origin.x + newBounds.size.width / 2.0
            let deltaX = oldVisibleCenterX - newVisibleCenterX
            
            self.items = self.items.map(){ item in
                item.view.frame.origin.x = item.view.frame.origin.x - deltaX
                item.view.frame.size.height = newBounds.size.height
                return item
            }
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        guard self.infiniteDataSource.totalItemCount() > 0 else { return }
        
        var bounds = self.bounds
        let visible = bounds.size.width
        
        if self.scrolling == 0 {
            var delta = self.contentSize.width / 2 - bounds.midX
            let allow = self.isPagingEnabled ? !self.isDecelerating : true
            
            if allow && abs(delta) > visible {
                delta = visible * (delta > 0 ? 1 : -1)
                
                self.delegate = nil
                
                let contentOffset = self.contentOffset
                self.contentOffset = CGPoint(x: contentOffset.x + delta, y: contentOffset.y)
                
                self.delegate = self
                
                bounds = self.bounds
                
                self.items = self.items.map(){ item in
                    item.view.frame.origin.x += delta
                    return item
                }
                self.infiniteDelegate?.updateContentOffset(delta)
            }
        }
        
        let minVisible = bounds.minX
        let maxVisible = bounds.maxX
        
        let lastItem = self.items.last
        var index = 0
        var endEdge: CGFloat = 0
        
        if let _item = lastItem {
            index = _item.index
            endEdge = _item.view.frame.maxX
        } else {
            endEdge = self.placeNewItem(.middle, edge: 0, index: 0)
        }
        
        while (endEdge < maxVisible) {
            index += 1
            endEdge = self.placeNewItem(.end, edge: endEdge, index: index)
        }
        
        let firstItem = self.items.first
        var startEdge: CGFloat = 0
        
        if let _item = firstItem {
            index = _item.index
            startEdge = _item.view.frame.minX
        }
        
        while (startEdge > minVisible) {
            index -= 1
            startEdge = self.placeNewItem(.start, edge: startEdge, index: index)
        }
        
        if self.scrolling == 0 && self.items.count > 0 {
            var lasted = self.items.last
            while (lasted != nil && lasted!.view.frame.minX >= maxVisible) {
                lasted!.view.removeFromSuperview()
                self.items.removeLast()
                lasted = self.items.last
            }
            
            var firsted = self.items.first
            while (firsted != nil && firsted!.view.frame.maxX <= minVisible) {
                firsted!.view.removeFromSuperview()
                self.items.remove(at: 0)
                firsted = self.items.first
            }
        }
        
        if let _item = self.itemAtCenterPosition() {
            if self.isUserScrolling { return }
            if self.lastReportedItemIndex != _item.index {
                self.lastReportedItemIndex = _item.index
                self.infiniteDelegate?.infiniteScrollViewDidShowCenterItem(_item)
            }
        }
    }
    
    // MARK: - Public Functions
    
    public func itemAtView(_ view: UIView) -> InfiniteItem? {
        return self.items.filter() { item in return item.view === view }.first
    }
    
    public func itemAtIndex(_ index: Int) -> InfiniteItem? {
        return self.items.filter() { item in return item.index == index }.first
    }
    
    public func updateItems(_ handler: ((InfiniteItem) -> InfiniteItem)) {
        self.items = self.items.map(handler)
    }
    
    public func reset() {
        self.subviews.forEach() { $0.removeFromSuperview() }
        self.items.removeAll(keepingCapacity: true)
    }
    
    public func reloadViews() {
        guard self.infiniteDataSource.totalItemCount() > 0 else { return }
        
        if let _targetItem = self.itemAtCenterPosition() {
            self.reloadView(.start, item: _targetItem, edge: _targetItem.view.frame.midX)
            
            var previousItem = _targetItem
            var item = self.itemAtIndex(previousItem.index + 1)
            
            while (item != nil) {
                self.reloadView(.end, item: item!, edge: previousItem.view.frame.maxX)
                previousItem = item!
                item = self.itemAtIndex(previousItem.index + 1)
            }
            
            previousItem = _targetItem
            item = self.itemAtIndex(previousItem.index - 1)
            
            while (item != nil) {
                self.reloadView(.end, item: item!, edge: previousItem.view.frame.maxX)
                previousItem = item!
                item = self.itemAtIndex(previousItem.index - 1)
            }
            
            self.setNeedsLayout()
            self.layoutIfNeeded()
        }
    }
    
    public func reloadView(_ position: XPosition, item: InfiniteItem, edge: CGFloat) {
        guard self.infiniteDataSource.totalItemCount() > 0 else { return }
      
        let convertIndex = self.convertIndex(item.index)
        let bounds = self.bounds
        let thickness = CGFloat(ceilf(Float(self.infiniteDataSource.thicknessForIndex(convertIndex))))
        let view = (self.infiniteDataSource.viewForIndex(convertIndex))
        
        switch position {
        case .start:
            item.view.frame = CGRect(x: edge - thickness, y: 0, width: thickness, height: bounds.size.height)
        case .middle:
            item.view.frame = CGRect(x: edge - thickness / 2.0, y: 0, width: thickness, height: bounds.size.height)
        case .end:
            item.view.frame = CGRect(x: edge, y: 0, width: thickness, height: bounds.size.height)
        }
        
        item.view.removeFromSuperview()
        self.addSubview(view)
    }
    
    public func resetWithIndex(_ index: Int) {
        guard self.infiniteDataSource.totalItemCount() > 0 else { return }
        if self.bounds.isEmpty { return }
        
        self.reset()
        _ = self.placeNewItem(.middle, edge: 0, index: index)
        self.setNeedsLayout()
        self.layoutIfNeeded()
    }
    
    public func itemAtCenterPosition() -> InfiniteItem? {
        let bounds = self.bounds
        let mark: CGFloat = bounds.midX
        for item in self.items {
            if item.view.frame.minX <= mark && item.view.frame.maxX >= mark {
                return item
            }
        }
        return nil
    }
    
    public func scrollToCenter(_ index: Int, offset: CGFloat, animated: Bool, animation: (() -> Void)?, completion: (() -> Void)?) {
        guard self.infiniteDataSource.totalItemCount() > 0 else { return }
        if self.bounds.isEmpty { return }
      
        self.setNeedsLayout()
        self.layoutIfNeeded()
      
        var bounds = self.bounds
        let visible = bounds.size.width
        
        var targetItem = self.items.filter({item in return item.index == index }).first
        
        if targetItem == nil {
            let firstItem = self.items.first
            let lastItem = self.items.last
            let isStart = index < firstItem!.index
            targetItem = self.createItem(index)
            var newItems: [InfiniteItem] = []
            newItems.append(targetItem!)
            
            var gap: CGFloat = isStart ? (visible - targetItem!.thickness) / 2.0 + offset : (visible - targetItem!.thickness) / 2.0 - offset
            
            var indexDelta = (isStart ? firstItem!.index - index : index - lastItem!.index) - 1
            var gapItemIndex = index
            
            while (indexDelta > 0 && gap >= 0) {
                gapItemIndex += isStart ? 1 : -1
                let item = self.createItem(gapItemIndex)
                
                isStart ? newItems.append(item) : newItems.insert(item, at: 0)
                
                gap -= item.thickness
                indexDelta -= 1
            }
            
            if isStart {
                var startEdge = firstItem!.view.frame.minX
                var newItemIndex = newItems.count - 1
                while newItemIndex >= 0 {
                    let item = newItems[newItemIndex]
                    item.view.frame = CGRect(x: startEdge - item.thickness, y: 0, width: item.thickness, height: bounds.size.height)
                    startEdge = item.view.frame.minX
                    self.addSubview(item.view)
                    self.items.insert(item, at: 0)
                    
                    newItemIndex -= 1
                }
            } else {
                var endEdge = firstItem!.view.frame.maxX
                self.items = newItems.map() { item in
                    item.view.frame = CGRect(x: endEdge, y: 0, width: item.thickness, height: bounds.size.height)
                    endEdge = item.view.frame.maxX
                    self.addSubview(item.view)
                    return item
                }
            }
        }
        
        bounds = CGRect(
            x: targetItem!.view.frame.minX - (bounds.size.width - targetItem!.thickness) / 2.0 + offset,
            y: 0,
            width: bounds.size.width,
            height: bounds.size.height
        )
        
        self.scrolling += 1
        self.setContentOffset(self.contentOffset, animated: false)
      
        if animated {
            UIView.animateKeyframes(withDuration: 0.25, delay: 0, options: .beginFromCurrentState, animations: {
                self.bounds = bounds
                animation?()
            }, completion: { finished in
                self.scrolling -= 1
                self.setNeedsLayout()
                self.layoutIfNeeded()
                completion?()
            })
        } else {
            self.bounds = bounds
            self.scrolling -= 1
            completion?()
        }
    }
    
    public func scrollToCenter(_ index: Int, animated: Bool, animation: (() -> Void)?, completion: (() -> Void)?) {
        self.scrollToCenter(index, offset: 0, animated: animated, animation: animation, completion: completion)
    }
    
    public func convertIndex(_ scrollViewIndex: Int) -> Int {
        let total = self.infiniteDataSource.totalItemCount()
        let currentIndex = scrollViewIndex >= 0 ? (scrollViewIndex % total) : (total - (-scrollViewIndex % total))
        
        return currentIndex == total ? 0 : currentIndex
    }
  
    // MARK: - Private Functions
    
    fileprivate func createItem(_ index: Int) -> InfiniteItem {
        let convertIndex = self.convertIndex(index)
        let bounds = self.bounds
        let thickness = CGFloat(ceilf(Float(self.infiniteDataSource.thicknessForIndex(convertIndex))))
        let view = self.infiniteDataSource.viewForIndex(convertIndex)
        
        view.frame = CGRect(x: 0, y: 0, width: thickness, height: bounds.size.height)
        
        return InfiniteItem(index, thickness, view)
    }
    
    fileprivate func placeNewItem(_ position: XPosition, edge: CGFloat, index: Int) -> CGFloat {
        let item = self.createItem(index)
        
        switch position {
        case .start:
            item.view.frame.origin.x = edge - item.thickness
            self.addSubview(item.view)
            self.items.insert(item, at: 0)
            return item.view.frame.minX
        case .middle:
            item.view.frame.origin.x = bounds.origin.x + (bounds.size.width - item.thickness) / 2.0
            self.addSubview(item.view)
            self.items.append(item)
            return item.view.frame.maxX
        case .end:
            item.view.frame.origin.x = edge
            self.addSubview(item.view)
            self.items.append(item)
            return item.view.frame.maxX
        }
    }
}

// MARK: - Private UIScrollViewDelegate

extension InfiniteScrollView: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
        self.infiniteDelegate?.infiniteScrollViewWillBeginDecelerating(scrollView)
    }
    
    public func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        self.infiniteDelegate?.infiniteScrollViewWillBeginDragging(scrollView)
        self.isUserScrolling = true
    }
    
    public func scrollViewDidScroll(_ scrollView: UIScrollView) {
        self.infiniteDelegate?.infinitScrollViewDidScroll(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        self.isUserScrolling = false
        
        if let _targetItem = self.itemAtCenterPosition() {
            self.scrollToCenter(_targetItem.index, offset: 0, animated: true, animation: nil, completion: nil)
            self.infiniteDelegate?.infiniteScrollViewDidEndCenterScrolling(_targetItem)
        }
    }
    
    public func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate { return }
        self.isUserScrolling = false
        
        if let _targetItem = self.itemAtCenterPosition() {
            self.scrollToCenter(_targetItem.index, offset: 0, animated: true, animation: nil, completion: nil)
            self.infiniteDelegate?.infiniteScrollViewDidEndCenterScrolling(_targetItem)
        }
    }
}
