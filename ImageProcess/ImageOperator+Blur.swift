//
//  ImageOperator+Blur.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/6.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import Accelerate

struct BoxBlurOperator: ImageOperator {
    var debugDescription: String {
        return "blur image with box "
    }
    
    let kernelLength: UInt32
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        let width = Int(buffer.width)
        let height = Int(buffer.height)
        guard var destinationBuffer = try? vImage_Buffer(width: width, height: height, bitsPerPixel: format.bitsPerPixel) else {
            return ImageMakeBufferError
        }
        //        let bytesPerPix = Int(format.bitsPerPixel / format.bitsPerComponent)
        //        withUnsafePointer(to: &buffer) { (ptr) -> Void in
        //            vImageCopyBuffer(ptr, &destinationBuffer, bytesPerPix, vImage_Flags(kvImageNoFlags))
        //        }
        let rect = CGRect.zero //CGRect(x: 0, y: 0, width: width, height: height)
        //        guard var blurDestination = destinationBuffer.subBuffer(rect: rect, format: format) else {
        //            destinationBuffer.free()
        //            return ImageMakeBufferError
        //        }
        var err = kvImageNoError
        if buffer.isGray() {
            err = vImageBoxConvolve_Planar8(&buffer, &destinationBuffer, nil, 0, 0, kernelLength, kernelLength, 0, vImage_Flags(kvImageEdgeExtend))
        } else {
            err = vImageBoxConvolve_ARGB8888(&buffer, &destinationBuffer, nil, vImagePixelCount(rect.origin.x), vImagePixelCount(rect.origin.y), kernelLength, kernelLength, nil, vImage_Flags(kvImageEdgeExtend))
        }
        guard err == kvImageNoError else {
            return .error("\(err)")
        }
        buffer = destinationBuffer
        return .success
    }
}

struct TentBlurOperator: ImageOperator {

    var debugDescription: String {
        return "TentBlurOperator with \(kernel)"
    }
    
    let kernel: UInt32
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        let width = Int(buffer.width)
        let height = Int(buffer.height)
        guard var destinationBuffer = try? vImage_Buffer(width: width, height: height, bitsPerPixel: format.bitsPerPixel) else {
            return ImageMakeBufferError
        }
        var err = kvImageNoError
        if buffer.isGray() {
            err = vImageTentConvolve_Planar8(&buffer, &destinationBuffer, nil, 0, 0, kernel, kernel, 0, vImage_Flags(kvImageTruncateKernel))
        } else {
            err = vImageTentConvolve_ARGB8888(&buffer, &destinationBuffer, nil, 0, 0, kernel, kernel, nil, vImage_Flags(kvImageTruncateKernel))
        }
        guard err == kvImageNoError else {
            return .error("\(err)")
        }
        buffer = destinationBuffer
        return .success
    }
}

struct KernelOperator: ImageOperator {
    var debugDescription: String {
        return "KernelOperator type:\(type)"
    }
    
    enum KernelType {
        case d1
        case d2
    }
    
    let kernel: [Int16]
    
    let type: KernelType
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        var ker = kernel;
        let divisor = ker.map { Int32($0) }.reduce(0, +)
        let kernelCount = type == .d2 ? Int(sqrtf(Float(ker.count))) : ker.count
        guard var destinationBuffer = try? vImage_Buffer(width: Int(buffer.width), height: Int(buffer.height), bitsPerPixel: format.bitsPerPixel) else {
            return ImageMakeBufferError
        }
        
        
        if buffer.isGray() {
            if type == .d1 {
               vImageConvolve_Planar8(&buffer, &destinationBuffer, nil, 0, 0, &ker, UInt32(kernelCount), UInt32(kernelCount), divisor, 0, vImage_Flags(kvImageEdgeExtend))
            } else {
                vImageConvolve_Planar8(&buffer, &destinationBuffer, nil, 0, 0, &ker, UInt32(kernelCount), 1, divisor, 0, vImage_Flags(kvImageEdgeExtend))
                vImageConvolve_Planar8(&destinationBuffer, &destinationBuffer, nil, 0, 0, &ker, 1, UInt32(kernelCount), divisor, 0, vImage_Flags(kvImageEdgeExtend))
            }
            
        } else {
            if type == .d2 {
                vImageConvolve_ARGB8888(&buffer, &destinationBuffer, nil, 0, 0, &ker, UInt32(kernelCount), UInt32(kernelCount), divisor, nil, vImage_Flags(kvImageEdgeExtend))
            } else {
                vImageConvolve_ARGB8888(&buffer, &destinationBuffer, nil, 0, 0, &ker, UInt32(kernelCount), 1, divisor, nil, vImage_Flags(kvImageEdgeExtend))
                vImageConvolve_ARGB8888(&destinationBuffer, &destinationBuffer, nil, 0, 0, &ker, 1, UInt32(kernelCount), divisor, nil, vImage_Flags(kvImageEdgeExtend))
            }
        }
        
        
        buffer = destinationBuffer
        
        return .success
    }
}
