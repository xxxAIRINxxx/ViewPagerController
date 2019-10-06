//
//  PagerContainerView.swift
//  ViewPagerController
//
//  Created by xxxAIRINxxx on 2016/01/05.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//

import Foundation
import UIKit
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}


public final class PagerContainerView: UIView {
    
    // MARK: - Public Handler Properties
    
    public var didShowViewControllerHandler : ((UIViewController) -> Void)?
    
    public var startSyncHandler : ((Int) -> Void)?
    
    public var syncOffsetHandler : ((_ currentIndex: Int, _ percentComplete: CGFloat, _ scrollingTowards: Bool) -> Void)?
    
    public var finishSyncHandler : ((Int) -> Void)?
    
    // MARK: - Private Properties
    
    fileprivate lazy var scrollView : InfiniteScrollView = {
        var scrollView = InfiniteScrollView(frame: self.bounds)
        scrollView.infiniteDataSource = self
        scrollView.infiniteDelegate = self
        scrollView.backgroundColor = UIColor.clear
        return scrollView
    }()
    
    // Contents
    fileprivate var contents : [UIViewController] = []
    
    // Sync ContainerView Scrolling
    public var scrollingIncrementalRatio: CGFloat = 1.1
    fileprivate var startDraggingOffsetX : CGFloat?
    fileprivate var startDraggingIndex : Int?
    
    // MARK: - Constructor
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }
    
    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    fileprivate func commonInit() {
        self.addSubview(self.scrollView)
        self.scrollView.isPagingEnabled = true
        self.scrollView.scrollsToTop = false
        
        self.setupConstraint()
    }
    
    // MARK: - Override
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.scrollView.frame = self.bounds
    }
    
    // MARK: - Public Functions
    
    public func addViewController(_ viewController: UIViewController) {
        self.contents.append(viewController)
        self.scrollView.reloadViews()
    }
    
    public func indexFromViewController(_ viewController: UIViewController) -> Int? {
        return self.contents.firstIndex(of: viewController)
        //return self.contents.index(of: viewController)
    }
    
    public func removeContent(_ viewController: UIViewController) {
        if let content = self.contents.filter({ $0 === viewController }).first {
            self.contents = self.contents.filter() { $0 !== content }
            self.scrollView.reset()
            self.reload()
        }
    }
    
    public func scrollToCenter(_ index: Int, animated: Bool, animation: (() -> Void)?, completion: (() -> Void)?) {
        if !self.scrollView.isDragging {
            let _index = self.currentIndex()
            if _index == index { return }
            if _index > index {
                self.scrollView.resetWithIndex(index + 1)
            } else {
                self.scrollView.resetWithIndex(index - 1)
            }
            self.scrollView.scrollToCenter(index, animated: animated, animation: animation) { [weak self] in
                self?.scrollView.resetWithIndex(index)
                completion?()
            }
        }
    }
    
    public func currentIndex() -> Int? {
        guard let currentItem = self.scrollView.itemAtCenterPosition() else { return nil }
        return currentItem.index
    }
    
    public func reload() {
        self.scrollView.resetWithIndex(0)
    }
  
    public func currentContent() -> UIViewController? {
        guard let _index = self.currentIndex() , _index != Int.min else { return nil }
      
        return self.contents[self.scrollView.convertIndex(_index)]
    }
}

// MARK: - Layout

extension PagerContainerView {
    
    fileprivate func setupConstraint() {
        self.allPin(self.scrollView)
    }
}

// MARK: - Sync ContainerView Scrolling

extension PagerContainerView {
    
    fileprivate func finishSyncViewScroll(_ index: Int) {
        self.finishSyncHandler?(index)
        self.startDraggingOffsetX = nil
        self.scrollView.setNeedsLayout()
        self.scrollView.layoutIfNeeded()
    }
}

// MARK: - InfiniteScrollViewDataSource

extension PagerContainerView: InfiniteScrollViewDataSource {
    
    public func totalItemCount() -> Int {
        return self.contents.count
    }
    
    public func viewForIndex(_ index: Int) -> UIView {
        let controller = self.contents[index]
        return controller.view
    }
    
    public func thicknessForIndex(_ index: Int) -> CGFloat {
        return self.frame.size.width
    }
}

// MARK: - InfiniteScrollViewDelegate

extension PagerContainerView: InfiniteScrollViewDelegate {
    
    public func updateContentOffset(_ delta: CGFloat) {
        self.startDraggingOffsetX? += delta
    }
    
    public func infiniteScrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {}
    
    public func infiniteScrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if let _currentItem = self.scrollView.itemAtCenterPosition() {
            if self.startDraggingOffsetX == nil {
                self.startSyncHandler?(_currentItem.index)
            } else {
                self.finishSyncViewScroll(_currentItem.index)
            }
        }
    }
    
    public func infinitScrollViewDidScroll(_ scrollView: UIScrollView) {
        if let _startDraggingOffsetX = self.startDraggingOffsetX {
            let offsetX = scrollView.contentOffset.x
            let scrollingTowards = _startDraggingOffsetX > offsetX
            let percent = (offsetX - _startDraggingOffsetX) / scrollView.bounds.width * self.scrollingIncrementalRatio
            let percentComplete = scrollingTowards == false ? percent : (1.0 - percent) - 1.0
            let _percentComplete =  min(1.0, percentComplete)
            
            if let _currentItem = self.scrollView.itemAtCenterPosition() {
                self.syncOffsetHandler?(_currentItem.index, _percentComplete, scrollingTowards)
            }
        } else {
            if scrollView.isDragging {
                self.startDraggingOffsetX = ceil(scrollView.contentOffset.x)
            }
        }
    }
    
    public func infiniteScrollViewDidEndCenterScrolling(_ item: InfiniteItem) {
        guard self.startDraggingOffsetX != nil else { return }
        
        if let _currentItem = self.scrollView.itemAtCenterPosition() {
            self.scrollView.scrollToCenter(_currentItem.index, animated: false, animation: nil, completion: nil)
            self.finishSyncViewScroll(_currentItem.index)
        }
    }
    
    public func infiniteScrollViewDidShowCenterItem(_ item: InfiniteItem) {
        guard let controller = self.contents.filter({ $0.view === item.view }).first else { return }
        self.didShowViewControllerHandler?(controller)
    }
}
