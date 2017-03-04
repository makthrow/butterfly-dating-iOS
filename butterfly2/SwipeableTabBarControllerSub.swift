//
//  SwipeableTabBarControllerSub.swift
//  butterfly2
//
//  Created by Alan Jaw on 3/4/17.
//  Copyright © 2017 Alan Jaw. All rights reserved.
//

import SwipeableTabBarController

class SwipeableTabBarControllerSub: SwipeableTabBarController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        selectedViewController = viewControllers?[1]
    }
}
