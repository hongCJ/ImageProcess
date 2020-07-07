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
    var next: ImageOperator?
    
    var otherImage: ImageSource
    let isTop: Bool
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        guard let image = otherImage.cgImage else { return .error("load image error") }
        guard let otherFormat = vImage_CGImageFormat(cgImage: image) else {
            return .error("load format err")
        }
        guard var otherBuffer = try? vImage_Buffer(cgImage: image, format: otherFormat) else {
            return .error("load buffer err")
        }
        
        guard var destinationBuffer = try? vImage_Buffer(width: Int(buffer.width), height: Int(buffer.height), bitsPerPixel: format.bitsPerPixel) else {
            otherBuffer.free()
            return ImageMakeBufferError
        }
        print("top: \(otherBuffer.width) \(otherBuffer.height)")
        print("bottom: \(buffer.width) \(buffer.height)")
        
        vImageAlphaBlend_ARGB8888(&otherBuffer, &buffer, &destinationBuffer, vImage_Flags(kvImageNoFlags))
        buffer = destinationBuffer
        return .success
    }
}

struct HistogramOperator: ImageOperator {
    var debugDescription: String {
        return "HistogramOperator"
    }
    
    let otherImage: ImageSource
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        guard let cgImage = otherImage.cgImage else {
            return .error("load image errpr")
        }
        guard let otherFormat = vImage_CGImageFormat(cgImage: cgImage) else {
            return .error("load format err")
        }
        guard var otherBuffer = try? vImage_Buffer(cgImage: cgImage, format: otherFormat) else {
            return .error("load buffer err")
        }
        var histogramBinZero = [vImagePixelCount](repeating: 0, count: 256)
        var histogramBinOne = [vImagePixelCount](repeating: 0, count: 256)
        var histogramBinTwo = [vImagePixelCount](repeating: 0, count: 256)
        var histogramBinThree = [vImagePixelCount](repeating: 0, count: 256)
        histogramBinZero.withUnsafeMutableBufferPointer { zeroPtr in
            histogramBinOne.withUnsafeMutableBufferPointer { onePtr in
                histogramBinTwo.withUnsafeMutableBufferPointer { twoPtr in
                    histogramBinThree.withUnsafeMutableBufferPointer { threePtr in
                        
                        var histogramBins = [zeroPtr.baseAddress, onePtr.baseAddress,
                                             twoPtr.baseAddress, threePtr.baseAddress]
                        
                        histogramBins.withUnsafeMutableBufferPointer { histogramBinsPtr in
                            let error = vImageHistogramCalculation_ARGB8888(&otherBuffer,
                                                                            histogramBinsPtr.baseAddress!,
                                                                            vImage_Flags(kvImageNoFlags))
                            
                            guard error == kvImageNoError else {
                                fatalError("Error calculating histogram: \(error)")
                            }
                        }
                    }
                }
            }
        }
        histogramBinZero.withUnsafeBufferPointer { zeroPtr in
            histogramBinOne.withUnsafeBufferPointer { onePtr in
                histogramBinTwo.withUnsafeBufferPointer { twoPtr in
                    histogramBinThree.withUnsafeBufferPointer { threePtr in
                        
                        var histogramBins = [zeroPtr.baseAddress, onePtr.baseAddress,
                                             twoPtr.baseAddress, threePtr.baseAddress]
                        histogramBins.withUnsafeMutableBufferPointer { histogramBinsPtr in
                            let error = vImageHistogramSpecification_ARGB8888(&buffer,
                                                                              &buffer,
                                                                              histogramBinsPtr.baseAddress!,
                                                                              vImage_Flags(kvImageLeaveAlphaUnchanged))
                            guard error == kvImageNoError else {
                                fatalError("Error specifying histogram: \(error)")
                            }
                        }
                    }
                }
            }
        }

        return .success
    }
}

struct CropOperator: ImageOperator {
    var debugDescription: String {
        return "CropOperator rect:\(rect)"
    }
    let rect: CGRect
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        guard buffer.isSubRect(rect: rect) else {
            return .error("out of rect")
        }
        let bytesPerPix = format.bitsPerPixel / format.bitsPerComponent
        let start = Int(rect.origin.y) * Int(buffer.rowBytes) + Int(rect.origin.x) * Int(bytesPerPix)
                      
        let blurDestination = vImage_Buffer(data: buffer.data.advanced(by: start),
                                            height: vImagePixelCount(rect.height),
                                            width: vImagePixelCount(rect.width),
                                            rowBytes: buffer.rowBytes)
        buffer = blurDestination
        return .success
    }
}
