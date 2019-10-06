//
//  NavSampleViewController.swift
//  Demo
//
//  Created by xxxAIRINxxx on 2016/01/05.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//

import UIKit
import ViewPagerController

class NavSampleViewController : UIViewController {
    
    @IBOutlet weak var layerView : UIView!
    
    var pagerController : ViewPagerController?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pagerController = ViewPagerController()
        pagerController.setParentController(self, parentView: self.layerView)
        
        var appearance = ViewPagerControllerAppearance()
        
        appearance.tabMenuHeight = 44.0
        appearance.scrollViewMinPositionY = 20.0
        appearance.scrollViewObservingType = .navigationBar(targetNavigationBar: self.navigationController!.navigationBar)
        
        appearance.tabMenuAppearance.backgroundColor = UIColor.darkGray
        appearance.tabMenuAppearance.selectedViewBackgroundColor = UIColor.blue
        appearance.tabMenuAppearance.selectedViewInsets = UIEdgeInsets(top: 39, left: 0, bottom: 0, right: 0)
        
        pagerController.updateAppearance(appearance)
        
        pagerController.willBeginTabMenuUserScrollingHandler = { selectedView in
            selectedView.alpha = 0.0
        }
        
        pagerController.didEndTabMenuUserScrollingHandler = { selectedView in
            selectedView.alpha = 1.0
        }
        
        pagerController.changeObserveScrollViewHandler = { controller in
            let detailController = controller as! DetailViewController
            
            return detailController.tableView
        }
        
        pagerController.didChangeHeaderViewHeightHandler = { height in
            print("call didShowViewControllerHandler : \(height)")
        }
        
        for title in sampleDataTitles {
            let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewController(withIdentifier: "DetailViewController") as! DetailViewController
            controller.view.clipsToBounds = true
            controller.title = title
            controller.parentController = self
            pagerController.addContent(title, viewController: controller)
        }
        
        self.pagerController = pagerController
        
        self.navigationItem.rightBarButtonItem = UIBarButtonItem(title: "remove", style: .plain, target: self, action: #selector(NavSampleViewController.remove))
    }
    
    @objc fileprivate func remove() {
        guard let c = self.pagerController?.children.first else { return }
        self.pagerController?.removeContent(c)
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        self.pagerController?.resetNavigationBarHeight(true)
    }
}
