//
//  PagerTabMenuView.swift
//  ViewPagerController
//
//  Created by xxxAIRINxxx on 2016/01/05.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//

import Foundation
import UIKit

public final class PagerTabMenuView: UIView {
    
    // MARK: - Public Handler Properties

    public var selectedIndexHandler : (Int -> Void)?
    
    public var updateSelectedViewHandler : (UIView -> Void)?
    
    public var willBeginScrollingHandler : (UIView -> Void)?
    
    public var didEndTabMenuScrollingHandler : (UIView -> Void)?
    
    // MARK: - Custom Settings Properties
    
    // Title Layout
    public private(set) var titleMargin : CGFloat = 0.0
    public private(set) var titleMinWidth : CGFloat = 0.0
    
    // Title Color
    public private(set) var defaultTitleColor : UIColor = UIColor.grayColor()
    public private(set) var highlightedTitleColor : UIColor = UIColor.whiteColor()
    public private(set) var selectedTitleColor : UIColor = UIColor.whiteColor()
    
    // Title Font
    public private(set) var defaultTitleFont : UIFont = UIFont.systemFontOfSize(14)
    public private(set) var highlightedTitleFont : UIFont = UIFont.systemFontOfSize(14)
    public private(set) var selectedTitleFont : UIFont = UIFont.boldSystemFontOfSize(14)
    
    // Selected View
    public private(set) var selectedViewBackgroundColor : UIColor = UIColor.clearColor()
    public private(set) var selectedViewInsets : UIEdgeInsets = UIEdgeInsetsZero
    
    // MARK: - Private Properties
    
    // Views
    private var selectedView : UIView = UIView(frame: CGRect.zero)
    private var backgroundView : UIView = UIView(frame: CGRect.zero)
    private lazy var scrollView : InfiniteScrollView = {
        var scrollView = InfiniteScrollView(frame: self.bounds)
        scrollView.infiniteDataSource = self
        scrollView.infiniteDelegate = self
        scrollView.scrollsToTop = false
        scrollView.backgroundColor = UIColor.clearColor()
        return scrollView
    }()
    
    // Contents
    private var contents : [String] = []
    
    // Selected View Layout
    private var selectedViewTopConstraint : NSLayoutConstraint!
    private var selectedViewBottomConstraint : NSLayoutConstraint!
    private var selectedViewWidthConstraint : NSLayoutConstraint!
    
    // Sync ContainerView Scrolling
    private var isSyncContainerViewScrolling : Bool = false
    private var syncStartIndex : Int = Int.min
    private var syncNextIndex : Int = Int.min
    private var syncStartContentOffsetX : CGFloat = CGFloat.min
    private var syncContentOffsetXDistance : CGFloat = CGFloat.min
    private var scrollingTowards : Bool = false
    private var percentComplete: CGFloat = CGFloat.min
    
    // TODO : Workaround : min item infinite scroll
    
    private var useTitles : [String] = []
    
    private var contentsRepeatCount : Int {
        get {
            let minWidth = self.bounds.size.width * 2
            let totalItemCount = self.totalItemCount()
            var totalItemWitdh: CGFloat = 0.0
            for index in 0..<totalItemCount {
                totalItemWitdh += self.thicknessForIndex(index)
            }
            
            if totalItemWitdh == 0 {
                return 0
            } else if minWidth < totalItemWitdh {
                return 0
            } else {
                return Int(ceil(minWidth % totalItemWitdh)) + 1
            }
        }
        set {}
    }
    private func updateUseContens() {
        let contentsRepeatCount = self.contentsRepeatCount
        if contentsRepeatCount == 0 {
            self.useTitles = self.contents
        } else {
            var tmpTitles: [String] = []
            var tmpIdentifiers: [String] = []
            for _ in 0..<contentsRepeatCount {
                self.contents.forEach(){ tmpIdentifiers.append($0) }
                self.contents.forEach(){ tmpTitles.append($0) }
            }
            self.useTitles = tmpTitles
        }
    }
    
