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
    var provider: Bool {get}
}

extension ImageOperator {
    var provider: Bool {
        return false
    }
}

struct ChainOperator: ImageOperator {
    var debugDescription: String {
        return "ChainOperator"
    }
    var provider: Bool {
        let arr = operators.filter {
            $0.provider
        }
        
        return !arr.isEmpty
    }
    var operators: [ImageOperator]
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        guard !operators.isEmpty else {
            return .error("empty operator")
        }
        var resultBuffer = buffer
        var resultFormat = format
        for op in operators {
            let err = op.operateImage(buffer: &resultBuffer, format: &resultFormat)
            if case ImageResult.error(_) = err {
                return err
            }
        }
        buffer = resultBuffer
        format = resultFormat
        return .success
    }
}


let imageChangeNotification = Notification.Name.init("processer-image")

struct BufferBox {
    var buffer: vImage_Buffer
    var format: vImage_CGImageFormat
    
    
    var image: CGImage? {
        let img = try? buffer.createCGImage(format: format)
        return img
    }
    
//    func copy() -> BufferBox? {
//        guard let buff = try? vImage_Buffer(width: Int(buffer.width), height: Int(buffer.height), bitsPerPixel: format.bitsPerPixel) else { return nil }
//        var form = vImage_CGImageFormat(bitsPerComponent: Int(format.bitsPerComponent), bitsPerPixel: Int(format.bitsPerPixel), colorSpace: format.colorSpace as! CGColorSpace, bitmapInfo: format.bitmapInfo)
//
//        return BufferBox(buffer: buff, format: form)
//    }
    
}



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
        if imageOperator.provider {
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
            sourceFormat = format
            sourceBuffer = buffer
        }
        
    }
    
}
