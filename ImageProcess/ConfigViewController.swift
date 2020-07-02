//
//  ConfigViewController.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/2.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import UIKit

class ConfiViewController: UIViewController {
    @IBOutlet weak var stepepr: UIStepper!
    
    private var oldStepper: Double = 100
    
    @IBAction func stepperChanged(_ sender: Any) {
        let value = stepepr.value
        
        _ = value > oldStepper ? ProcesserBinder.shared.processer?.lighten(by: 5) : ProcesserBinder.shared.processer?.darken(by: 5)
        oldStepper = value
    }
    @IBAction func gray(_ sender: Any) {
       _ = ProcesserBinder.shared.processer?.gray()
    }
}
