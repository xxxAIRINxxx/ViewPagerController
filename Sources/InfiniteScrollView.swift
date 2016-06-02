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
    case Start
    case Middle
    case End
}

public final class InfiniteItem: NSObject {
    var identifier : String
    var index : Int
    var thickness : CGFloat
    var view : UIView
    
    public init(identifier: String, index: Int, thickness: CGFloat, view: UIView) {
        self.identifier = identifier
        self.index = index
        self.thickness = thickness
        self.view = view
        super.init()
    }
}

public protocol InfiniteScrollViewDataSource: class {
    
    func totalItemCount() -> Int
    
    func viewForIndex(index: Int) -> UIView
    
    func thicknessForIndex(index: Int) -> CGFloat
}

public protocol InfiniteScrollViewDelegate: class {
    
    func updateContentOffset(delta: CGFloat)
    
    func infiniteScrollViewWillBeginDecelerating(scrollView: UIScrollView)
    
    func infiniteScrollViewWillBeginDragging(scrollView: UIScrollView)
    
    func infinitScrollViewDidScroll(scrollView: UIScrollView)
    
    func infiniteScrollViewDidEndCenterScrolling(item: InfiniteItem)
    
    func infiniteScrollViewDidShowCenterItem(item: InfiniteItem)
}

public final class InfiniteScrollView: UIScrollView {

    public weak var infiniteDataSource : InfiniteScrollViewDataSource!
    public weak var infiniteDelegate : InfiniteScrollViewDelegate?
    
    public private(set) var items : [InfiniteItem] = []
    
    public var scrolling : Int = 0
    private var lastReportedItemIndex : Int = Int.min
    private var isUserScrolling = false
    
    // MARK: - Constructor
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
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
            if CGRectIsEmpty(newValue) { return }
            
            let bounds = self.bounds
            let oldVisibleCenterX = bounds.origin.x + bounds.size.width / 2.0
            
            super.frame = newValue
            
            let newBounds = self.bounds
            if newBounds.size.width * 5 > self.contentSize.width || newBounds.size.height < self.contentSize.height {
                super.contentSize = CGSizeMake(newBounds.width * 5, newBounds.size.height)
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
            var delta = self.contentSize.width / 2 - CGRectGetMidX(bounds)
            let allow = self.pagingEnabled ? !self.decelerating : true
            
            if allow && fabs(delta) > visible {
                delta = visible * (delta > 0 ? 1 : -1)
                
                self.delegate = nil
                
                let contentOffset = self.contentOffset
                self.contentOffset = CGPointMake(contentOffset.x + delta, contentOffset.y)
                
                self.delegate = self
                
                bounds = self.bounds
                
                self.items = self.items.map(){ item in
                    item.view.frame.origin.x += delta
                    return item
                }
                self.infiniteDelegate?.updateContentOffset(delta)
            }
        }
        
        let minVisible = CGRectGetMinX(bounds)
        let maxVisible = CGRectGetMaxX(bounds)
        
        let lastItem = self.items.last
        var index = 0
        var endEdge: CGFloat = 0
        
        if let _item = lastItem {
            index = _item.index
            endEdge = CGRectGetMaxX(_item.view.frame)
        } else {
            endEdge = self.placeNewItem(.Middle, edge: 0, index: 0)
        }
        
        while (endEdge < maxVisible) {
            index += 1
            endEdge = self.placeNewItem(.End, edge: endEdge, index: index)
        }
        
        let firstItem = self.items.first
        var startEdge: CGFloat = 0
        
        if let _item = firstItem {
            index = _item.index
            startEdge = CGRectGetMinX(_item.view.frame)
        }
        
        while (startEdge > minVisible) {
            index -= 1
            startEdge = self.placeNewItem(.Start, edge: startEdge, index: index)
        }
        
