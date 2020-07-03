//
//  ImageBinder.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/2.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import UIKit

class ProcesserBinder {
    
    static let shared = ProcesserBinder()
    
    private var _image: UIImage?
    
    var image: UIImage? {
        set {
            _image = newValue
            if let cgimage = newValue?.cgImage {
                processer = ImageProcesser(image: cgimage)
            }
            if let view = imageView {
                view.image = image
            }
        }
        get {
            return _image
        }
    }
    
    private var imageView: UIImageView?
    
    private(set) var processer: ImageProcesser?
    
    init() {
        NotificationCenter.default.addObserver(forName: imageChangeNotification, object: nil, queue: OperationQueue.main) { _ in
            self.updateImageView()
        }
    }
    
    private func updateImageView() {
        if let img = processer?.image {
            let newImage = UIImage(cgImage: img)
            imageView?.image = newImage
        }
        
    }
    
    func bind(imageView: UIImageView) {
        self.imageView = imageView
        imageView.image = image
    }
    
    func reset() {
        self.image = _image
    }
    
    
}
