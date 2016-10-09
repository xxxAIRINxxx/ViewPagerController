//
//  StartViewController.swift
//  Demo
//
//  Created by xxxAIRINxxx on 2016/01/05.
//  Copyright © 2016 xxxAIRINxxx. All rights reserved.
//

import UIKit

class StartViewController: UITableViewController {
    
    // MARK: - UITableViewDataSource
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 2
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if (indexPath as NSIndexPath).row == 0 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath) 
            return cell
        }
        if (indexPath as NSIndexPath).row == 1 {
            let cell = tableView.dequeueReusableCell(withIdentifier: "Cell2", for: indexPath) 
            return cell
        }
        
        return UITableViewCell()
    }
}