    // MARK: - Constructor
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.commonInit()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.commonInit()
    }
    
    private func commonInit() {
        self.addSubview(self.backgroundView)
        self.addSubview(self.selectedView)
        self.addSubview(self.scrollView)
        
        self.setupConstraint()
    }
    
    // MARK: - Override
    
    override public func layoutSubviews() {
        super.layoutSubviews()
        self.scrollView.frame = self.bounds
    }
    
    // MARK: - Public Functions
    
    public func getSelectedView() -> UIView {
        return self.selectedView
    }
    
    public func updateAppearance(appearance: TabMenuAppearance) {
        self.backgroundColor = appearance.backgroundColor
        
        // Title Layout
        self.titleMargin = appearance.titleMargin
        self.titleMinWidth = appearance.titleMinWidth
        
        // Title Color
        self.defaultTitleColor = appearance.defaultTitleColor
        self.highlightedTitleColor = appearance.highlightedTitleColor
        self.selectedTitleColor = appearance.selectedTitleColor
        
        // Title Font
        self.defaultTitleFont = appearance.defaultTitleFont
        self.highlightedTitleFont = appearance.highlightedTitleFont
        self.selectedTitleFont = appearance.selectedTitleFont
        
        // Selected View
        self.selectedViewBackgroundColor = appearance.selectedViewBackgroundColor
        self.selectedView.backgroundColor = self.selectedViewBackgroundColor
        self.selectedViewInsets = appearance.selectedViewInsets
        
        self.backgroundView.subviews.forEach() { $0.removeFromSuperview() }
        if let _contentsView = appearance.backgroundContentsView {
            self.backgroundView.addSubview(_contentsView)
            self.backgroundView.allPin(_contentsView)
        }
        
        self.updateSelectedViewLayout(false)
        self.updateButtonAttribute()
        self.scrollView.reloadViews()
    }
    
    public func addTitle(title: String) {
        self.contents.append(title)
        self.reload()
    }
    
    public func removeContentAtIndex(index: Int) {
        self.contents.removeAtIndex(index)
        self.scrollView.reset()
        self.reload()
    }
    
    public func scrollToCenter(index: Int, animated: Bool, animation: (Void -> Void)?, completion: (Void -> Void)?) {
        self.scrollView.scrollToCenter(index, animated: animated, animation: animation, completion: completion)
    }
    
    public func stopScrolling(index: Int) {
        self.scrollView.scrollEnabled = false
        self.scrollView.setContentOffset(self.scrollView.contentOffset, animated: false)
        self.scrollView.scrollEnabled = true
        self.scrollView.resetWithIndex(index)
        self.updateSelectedButton(index)
    }
    
    public func reload() {
        self.updateUseContens()
        self.scrollView.reloadViews()
        
        self.scrollView.resetWithIndex(0)
        self.updateSelectedViewLayout(false)
    }
}

// MARK: - Sync ContainerView Scrolling

extension PagerTabMenuView {
    
    internal func syncContainerViewScrollTo(currentIndex: Int, percentComplete: CGFloat, scrollingTowards: Bool) {
        if self.isSyncContainerViewScrolling {
            self.scrollingTowards = scrollingTowards
            
            self.syncOffset(percentComplete)
            self.syncSelectedViewWidth(percentComplete)
            self.syncButtons(percentComplete)
        } else {
            self.scrollView.scrollToCenter(currentIndex, animated: false, animation: nil, completion: nil)
            if let _currentItem = self.scrollView.itemAtCenterPosition() {
                let nextItem = self.scrollView.itemAtIndex(_currentItem.index + (scrollingTowards ? -1 : 1))
                
                if let _nextItem = nextItem {
                    self.scrollView.userInteractionEnabled = false
                    self.isSyncContainerViewScrolling = true
                    self.syncStartIndex = _currentItem.index
                    self.syncNextIndex = _nextItem.index
                    self.syncStartContentOffsetX = self.scrollView.contentOffset.x
                    let startOffsetX = _currentItem.view.frame.midX
                    let endOffsetX = _nextItem.view.frame.midX
                    self.scrollingTowards = scrollingTowards
                    self.syncContentOffsetXDistance = scrollingTowards ? startOffsetX - endOffsetX : endOffsetX - startOffsetX
                }
            }
        }
    }
    
    internal func finishSyncContainerViewScroll(index: Int) {
        self.scrollView.userInteractionEnabled = true
        self.isSyncContainerViewScrolling = false
        self.percentComplete = CGFloat.min
        self.updateButtonAttribute()
        
        if let _centerItem = self.scrollView.itemAtIndex(index) {
            self.updateCenterItem(_centerItem)
        }
    }
    
