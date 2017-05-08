//
//  ViewController.swift
//  MXPressButtonDemo
//
//  Created by Ashbringer on 5/4/17.
//  Copyright © 2017 wintface.com. All rights reserved.
//

import UIKit

class ViewController: UIViewController {

    private lazy var pressButton: MXPressButton = {
//        let button = MXPressButton(frame: CGRect(x: 0, y: 0, width: 120, height: 120))
        let button = MXPressButton()
        button.frame = CGRect(x: 0, y: 0, width: 120, height: 120)
        
        button.center = self.view.center
        
        return button
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view, typically from a nib.
        
        self.view.backgroundColor = UIColor(white: 0.0, alpha: 1)
        self.view.addSubview(self.pressButton)
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }


}

