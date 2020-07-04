//
//  ImageProcesser.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/2.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import UIKit
import Accelerate


enum ImageResult {
    case success
    case error(String)
}

let ImageMakeBufferError = ImageResult.error("fail create buffer")

protocol ImageOperator: CustomDebugStringConvertible {
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult
}


let imageChangeNotification = Notification.Name.init("processer-image")

class ImageProcesser {
     var image: CGImage? {
        didSet {
            NotificationCenter.default.post(name: imageChangeNotification, object: nil)
        }
    }

    var sourceBuffer: vImage_Buffer?
    var sourceFormat: vImage_CGImageFormat?
    
    deinit {
        sourceBuffer?.free()
    }

    func performOperator(imageOperator: ImageOperator) {
        // not good
        if type(of: imageOperator) == BufferProvider.self {
            if sourceFormat == nil {
                sourceFormat = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 32, colorSpace: CGColorSpaceCreateDeviceRGB(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.first.rawValue))
            }
            if sourceBuffer == nil {
                sourceBuffer = try? vImage_Buffer(width: 10, height: 10, bitsPerPixel: 32)
            }
        }
        guard var buffer = sourceBuffer, var format = sourceFormat else {
            return
        }
        let err = imageOperator.operateImage(buffer: &buffer, format: &format)
        guard case ImageResult.success = err else {
            return
        }
        if let img = try? buffer.createCGImage(format: format) {
            image = img
            sourceBuffer?.free()
            sourceFormat = format
            sourceBuffer = buffer
        }
        
    }
    
}