    internal func syncOffset(percentComplete: CGFloat) {
        if self.percentComplete >= 1.0 { return }
        
        self.percentComplete = percentComplete
        let diff = self.syncContentOffsetXDistance * percentComplete
        let offset = self.scrollingTowards ? self.syncStartContentOffsetX - diff : self.syncStartContentOffsetX + diff
        
        self.scrollView.contentOffset = CGPoint(x: offset, y: 0)
    }
    
    internal func syncSelectedViewWidth(percentComplete: CGFloat) {
        guard let _currentItem = self.scrollView.itemAtIndex(self.syncStartIndex),
            _nextItem = self.scrollView.itemAtIndex(self.syncNextIndex) else { return }
        
        let inset = self.selectedViewInsets.left + self.selectedViewInsets.right
        let currentWidth = _currentItem.thickness - inset
        let nextWidth = _nextItem.thickness - inset
        let diff = nextWidth - currentWidth
        self.selectedViewWidthConstraint.constant = currentWidth + diff * percentComplete
    }
    
    internal func syncButtons(percentComplete: CGFloat) {
        guard let _currentItem = self.scrollView.itemAtIndex(self.syncStartIndex),
            _nextItem = self.scrollView.itemAtIndex(self.syncNextIndex) else { return }
        
        let normal = self.defaultTitleColor.getRGBAStruct()
        let selected = self.selectedTitleColor.getRGBAStruct()
        
        let absRatio = fabs(percentComplete)
        
        let prevColor = UIColor(
            red: normal.red * absRatio + selected.red * (1.0 - absRatio),
            green: normal.green * absRatio + selected.green * (1.0 - absRatio),
            blue: normal.blue * absRatio + selected.blue * (1.0 - absRatio),
            alpha: normal.alpha * absRatio + selected.alpha * (1.0 - absRatio)
        )
        let nextColor = UIColor(
            red: normal.red * (1.0 - absRatio) + selected.red * absRatio,
            green: normal.green * (1.0 - absRatio) + selected.green * absRatio,
            blue: normal.blue * (1.0 - absRatio) + selected.blue * absRatio,
            alpha: normal.alpha * (1.0 - absRatio) + selected.alpha * absRatio
        )
        let currentButton = _currentItem.view as! UIButton
        let nextButton = _nextItem.view as! UIButton
        
        currentButton.setTitleColor(prevColor, forState: .Normal)
        nextButton.setTitleColor(nextColor, forState: .Normal)
        
        self.syncButtonTitleColor(currentButton, color: prevColor)
        self.syncButtonTitleColor(nextButton, color: nextColor)
    }
    
    internal func syncButtonTitleColor(button: UIButton, color: UIColor) {
        button.setButtonTitleAttribute(self.defaultTitleFont, textColor: color, state: .Normal)
        button.setButtonTitleAttribute(self.highlightedTitleFont, textColor: color, state: .Highlighted)
        button.setButtonTitleAttribute(self.selectedTitleFont, textColor: color, state: .Selected)
    }
}

// MARK: - Button Customize

extension PagerTabMenuView {
    
    private func createTitleButton(title: String) -> UIButton {
        let button = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: self.titleMinWidth, height: self.frame.height))
        button.exclusiveTouch = true
        button.setTitle(title, forState: .Normal)
        self.updateButtonTitleAttribute(button)
        button.addTarget(self, action: #selector(PagerTabMenuView.tabMenuButtonTapped(_:)), forControlEvents: .TouchUpInside)
        
        return button
    }
    
    public func tabMenuButtonTapped(sender: UIButton) {
        if let _item = self.scrollView.itemAtView(sender) {
            self.updateCenterItem(_item)
            self.selectedIndexHandler?(_item.index)
        }
    }
    
    private func updateButtonAttribute() {
        self.scrollView.subviews.forEach() {
            let button = $0 as! UIButton
            self.updateButtonTitleAttribute(button)
        }
    }
    
    private func updateButtonTitleAttribute(button: UIButton) {
        button.setButtonTitleAttribute(self.defaultTitleFont, textColor: self.defaultTitleColor, state: .Normal)
        button.setButtonTitleAttribute(self.highlightedTitleFont, textColor: self.highlightedTitleColor, state: .Highlighted)
        button.setButtonTitleAttribute(self.selectedTitleFont, textColor: self.selectedTitleColor, state: .Selected)
    }
}

extension UIButton {
    
