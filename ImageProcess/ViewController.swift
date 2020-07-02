//
//  ViewController.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/1.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import UIKit

class ViewController: UIViewController {
    private var imageView: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        imageView = UIImageView()
        imageView.frame = view.bounds
        imageView.contentMode = .scaleAspectFit
        imageView.center = view.center
        view.addSubview(imageView)
        loadImage()
    }
    
    func loadImage() {
        guard let img = UIImage.loadFromBundle(name: "color", type: "jpg") else {
            return
        }
        ProcesserBinder.shared.image = img
        ProcesserBinder.shared.bind(imageView: imageView)
    }
    
    
}

