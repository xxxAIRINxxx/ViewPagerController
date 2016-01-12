//
//  ViewPagerController.swift
//  ViewPagerController
//
//  Created by xxxAIRINxxx on 2016/01/05.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//

import Foundation
import UIKit

public enum ObservingScrollViewType {
    case None
    case Header
    case NavigationBar(targetNavigationBar : UINavigationBar)
}

public class ViewPagerController: UIViewController {
    
    // MARK: - Public Handler Properties
    
    public var didShowViewControllerHandler : (UIViewController -> Void)?
    
    public var updateSelectedViewHandler : (UIView -> Void)?
    
    public var willBeginTabMenuUserScrollingHandler : (UIView -> Void)?
    
    public var didEndTabMenuUserScrollingHandler : (UIView -> Void)?
    
    public var didChangeHeaderViewHeightHandler : (CGFloat -> Void)?
    
    public var didShowViewControllerObservingHandler : (UIViewController -> UIScrollView?)?
    
    // MARK: - Custom Settings Properties
    
    public private(set) var headerViewHeight : CGFloat = 0.0
    public private(set) var tabMenuViewHeight : CGFloat = 0.0
    
    // ScrollHeaderSupport
    public private(set) var scrollViewMinPositionY : CGFloat = 0.0
    public private(set) var scrollViewObservingDelay : CGFloat = 0.0
    public private(set) var scrollViewObservingType : ObservingScrollViewType = .None {
        didSet {
            switch self.scrollViewObservingType {
            case .Header:
                self.targetNavigationBar = nil
            case .NavigationBar(let targetNavigationBar):
                self.targetNavigationBar = targetNavigationBar
            case .None:
                self.targetNavigationBar = nil
                self.observingScrollView = nil
            }
        }
    }
    
    // MARK: - Private Properties
    
    internal var headerView : UIView = UIView(frame: CGRectZero)
    
    internal var tabMenuView : PagerTabMenuView = PagerTabMenuView(frame: CGRectZero)
    
    internal var containerView : PagerContainerView = PagerContainerView(frame: CGRectZero)
    
    internal var targetNavigationBar : UINavigationBar?
    
    internal var headerViewHeightConstraint : NSLayoutConstraint!

    internal var tabMenuViewHeightConstraint : NSLayoutConstraint!

    internal var viewTopConstraint : NSLayoutConstraint!
    
    internal var observingScrollView : UIScrollView? {
        willSet { self.stopScrollViewContentOffsetObserving() }
        didSet { self.startScrollViewContentOffsetObserving() }
    }
    
    // MARK: - Override
    
    deinit {
        self.scrollViewObservingType = .None
    }
    
    public override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.addSubview(self.containerView)
        self.view.addSubview(self.tabMenuView)
        self.view.addSubview(self.headerView)
        