    public func setButtonTitleAttribute(font: UIFont, textColor: UIColor, state: UIControlState) {
        guard let _title = self.titleForState(.Normal) else { return }
        
        self.setAttributedTitle(NSAttributedString(string: _title, attributes:
            [
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: textColor,
            ]
            ), forState: state)
    }
}

// MARK: - Layout

extension PagerTabMenuView {
    
    private func setupConstraint() {
        self.allPin(self.backgroundView)
        self.allPin(self.scrollView)
        
        self.selectedViewTopConstraint = self.addPin(self.selectedView, attribute: .Top, toView: self, constant: self.selectedViewInsets.top)
        self.selectedViewBottomConstraint = self.addPin(self.selectedView, attribute: .Bottom, toView: self, constant: -self.selectedViewInsets.bottom)
        self.selectedViewWidthConstraint = addConstraint(
            self.selectedView,
            relation: .Equal,
            withItem: self.selectedView,
            withAttribute: .Width,
            toItem: nil,
            toAttribute: .Width,
            constant: self.titleMinWidth
        )
        addConstraint(
            self,
            relation: .Equal,
            withItem: self,
            withAttribute: .CenterX,
            toItem: self.selectedView,
            toAttribute: .CenterX,
            constant: 0
        )
    }
    
    internal func updateSelectedViewLayout(animated: Bool) {
        self.updateSelectedViewWidth()
        self.selectedViewTopConstraint.constant = self.selectedViewInsets.top
        self.selectedViewBottomConstraint.constant = -self.selectedViewInsets.bottom
        self.updateSelectedViewHandler?(self.selectedView)
        
        UIView.animateWithDuration(animated ? 0.25 : 0, animations: {
            self.selectedView.layoutIfNeeded()
        })
    }
    
    private func updateSelectedViewWidth() {
        guard let _centerItem = self.scrollView.itemAtCenterPosition() else { return }
        
        let inset = self.selectedViewInsets.left + self.selectedViewInsets.right
        self.selectedViewWidthConstraint.constant = _centerItem.thickness - inset
    }
    
    private func updateCenterItem(item: InfiniteItem) {
        self.scrollView.scrollToCenter(item.index, animated: true, animation: nil, completion: nil)
        self.scrollView.resetWithIndex(item.index)
        self.updateSelectedButton(item.index)
        self.updateSelectedViewLayout(true)
    }
    
    private func updateSelectedButton(index: Int) {
        self.scrollView.updateItems() {
            let itemButton = $0.view as! UIButton
            itemButton.selected = $0.index == index ? true : false
            return $0
        }
    }
}

// MARK: - InfiniteScrollViewDataSource

extension PagerTabMenuView: InfiniteScrollViewDataSource {
    
    public func totalItemCount() -> Int {
        return self.useTitles.count
    }
    
    public func viewForIndex(index: Int) -> UIView {
        let title = self.useTitles[index]
        let button = self.createTitleButton(title)
        
        return button
    }
    
    public func thicknessForIndex(index: Int) -> CGFloat {
        let title = self.useTitles[index]
        let fontAttr: [String : AnyObject] = [NSFontAttributeName : self.selectedTitleFont]
        var width = NSString(string: title).sizeWithAttributes(fontAttr).width
        if width < self.titleMinWidth {
            width = self.titleMinWidth
        }
        return width + self.titleMargin * 2
    }
}

// MARK: - InfiniteScrollViewDelegate

extension PagerTabMenuView: InfiniteScrollViewDelegate {
    
    public func updateContentOffset(delta: CGFloat) {
        self.syncStartContentOffsetX += delta
    }
    
    public func infiniteScrollViewWillBeginDecelerating(scrollView: UIScrollView) {
    }
    
    public func infiniteScrollViewWillBeginDragging(scrollView: UIScrollView) {
        guard !self.isSyncContainerViewScrolling else { return }
        
        self.willBeginScrollingHandler?(self.selectedView)
    }
    
    public func infinitScrollViewDidScroll(scrollView: UIScrollView) {
    }
    
    public func infiniteScrollViewDidEndCenterScrolling(item: InfiniteItem) {
        guard !self.isSyncContainerViewScrolling else { return }
        
        self.updateCenterItem(item)
        self.didEndTabMenuScrollingHandler?(self.selectedView)
        self.selectedIndexHandler?(item.index)
    }
    
    public func infiniteScrollViewDidShowCenterItem(item: InfiniteItem) {
        guard !self.isSyncContainerViewScrolling else { return }
        
        self.updateCenterItem(item)
    }
}