//
//  ImageProcesser.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/2.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import UIKit
import Accelerate

protocol Processer {
    func process(image: CGImage) -> CGImage
    
    func processImageData(data: UnsafeMutablePointer<UInt8>, bytesPerPixs: Int)
}


//class garyProcesser: Processer {
//    func process(image: CGImage) -> CGImage {
//        return image
//    }
//}

let imageChangeNotification = Notification.Name.init("processer-image")

class ImageProcesser {
    
    private(set) var image: CGImage
    private(set) var width: Int = 0
    private(set) var height: Int = 0
    
    private var context: CGContext?
    private var data: UnsafeMutablePointer<UInt32>?
    
    deinit {
        data?.deallocate()
    }
    
    init(image: CGImage) {
        self.image = image
        self.width = image.width
        self.height = image.height
        setupContext()
    }
    
    private func setupContext() {
        let uint32Size = MemoryLayout<UInt32>.size
        data = UnsafeMutablePointer<UInt32>.allocate(capacity: width * height)
        context = CGContext.init(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * uint32Size, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.order32Little.rawValue)
        assert(context != nil, "make context fail")
        context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
    }
    
    func iter(block: (UnsafeMutablePointer<UInt8>) -> Void) -> CGImage {
        guard let data = data else {
            return image
        }
        for row in 0..<height {
            for column in 0..<width {
                let rgba = data.advanced(by: row * width + column)
                let rgb = unsafeBitCast(rgba, to: UnsafeMutablePointer<UInt8>.self)
                block(rgb)
            }
        }
        guard let newImage = context?.makeImage() else {
            return image
        }
        image = newImage
        NotificationCenter.default.post(name: imageChangeNotification, object: nil)
        return newImage
    }
    
    
    func scale(x: Float, y: Float) -> CGImage {
        return image
    }
    
    func gray() -> CGImage {
        return iter { (ptr) in
            let gray = UInt8(0.3  * Double(ptr[3]) + 0.59 * Double(ptr[2]) + 0.11 * Double(ptr[1]))
            ptr[3] = gray
            ptr[2] = gray
            ptr[1] = gray
        }
    }
    
    func lighten(by offset: UInt8) -> CGImage {
        return iter { (ptr) in
            ptr[1] = 255 - ptr[1] < offset ? 255 : ptr[1] + offset
            ptr[2] = 255 - ptr[2] < offset ? 255 : ptr[2] + offset
            ptr[3] = 255 - ptr[3] < offset ? 255 : ptr[3] + offset
        }
    }
    func darken(by offset: UInt8) -> CGImage {
        return iter { (ptr) in
            ptr[1] = ptr[1] < offset ? 0 : ptr[1] - offset
            ptr[2] = ptr[2] < offset ? 0 : ptr[2] - offset
            ptr[3] = ptr[3] < offset ? 0 : ptr[3] - offset
        }
    }
    
    func blur() {
        
    }
    
}
