//
//  ViewController.swift
//  ViewPagerController
//
//  Created by xxxAIRINxxx on 2016/01/05.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    
    @IBOutlet weak var layerView : UIView!
    
    var pagerController : ViewPagerController?

    override func viewDidLoad() {
        super.viewDidLoad()
        
        let pagerController = ViewPagerController()
        pagerController.setParentController(self, parentView: self.layerView)
        
        var appearance = ViewPagerControllerAppearance()
        
        appearance.headerHeight = 200.0
        appearance.scrollViewMinPositionY = 20.0
        appearance.scrollViewObservingType = .Header
        
        let imageView = UIImageView(image: UIImage(named: "sample_header_image.jpg"))
        imageView.contentMode = .ScaleAspectFill
        imageView.clipsToBounds = true
        appearance.headerContentsView = imageView
        
        appearance.tabMenuAppearance.selectedViewBackgroundColor = UIColor.greenColor()
        appearance.tabMenuAppearance.selectedViewInsets = UIEdgeInsetsMake(10, 5, 10, 5)
        
        pagerController.updateAppearance(appearance)
        
        pagerController.updateSelectedViewHandler = { selectedView in
            selectedView.layer.cornerRadius = selectedView.frame.size.height * 0.5
        }
               
        pagerController.willBeginTabMenuUserScrollingHandler = { selectedView in
            print("call willBeginTabMenuUserScrollingHandler")
            selectedView.alpha = 0.0
        }
        
        pagerController.didEndTabMenuUserScrollingHandler = { selectedView in
            print("call didEndTabMenuUserScrollingHandler")
            selectedView.alpha = 1.0
        }
        
        pagerController.didShowViewControllerHandler = { controller in
            print("call didShowViewControllerHandler")
            print("controller : \(controller.title)")
            let currentController = pagerController.currentContent()
            print("currentContent : \(currentController?.title)")
        }
        
        pagerController.didShowViewControllerObservingHandler = { controller in
            print("call didShowViewControllerObservingHandler")
            let detailController = controller as! DetailViewController
            
            return detailController.tableView
        }
        
        pagerController.didChangeHeaderViewHeightHandler = { height in
            print("call didChangeHeaderViewHeightHandler : \(height)")
        }
        
        pagerController.didScrollContentHandler = { percentComplete in
            print("call didScrollContentHandler : \(percentComplete)")
        }
        
        for title in sampleDataTitles {
            let controller = UIStoryboard(name: "Main", bundle: nil).instantiateViewControllerWithIdentifier("DetailViewController") as! DetailViewController
            controller.view.clipsToBounds = true
            controller.title = title
            controller.parentController = self
            pagerController.addContent(title, viewController: controller)
        }
        
        self.pagerController = pagerController
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.navigationController?.navigationBarHidden = true
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
        self.navigationController?.navigationBarHidden = false
    }
}

