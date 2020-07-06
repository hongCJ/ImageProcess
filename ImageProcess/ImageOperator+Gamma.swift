//
//  ImageOperator+Gamma.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/6.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import Accelerate

struct GammaOperator: ImageOperator {
    var debugDescription: String {
        return "GammaOperator b: \(boundary) l: \(linearCoefficients) g:\(gamma)"
    }
    let boundary: Pixel_8
    let linearCoefficients: [Float]
    let gamma: Float
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        let exponentialCoefficients: [Float] = [1, 0, 0]
        let rgbFormat = vImage_CGImageFormat(
            bitsPerComponent: 8,
            bitsPerPixel: 8 * 3,
            colorSpace: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue),
            renderingIntent: .defaultIntent)!
        
        guard var destinationBuffer = try? vImage_Buffer(width: Int(buffer.width),
                                                         height: Int(buffer.height),
                                                         bitsPerPixel: rgbFormat.bitsPerPixel) else {
                                                            return ImageMakeBufferError
        }
        var planarDestination = vImage_Buffer(data: destinationBuffer.data,
                                              height: destinationBuffer.height,
                                              width: destinationBuffer.width * 3,
                                              rowBytes: destinationBuffer.rowBytes)
        
        vImageConvert_RGBA8888toRGB888(&buffer,
                                       &destinationBuffer,
                                       vImage_Flags(kvImageNoFlags))
        
        vImagePiecewiseGamma_Planar8(&planarDestination,
                                     &planarDestination,
                                     exponentialCoefficients,
                                     gamma,
                                     linearCoefficients,
                                     boundary,
                                     vImage_Flags(kvImageNoFlags))
        buffer = destinationBuffer
        format = rgbFormat
        return .success
    }
}

struct AlphaOperator: ImageOperator {
    var debugDescription: String {
        return "alpha ope\rator"
    }
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
//        vImageAlphaBlend_ARGB8888(<#T##srcTop: UnsafePointer<vImage_Buffer>##UnsafePointer<vImage_Buffer>#>, <#T##srcBottom: UnsafePointer<vImage_Buffer>##UnsafePointer<vImage_Buffer>#>, <#T##dest: UnsafePointer<vImage_Buffer>##UnsafePointer<vImage_Buffer>#>, <#T##flags: vImage_Flags##vImage_Flags#>)
        return .success
    }
}
