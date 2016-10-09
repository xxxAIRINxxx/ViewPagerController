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

    public var selectedIndexHandler : ((Int) -> Void)?
    
    public var updateSelectedViewHandler : ((UIView) -> Void)?
    
    public var willBeginScrollingHandler : ((UIView) -> Void)?
    
    public var didEndTabMenuScrollingHandler : ((UIView) -> Void)?
    
    // MARK: - Custom Settings Properties
    
    // Title Layout
    public fileprivate(set) var titleMargin : CGFloat = 0.0
    public fileprivate(set) var titleMinWidth : CGFloat = 0.0
    
    // Title Color
    public fileprivate(set) var defaultTitleColor : UIColor = UIColor.gray
    public fileprivate(set) var highlightedTitleColor : UIColor = UIColor.white
    public fileprivate(set) var selectedTitleColor : UIColor = UIColor.white
    
    // Title Font
    public fileprivate(set) var defaultTitleFont : UIFont = UIFont.systemFont(ofSize: 14)
    public fileprivate(set) var highlightedTitleFont : UIFont = UIFont.systemFont(ofSize: 14)
    public fileprivate(set) var selectedTitleFont : UIFont = UIFont.boldSystemFont(ofSize: 14)
    
    // Selected View
    public fileprivate(set) var selectedViewBackgroundColor : UIColor = UIColor.clear
    public fileprivate(set) var selectedViewInsets : UIEdgeInsets = UIEdgeInsets.zero
    
    // MARK: - Private Properties
    
    // Views
    fileprivate var selectedView : UIView = UIView(frame: CGRect.zero)
    fileprivate var backgroundView : UIView = UIView(frame: CGRect.zero)
    fileprivate lazy var scrollView : InfiniteScrollView = {
        var scrollView = InfiniteScrollView(frame: self.bounds)
        scrollView.infiniteDataSource = self
        scrollView.infiniteDelegate = self
        scrollView.scrollsToTop = false
        scrollView.backgroundColor = UIColor.clear
        return scrollView
    }()
    
    // Contents
    fileprivate var contents : [String] = []
    
    // Selected View Layout
    fileprivate var selectedViewTopConstraint : NSLayoutConstraint!
    fileprivate var selectedViewBottomConstraint : NSLayoutConstraint!
    fileprivate var selectedViewWidthConstraint : NSLayoutConstraint!
    
    // Sync ContainerView Scrolling
    fileprivate var isSyncContainerViewScrolling : Bool = false
    fileprivate var syncStartIndex : Int = Int.min
    fileprivate var syncNextIndex : Int = Int.min
    fileprivate var syncStartContentOffsetX : CGFloat = CGFloat.leastNormalMagnitude
    fileprivate var syncContentOffsetXDistance : CGFloat = CGFloat.leastNormalMagnitude
    fileprivate var scrollingTowards : Bool = false
    fileprivate var percentComplete: CGFloat = CGFloat.leastNormalMagnitude
    
    // TODO : Workaround : min item infinite scroll
    
    fileprivate var useTitles : [String] = []
    
    fileprivate var contentsRepeatCount : Int {
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
                return Int(ceil(minWidth.truncatingRemainder(dividingBy: totalItemWitdh))) + 1
            }
        }
        set {}
    }
    fileprivate func updateUseContens() {
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
    
    fileprivate func commonInit() {
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
    
    public func updateAppearance(_ appearance: TabMenuAppearance) {
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
    
    public func addTitle(_ title: String) {
        self.contents.append(title)
        self.reload()
    }
    
    public func removeContentAtIndex(_ index: Int) {
        self.contents.remove(at: index)
        self.reload()
    }
    
    public func scrollToCenter(_ index: Int, animated: Bool, animation: ((Void) -> Void)?, completion: ((Void) -> Void)?) {
        self.scrollView.scrollToCenter(index, animated: animated, animation: animation, completion: completion)
    }
    
    public func stopScrolling(_ index: Int) {
        self.scrollView.isScrollEnabled = false
        self.scrollView.setContentOffset(self.scrollView.contentOffset, animated: false)
        self.scrollView.isScrollEnabled = true
        self.scrollView.resetWithIndex(index)
        self.updateSelectedButton(index)
    }
    
    public func reload() {
        self.updateUseContens()
        self.scrollView.resetWithIndex(0)
        self.updateSelectedButton(0)
        self.updateSelectedViewLayout(false)
    }
}

// MARK: - Sync ContainerView Scrolling

extension PagerTabMenuView {
    
    internal func syncContainerViewScrollTo(_ currentIndex: Int, percentComplete: CGFloat, scrollingTowards: Bool) {
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
                    self.scrollView.isUserInteractionEnabled = false
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
    
    internal func finishSyncContainerViewScroll(_ index: Int) {
        self.scrollView.isUserInteractionEnabled = true
        self.isSyncContainerViewScrolling = false
        self.percentComplete = CGFloat.leastNormalMagnitude
        self.updateButtonAttribute()
        
        if let _centerItem = self.scrollView.itemAtIndex(index) {
            self.updateCenterItem(_centerItem, animated: false)
        }
    }
    
    internal func syncOffset(_ percentComplete: CGFloat) {
        if self.percentComplete >= 1.0 { return }
        
        self.percentComplete = percentComplete
        let diff = self.syncContentOffsetXDistance * percentComplete
        let offset = self.scrollingTowards ? self.syncStartContentOffsetX - diff : self.syncStartContentOffsetX + diff
        
        self.scrollView.contentOffset = CGPoint(x: offset, y: 0)
    }
    
    internal func syncSelectedViewWidth(_ percentComplete: CGFloat) {
        guard let _currentItem = self.scrollView.itemAtIndex(self.syncStartIndex),
            let _nextItem = self.scrollView.itemAtIndex(self.syncNextIndex) else { return }
        
        let inset = self.selectedViewInsets.left + self.selectedViewInsets.right
        let currentWidth = _currentItem.thickness - inset
        let nextWidth = _nextItem.thickness - inset
        let diff = nextWidth - currentWidth
        self.selectedViewWidthConstraint.constant = currentWidth + diff * percentComplete
    }
    
    internal func syncButtons(_ percentComplete: CGFloat) {
        guard let _currentItem = self.scrollView.itemAtIndex(self.syncStartIndex),
            let _nextItem = self.scrollView.itemAtIndex(self.syncNextIndex) else { return }
        
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
        
        currentButton.setTitleColor(prevColor, for: UIControlState())
        nextButton.setTitleColor(nextColor, for: UIControlState())
        
        self.syncButtonTitleColor(currentButton, color: prevColor)
        self.syncButtonTitleColor(nextButton, color: nextColor)
    }
    
    internal func syncButtonTitleColor(_ button: UIButton, color: UIColor) {
        button.setButtonTitleAttribute(self.defaultTitleFont, textColor: color, state: UIControlState())
        button.setButtonTitleAttribute(self.highlightedTitleFont, textColor: color, state: .highlighted)
        button.setButtonTitleAttribute(self.selectedTitleFont, textColor: color, state: .selected)
    }
}

// MARK: - Button Customize

extension PagerTabMenuView {
    
    fileprivate func createTitleButton(_ title: String) -> UIButton {
        let button = UIButton(frame: CGRect(x: 0.0, y: 0.0, width: self.titleMinWidth, height: self.frame.height))
        button.isExclusiveTouch = true
        button.setTitle(title, for: UIControlState())
        self.updateButtonTitleAttribute(button)
        button.addTarget(self, action: #selector(PagerTabMenuView.tabMenuButtonTapped(_:)), for: .touchUpInside)
        
        return button
    }
    
    public func tabMenuButtonTapped(_ sender: UIButton) {
        if let _item = self.scrollView.itemAtView(sender) {
            self.updateCenterItem(_item, animated: true)
            self.selectedIndexHandler?(_item.index)
        }
    }
    
    fileprivate func updateButtonAttribute() {
        self.scrollView.subviews.forEach() {
            let button = $0 as! UIButton
            self.updateButtonTitleAttribute(button)
        }
    }
    
    fileprivate func updateButtonTitleAttribute(_ button: UIButton) {
        button.setButtonTitleAttribute(self.defaultTitleFont, textColor: self.defaultTitleColor, state: UIControlState())
        button.setButtonTitleAttribute(self.highlightedTitleFont, textColor: self.highlightedTitleColor, state: .highlighted)
        button.setButtonTitleAttribute(self.selectedTitleFont, textColor: self.selectedTitleColor, state: .selected)
    }
}

extension UIButton {
    
    public func setButtonTitleAttribute(_ font: UIFont, textColor: UIColor, state: UIControlState) {
        guard let _title = self.title(for: UIControlState()) else { return }
        
        self.setAttributedTitle(NSAttributedString(string: _title, attributes:
            [
                NSFontAttributeName: font,
                NSForegroundColorAttributeName: textColor,
            ]
            ), for: state)
    }
}

// MARK: - Layout

extension PagerTabMenuView {
    
    fileprivate func setupConstraint() {
        self.allPin(self.backgroundView)
        self.allPin(self.scrollView)
        
        self.selectedViewTopConstraint = self.addPin(self.selectedView, attribute: .top, toView: self, constant: self.selectedViewInsets.top)
        self.selectedViewBottomConstraint = self.addPin(self.selectedView, attribute: .bottom, toView: self, constant: -self.selectedViewInsets.bottom)
        self.selectedViewWidthConstraint = addConstraint(
            self.selectedView,
            relation: .equal,
            withItem: self.selectedView,
            withAttribute: .width,
            toItem: nil,
            toAttribute: .width,
            constant: self.titleMinWidth
        )
        _ = addConstraint(
            self,
            relation: .equal,
            withItem: self,
            withAttribute: .centerX,
            toItem: self.selectedView,
            toAttribute: .centerX,
            constant: 0
        )
    }
    
    internal func updateSelectedViewLayout(_ animated: Bool) {
        self.updateSelectedViewWidth()
        self.selectedViewTopConstraint.constant = self.selectedViewInsets.top
        self.selectedViewBottomConstraint.constant = -self.selectedViewInsets.bottom
        self.updateSelectedViewHandler?(self.selectedView)
        
        UIView.animate(withDuration: animated ? 0.25 : 0, animations: {
            self.selectedView.layoutIfNeeded()
        })
    }
    
    fileprivate func updateSelectedViewWidth() {
        guard let _centerItem = self.scrollView.itemAtCenterPosition() else { return }
        
        let inset = self.selectedViewInsets.left + self.selectedViewInsets.right
        self.selectedViewWidthConstraint.constant = _centerItem.thickness - inset
    }
    
    fileprivate func updateCenterItem(_ item: InfiniteItem, animated: Bool) {
        self.scrollView.scrollToCenter(item.index, animated: animated, animation: nil, completion: nil)
        self.updateSelectedButton(item.index)
        self.updateSelectedViewLayout(animated)
    }
    
    fileprivate func updateSelectedButton(_ index: Int) {
        self.scrollView.updateItems() {
            let itemButton = $0.view as! UIButton
            itemButton.isSelected = $0.index == index ? true : false
            return $0
        }
    }
}

// MARK: - InfiniteScrollViewDataSource

extension PagerTabMenuView: InfiniteScrollViewDataSource {
    
    public func totalItemCount() -> Int {
        return self.useTitles.count
    }
    
    public func viewForIndex(_ index: Int) -> UIView {
        let title = self.useTitles[index]
        let button = self.createTitleButton(title)
        
        return button
    }
    
    public func thicknessForIndex(_ index: Int) -> CGFloat {
        let title = self.useTitles[index]
        let fontAttr: [String : AnyObject] = [NSFontAttributeName : self.selectedTitleFont]
        var width = NSString(string: title).size(attributes: fontAttr).width
        if width < self.titleMinWidth {
            width = self.titleMinWidth
        }
        return width + self.titleMargin * 2
    }
}

// MARK: - InfiniteScrollViewDelegate

extension PagerTabMenuView: InfiniteScrollViewDelegate {
    
    public func updateContentOffset(_ delta: CGFloat) {
        self.syncStartContentOffsetX += delta
    }
    
    public func infiniteScrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
    }
    
    public func infiniteScrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        guard !self.isSyncContainerViewScrolling else { return }
        
        self.willBeginScrollingHandler?(self.selectedView)
    }
    
    public func infinitScrollViewDidScroll(_ scrollView: UIScrollView) {
    }
    
    public func infiniteScrollViewDidEndCenterScrolling(_ item: InfiniteItem) {
        guard !self.isSyncContainerViewScrolling else { return }
        
        self.updateCenterItem(item, animated: false)
        self.didEndTabMenuScrollingHandler?(self.selectedView)
        self.selectedIndexHandler?(item.index)
    }
    
    public func infiniteScrollViewDidShowCenterItem(_ item: InfiniteItem) {
        guard !self.isSyncContainerViewScrolling else { return }
        
        self.updateCenterItem(item, animated: false)
    }
}