        if self.scrolling == 0 && self.items.count > 0 {
            var lasted = self.items.last
            while (lasted != nil && CGRectGetMinX(lasted!.view.frame) >= maxVisible) {
                lasted!.view.removeFromSuperview()
                self.items.removeLast()
                lasted = self.items.last
            }
            
            var firsted = self.items.first
            while (firsted != nil && CGRectGetMaxX(firsted!.view.frame) <= minVisible) {
                firsted!.view.removeFromSuperview()
                self.items.removeAtIndex(0)
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
    
    public func itemAtView(view: UIView) -> InfiniteItem? {
        let item = self.items.filter() { item in return item.view == view }
        return item.first
    }
    
    public func itemAtIndex(index: Int) -> InfiniteItem? {
        let item = self.items.filter() { item in return item.index == index }
        return item.first
    }
    
    public func updateItems(handler: (InfiniteItem -> InfiniteItem)) {
        self.items = self.items.map(handler)
    }
    
    public func reset() {
        self.subviews.forEach() { $0.removeFromSuperview() }
        self.items.removeAll(keepCapacity: true)
    }
    
    public func reloadViews() {
        guard self.infiniteDataSource.totalItemCount() > 0 else { return }
        
        if let _targetItem = self.itemAtCenterPosition() {
            self.reloadView(.Start, item: _targetItem, edge: CGRectGetMidX(_targetItem.view.frame))
            
            var previousItem = _targetItem
            var item = self.itemAtIndex(previousItem.index + 1)
            
            while (item != nil) {
                self.reloadView(.End, item: item!, edge: CGRectGetMaxX(previousItem.view.frame))
                previousItem = item!
                item = self.itemAtIndex(previousItem.index + 1)
            }
            
            previousItem = _targetItem
            item = self.itemAtIndex(previousItem.index - 1)
            
            while (item != nil) {
                self.reloadView(.End, item: item!, edge: CGRectGetMaxX(previousItem.view.frame))
                previousItem = item!
                item = self.itemAtIndex(previousItem.index - 1)
            }
            
            self.setNeedsLayout()
        }
    }
    
    public func reloadView(position: XPosition, item: InfiniteItem, edge: CGFloat) {
        guard self.infiniteDataSource.totalItemCount() > 0 else { return }
        
        let bounds = self.bounds
        let thickness = CGFloat(ceilf(Float(self.infiniteDataSource.thicknessForIndex(item.index))))
        let view = (self.infiniteDataSource.viewForIndex(item.index))
        
        switch position {
        case .Start:
            item.view.frame = CGRectMake(edge - thickness, 0, thickness, bounds.size.height)
        case .Middle:
            item.view.frame = CGRectMake(edge - thickness / 2.0, 0, thickness, bounds.size.height)
        case .End:
            item.view.frame = CGRectMake(edge, 0, thickness, bounds.size.height)
        }
        
        item.view.removeFromSuperview()
        self.addSubview(view)
        item.view = view
    }
    
    public func resetWithIndex(index: Int) {
        guard self.infiniteDataSource.totalItemCount() > 0 else { return }
        if CGRectIsEmpty(self.bounds) { return }
        
        self.reset()
        self.placeNewItem(.Middle, edge: 0, index: index)
        self.setNeedsLayout()
    }
    
    public func itemAtCenterPosition() -> InfiniteItem? {
        let bounds = self.bounds
        let mark: CGFloat = CGRectGetMidX(bounds)
        for item in self.items {
            if CGRectGetMinX(item.view.frame) <= mark && CGRectGetMaxX(item.view.frame) >= mark {
                return item
            }
        }
        return nil
    }
    
    public func scrollToCenter(index: Int, offset: CGFloat, animated: Bool, animation: (Void -> Void)?, completion: (Void -> Void)?) {
        guard self.infiniteDataSource.totalItemCount() > 0 else { return }
        if CGRectIsEmpty(self.bounds) { return }
        
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
                
                isStart ? newItems.append(item) : newItems.insert(item, atIndex: 0)
                
                gap -= item.thickness
                indexDelta -= 1
            }
            
            if isStart {
                var startEdge = CGRectGetMinX(firstItem!.view.frame)
                var newItemIndex = newItems.count - 1
                while newItemIndex >= 0 {
                    let item = newItems[newItemIndex]
                    item.view.frame = CGRectMake(startEdge - item.thickness, 0, item.thickness, bounds.size.height)
                    startEdge = CGRectGetMinX(item.view.frame)
                    self.addSubview(item.view)
                    self.items.insert(item, atIndex: 0)
                    
                    newItemIndex -= 1
                }
            } else {
                var endEdge = CGRectGetMaxX(firstItem!.view.frame)
                self.items = newItems.map() { item in
                    item.view.frame = CGRectMake(endEdge, 0, item.thickness, bounds.size.height)
                    endEdge = CGRectGetMaxX(item.view.frame)
                    self.addSubview(item.view)
                    return item
                }
            }
        }
        
        bounds = CGRectMake(
            CGRectGetMinX(targetItem!.view.frame) - (bounds.size.width - targetItem!.thickness) / 2.0 + offset,
            0,
            bounds.size.width,
            bounds.size.height
        )
        
        self.scrolling += 1
        self.setContentOffset(self.contentOffset, animated: false)
        UIView.animateKeyframesWithDuration(
            animated ? 0.25 : 0,
            delay: 0,
            options: .BeginFromCurrentState,
            animations: { () -> Void in
                self.bounds = bounds
                animation?()
            }, completion: { finished in
                self.scrolling -= 1
                self.setNeedsLayout()
                self.layoutIfNeeded()
                completion?()
        })
    }
    
