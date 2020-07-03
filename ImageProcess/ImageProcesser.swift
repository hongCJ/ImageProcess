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



let imageChangeNotification = Notification.Name.init("processer-image")

class ImageProcesser {
     var image: CGImage {
        didSet {
            NotificationCenter.default.post(name: imageChangeNotification, object: nil)
        }
    }
//    private(set) var width: Int = 0
//    private(set) var height: Int = 0
//
//    private var context: CGContext?
//    private var data: UnsafeMutablePointer<UInt32>?
    
    var sourceBuffer: vImage_Buffer?
    var sourceFormat: vImage_CGImageFormat?
    
    deinit {
//        data?.deallocate()
        sourceBuffer?.free()
    }
    
    init(image: CGImage) {
        self.image = image
//        self.width = image.width
//        self.height = image.height
//        setupContext()
        sourceFormat = vImage_CGImageFormat(cgImage: image)
        if let format = sourceFormat {
            sourceBuffer = try? vImage_Buffer(cgImage: image, format: format)
        }
    }
    
//    private func setupContext() {
//        let uint32Size = MemoryLayout<UInt32>.size
//        data = UnsafeMutablePointer<UInt32>.allocate(capacity: width * height)
//        context = CGContext.init(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * uint32Size, space: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.order32Little.rawValue)
//        assert(context != nil, "make context fail")
//        context?.draw(image, in: CGRect(x: 0, y: 0, width: width, height: height))
//    }
    
    func iter(block: (UnsafeMutablePointer<UInt8>) -> Void) {
//        guard let buffer = sourceBuffer else {
//            return
//        }
//        let width = buffer.width
//        let height = buffer.height
//        let data = buffer.data
//
//        for row in 0..<height {
//            for column in 0..<width {
//                let rgba = data.advanced(by: row * width + column)
//                let rgb = unsafeBitCast(rgba, to: UnsafeMutablePointer<UInt8>.self)
//                block(rgb)
//            }
//        }
//        guard let newImage = context?.makeImage() else {
//            return
//        }
//        image = newImage
    }
    
    
//    func scale(x: Float, y: Float) -> CGImage {
//        return image
//    }
    
    func gray() {
//        iter { (ptr) in
//            let gray = UInt8(0.3  * Double(ptr[3]) + 0.59 * Double(ptr[2]) + 0.11 * Double(ptr[1]))
//            ptr[3] = gray
//            ptr[2] = gray
//            ptr[1] = gray
//        }
    }
    
    func lighten(by offset: UInt8) {
        guard let buffer = sourceBuffer else {
            return
        }
        guard let format = sourceFormat else {
            return
        }
        guard let data = buffer.data else {
            return
        }
        let width = buffer.width
        let height = buffer.height
        
        //todo: format channel
        
        let rebind = data.assumingMemoryBound(to: UInt8.self)
        for i in 0..<Int(width * height){
            let v = rebind[i]
            rebind[i] = 255 - v < offset ? 255 : v + offset
        }
        if let img = try? sourceBuffer?.createCGImage(format: format) {
            image = img
        }
    }
    func darken(by offset: UInt8) {
        guard let buffer = sourceBuffer else {
            return
        }
        guard let format = sourceFormat else {
            return
        }
        guard let data = buffer.data else {
            return
        }
        let width = buffer.width
        let height = buffer.height
        
        //todo: format channel
        
        let rebind = data.assumingMemoryBound(to: UInt8.self)
        for i in 0..<Int(width * height){
            let v = rebind[i]
            rebind[i] = v < offset ? 0 : v - offset
        }
        if let img = try? sourceBuffer?.createCGImage(format: format) {
            image = img
        }
    }
    
}
