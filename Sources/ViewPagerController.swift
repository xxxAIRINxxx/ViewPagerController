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
    case none
    case header
    case navigationBar(targetNavigationBar : UINavigationBar)
}

public final class ViewPagerController: UIViewController {
    
    // MARK: - Public Handler Properties
    
    public var didShowViewControllerHandler : ((UIViewController) -> Void)?
    
    public var updateSelectedViewHandler : ((UIView) -> Void)?
    
    public var willBeginTabMenuUserScrollingHandler : ((UIView) -> Void)?
    
    public var didEndTabMenuUserScrollingHandler : ((UIView) -> Void)?
    
    public var didChangeHeaderViewHeightHandler : ((CGFloat) -> Void)?
    
    public var changeObserveScrollViewHandler : ((UIViewController) -> UIScrollView?)?
    
    public var didScrollContentHandler : ((CGFloat) -> Void)?
    
    // MARK: - Custom Settings Properties
    
    public fileprivate(set) var headerViewHeight : CGFloat = 0.0
    public fileprivate(set) var tabMenuViewHeight : CGFloat = 0.0
    
    // ScrollHeaderSupport
    public fileprivate(set) var scrollViewMinPositionY : CGFloat = 0.0
    public fileprivate(set) var scrollViewObservingDelay : CGFloat = 0.0
    public fileprivate(set) var scrollViewObservingType : ObservingScrollViewType = .none {
        didSet {
            switch self.scrollViewObservingType {
            case .header:
                self.targetNavigationBar = nil
            case .navigationBar(let targetNavigationBar):
                self.targetNavigationBar = targetNavigationBar
            case .none:
                self.targetNavigationBar = nil
                self.observingScrollView = nil
            }
        }
    }
    
    // MARK: - Private Properties
    
    internal var headerView : UIView = UIView(frame: CGRect.zero)
    
    internal var tabMenuView : PagerTabMenuView = PagerTabMenuView(frame: CGRect.zero)
    
    internal var containerView : PagerContainerView = PagerContainerView(frame: CGRect.zero)
    
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
        self.scrollViewObservingType = .none
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
    
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.tabMenuView.stopScrolling(self.containerView.currentIndex() ?? 0)
        self.didEndTabMenuUserScrollingHandler?(self.tabMenuView.getSelectedView())
        self.tabMenuView.updateSelectedViewLayout(false)
    }
    
    // MARK: - Public Functions
    
    public func updateAppearance(_ appearance: ViewPagerControllerAppearance) {
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
    
    public func setParentController(_ controller: UIViewController, parentView: UIView) {
        controller.automaticallyAdjustsScrollViewInsets = false
        controller.addChildViewController(self)
        
        parentView.addSubview(self.view)
        
        self.viewTopConstraint = parentView.addPin(self.view, attribute: .top, toView: parentView, constant: 0.0)
        _ = parentView.addPin(self.view, attribute: .bottom, toView: parentView, constant: 0.0)
        _ = parentView.addPin(self.view, attribute: .left, toView: parentView, constant: 0.0)
        _ = parentView.addPin(self.view, attribute: .right, toView: parentView, constant: 0.0)
        
        self.didMove(toParentViewController: controller)
    }
    
    public func addContent(_ title: String, viewController: UIViewController) {
        self.tabMenuView.addTitle(title)
        self.addChildViewController(viewController)
        self.containerView.addViewController(viewController)
    }
    
    public func removeContent(_ viewController: UIViewController) {
        guard let index = self.containerView.indexFromViewController(viewController) else { return }
        
        if self.childViewControllers.contains(viewController) {
            viewController.willMove(toParentViewController: nil)
            
            self.tabMenuView.removeContentAtIndex(index)
            self.containerView.removeContent(viewController)
            
            viewController.removeFromParentViewController()
        }
    }
    
    public func currentContent() -> UIViewController? {
        return self.containerView.currentContent()
    }
  
    // MARK: - Private Functions
    
    fileprivate func setupConstraint() {
        // Header
        _ = self.view.addPin(self.headerView, attribute: .top, toView: self.view, constant: 0.0)
        self.headerViewHeightConstraint = self.headerView.addHeightConstraint(self.headerView, constant: self.headerViewHeight)
        _ = self.view.addPin(self.headerView, attribute: .left, toView: self.view, constant: 0.0)
        _ = self.view.addPin(self.headerView, attribute: .right, toView: self.view, constant: 0.0)
        
        // Tab Menu
        _ = self.view.addPin(self.tabMenuView, isWithViewTop: true, toView: self.headerView, isToViewTop: false, constant: 0.0)
        self.tabMenuViewHeightConstraint = self.tabMenuView.addHeightConstraint(self.tabMenuView, constant: self.tabMenuViewHeight)
        _ = self.view.addPin(self.tabMenuView, attribute: .left, toView: self.view, constant: 0.0)
        _ = self.view.addPin(self.tabMenuView, attribute: .right, toView: self.view, constant: 0.0)
        
        // Container
        _ = self.view.addPin(self.containerView, isWithViewTop: true, toView: self.tabMenuView, isToViewTop: false, constant: 0.0)
        _ = self.view.addPin(self.containerView, attribute: .bottom, toView: self.view, constant: 0.0)
        _ = self.view.addPin(self.containerView, attribute: .left, toView: self.view, constant: 0.0)
        _ = self.view.addPin(self.containerView, attribute: .right, toView: self.view, constant: 0.0)
    }
    
    fileprivate func setupHandler() {
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
            self?.didScrollContentHandler?(percentComplete)
        }
        
        self.containerView.finishSyncHandler = { [weak self] index in
            self?.tabMenuView.finishSyncContainerViewScroll(index)
        }
        
        self.containerView.didShowViewControllerHandler = { [weak self] controller in
            self?.didShowViewControllerHandler?(controller)
            let scrollView = self?.changeObserveScrollViewHandler?(controller)
            self?.observingScrollView = scrollView
        }
    }
    
    fileprivate func startScrollViewContentOffsetObserving() {
        if let _observingScrollView = self.observingScrollView {
            _observingScrollView.addObserver(self, forKeyPath: "contentOffset", options: [.old, .new], context: nil)
        }
    }
    
    fileprivate func stopScrollViewContentOffsetObserving() {
        if let _observingScrollView = self.observingScrollView {
            _observingScrollView.removeObserver(self, forKeyPath: "contentOffset")
        }
    }
}