    public func scrollToCenter(index: Int, animated: Bool, animation: (Void -> Void)?, completion: (Void -> Void)?) {
        self.scrollToCenter(index, offset: 0, animated: animated, animation: animation, completion: completion)
    }
    
    public func convertIndex(scrollViewIndex: Int) -> Int {
        let total = self.infiniteDataSource.totalItemCount()
        let currentIndex = scrollViewIndex >= 0 ? (scrollViewIndex % total) : (total - (-scrollViewIndex % total))
        
        return currentIndex == total ? 0 : currentIndex
    }
  
    // MARK: - Private Functions
    
    private func createItem(index: Int) -> InfiniteItem {
        let convertIndex = self.convertIndex(index)
        let bounds = self.bounds
        let thickness = CGFloat(ceilf(Float(self.infiniteDataSource.thicknessForIndex(convertIndex))))
        let view = self.infiniteDataSource.viewForIndex(convertIndex)
        
        view.frame = CGRectMake(0, 0, thickness, bounds.size.height)
        
        return InfiniteItem(index, thickness, view)
    }
    
    private func placeNewItem(position: XPosition, edge: CGFloat, index: Int) -> CGFloat {
        let item = self.createItem(index)
        
        switch position {
        case .Start:
            item.view.frame.origin.x = edge - item.thickness
            self.addSubview(item.view)
            self.items.insert(item, atIndex: 0)
            return CGRectGetMinX(item.view.frame)
        case .Middle:
            item.view.frame.origin.x = bounds.origin.x + (bounds.size.width - item.thickness) / 2.0
            self.addSubview(item.view)
            self.items.append(item)
            return CGRectGetMaxX(item.view.frame)
        case .End:
            item.view.frame.origin.x = edge
            self.addSubview(item.view)
            self.items.append(item)
            return CGRectGetMaxX(item.view.frame)
        }
    }
}

// MARK: - Private UIScrollViewDelegate

extension InfiniteScrollView: UIScrollViewDelegate {
    
    public func scrollViewWillBeginDecelerating(scrollView: UIScrollView) {
        self.infiniteDelegate?.infiniteScrollViewWillBeginDecelerating(scrollView)
    }
    
    public func scrollViewWillBeginDragging(scrollView: UIScrollView) {
        self.infiniteDelegate?.infiniteScrollViewWillBeginDragging(scrollView)
        self.isUserScrolling = true
    }
    
    public func scrollViewDidScroll(scrollView: UIScrollView) {
        self.infiniteDelegate?.infinitScrollViewDidScroll(scrollView)
    }
    
    public func scrollViewDidEndDecelerating(scrollView: UIScrollView) {
        self.isUserScrolling = false
        
        if let _targetItem = self.itemAtCenterPosition() {
            self.scrollToCenter(_targetItem.index, offset: 0, animated: true, animation: nil, completion: nil)
            self.infiniteDelegate?.infiniteScrollViewDidEndCenterScrolling(_targetItem)
        }
    }
    
    public func scrollViewDidEndDragging(scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if decelerate { return }
        self.isUserScrolling = false
        
        if let _targetItem = self.itemAtCenterPosition() {
            self.scrollToCenter(_targetItem.index, offset: 0, animated: true, animation: nil, completion: nil)
            self.infiniteDelegate?.infiniteScrollViewDidEndCenterScrolling(_targetItem)
        }
    }
}