        self.setupConstraint()
        self.setupHandler()
        self.updateAppearance(ViewPagerControllerAppearance())
    }
    
    public override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.tabMenuView.stopScrolling(self.containerView.currentIndex())
        self.didEndTabMenuUserScrollingHandler?(self.tabMenuView.getSelectedView())
        self.tabMenuView.updateSelectedViewLayout(false)
    }
    
    // MARK: - Public Functions
    
    public func updateAppearance(appearance: ViewPagerControllerAppearance) {
        // Header
        self.headerViewHeight = appearance.headerHeight
        self.headerViewHeightConstraint.constant = self.headerViewHeight
        
        self.headerView.subviews.forEach() { $0.removeFromSuperview() }
        if let _contentsView = appearance.headerContentsView {
            self.headerView.addSubview(_contentsView)
            self.headerView.allPin(_contentsView)
        }
        
        // Tab Menu
        self.tabMenuViewHeight = appearance.tabMenuHeight
        self.tabMenuViewHeightConstraint.constant = self.tabMenuViewHeight
        self.tabMenuView.updateAppearance(appearance.tabMenuAppearance)
        
        // ScrollHeaderSupport
        self.scrollViewMinPositionY = appearance.scrollViewMinPositionY
        self.scrollViewObservingType = appearance.scrollViewObservingType
        self.scrollViewObservingDelay = appearance.scrollViewObservingDelay
        
        self.view.layoutIfNeeded()
    }
    
    public func setParentController(controller: UIViewController, parentView: UIView) {
        controller.automaticallyAdjustsScrollViewInsets = false
        controller.addChildViewController(self)
        
        parentView.addSubview(self.view)
        
        self.viewTopConstraint = parentView.addPin(self.view, attribute: .Top, toView: parentView, constant: 0.0)
        parentView.addPin(self.view, attribute: .Bottom, toView: parentView, constant: 0.0)
        parentView.addPin(self.view, attribute: .Left, toView: parentView, constant: 0.0)
        parentView.addPin(self.view, attribute: .Right, toView: parentView, constant: 0.0)
        
        self.didMoveToParentViewController(controller)
    }
    
    public func addContents(title: String, viewController: UIViewController) {
        let identifier = NSUUID().UUIDString
        self.tabMenuView.addTitle(identifier, title: title)
        self.addChildViewController(viewController)
        self.containerView.addViewController(identifier, viewController: viewController)
    }
    
    // MARK: - Private Functions
    
    private func setupConstraint() {
        // Header
        self.view.addPin(self.headerView, attribute: .Top, toView: self.view, constant: 0.0)
        self.headerViewHeightConstraint = self.headerView.addHeightConstraint(self.headerView, constant: self.headerViewHeight)
        self.view.addPin(self.headerView, attribute: .Left, toView: self.view, constant: 0.0)
        self.view.addPin(self.headerView, attribute: .Right, toView: self.view, constant: 0.0)
        
        // Tab Menu
        self.view.addPin(self.tabMenuView, isWithViewTop: true, toView: self.headerView, isToViewTop: false, constant: 0.0)
        self.tabMenuViewHeightConstraint = self.tabMenuView.addHeightConstraint(self.tabMenuView, constant: self.tabMenuViewHeight)
        self.view.addPin(self.tabMenuView, attribute: .Left, toView: self.view, constant: 0.0)
        self.view.addPin(self.tabMenuView, attribute: .Right, toView: self.view, constant: 0.0)
        
        // Container
        self.view.addPin(self.containerView, isWithViewTop: true, toView: self.tabMenuView, isToViewTop: false, constant: 0.0)
        self.view.addPin(self.containerView, attribute: .Bottom, toView: self.view, constant: 0.0)
        self.view.addPin(self.containerView, attribute: .Left, toView: self.view, constant: 0.0)
        self.view.addPin(self.containerView, attribute: .Right, toView: self.view, constant: 0.0)
    }
    
    private func setupHandler() {
        self.tabMenuView.selectedIndexHandler = { [weak self] index in
            self?.containerView.scrollToCenter(index, animated: true, animation: nil, completion: nil)
        }
        
        self.tabMenuView.updateSelectedViewHandler = { [weak self] selectedView in
            self?.updateSelectedViewHandler?(selectedView)
        }
        
        self.tabMenuView.willBeginScrollingHandler = { [weak self] selectedView in
            self?.willBeginTabMenuUserScrollingHandler?(selectedView)
        }
        
        self.tabMenuView.didEndTabMenuScrollingHandler = { [weak self] selectedView in
            self?.didEndTabMenuUserScrollingHandler?(selectedView)
        }
        
        self.containerView.startSyncHandler = { [weak self] index in
            self?.tabMenuView.stopScrolling(index)
        }
        
        self.containerView.syncOffsetHandler = { [weak self] index, percentComplete, scrollingTowards in
            self?.tabMenuView.syncContainerViewScrollTo(index, percentComplete: percentComplete, scrollingTowards: scrollingTowards)
        }
        
        self.containerView.finishSyncHandler = { [weak self] index in
            self?.tabMenuView.finishSyncContainerViewScroll(index)
        }
        
        self.containerView.didShowViewControllerHandler = { [weak self] controller in
            self?.didShowViewControllerHandler?(controller)
            let scrollView = self?.didShowViewControllerObservingHandler?(controller)
            self?.observingScrollView = scrollView
        }
    }
    
    private func startScrollViewContentOffsetObserving() {
        if let _observingScrollView = self.observingScrollView {
            _observingScrollView.addObserver(self, forKeyPath: "contentOffset", options: [.Old, .New], context: nil)
        }
    }
    
    private func stopScrollViewContentOffsetObserving() {
        if let _observingScrollView = self.observingScrollView {
            _observingScrollView.removeObserver(self, forKeyPath: "contentOffset")
        }
    }
}
