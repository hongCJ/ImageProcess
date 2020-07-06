//
//  ImageOperator2.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/5.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import simd
import Accelerate

struct ConvertOperator: ImageOperator {
    var debugDescription: String {
        return "convert image"
    }
    
    let destinationFormat: vImage_CGImageFormat
    
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        var desFormat = destinationFormat
        let converter = vImageConverter_CreateWithCGImageFormat(
            &format,
            &desFormat,
            nil,
            vImage_Flags(kvImagePrintDiagnosticsToConsole),
            nil)
        
        guard let _converter = converter?.takeRetainedValue() else {
            return .error("convert error")
        }
        
        
        assert(vImageConverter_GetNumberOfSourceBuffers(_converter) == 1,
               "Number of source buffers should be 1.")
        assert(vImageConverter_GetNumberOfDestinationBuffers(_converter) == 1,
               "Number of destination buffers should be 1.")
        
        var rgbDestinationBuffer = vImage_Buffer()
        vImageBuffer_Init(&rgbDestinationBuffer,
                          buffer.height,
                          buffer.width,
                          desFormat.bitsPerPixel,
                          vImage_Flags(kvImageNoFlags))
        
        
        vImageConvert_AnyToAny(
            _converter,
            &buffer,
            &rgbDestinationBuffer,
            nil,
            vImage_Flags(kvImagePrintDiagnosticsToConsole))
        buffer = rgbDestinationBuffer
        return .success
    }
}

struct SharpeOperator: ImageOperator {
    var debugDescription: String {
        return "sharp image"
    }
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        let width = Int(buffer.width)
        let height = Int(buffer.height)
        
        guard var sourceBuffer = try? vImage_Buffer(width: width, height: height, bitsPerPixel: format.bitsPerPixel) else {
            return ImageMakeBufferError
        }
        let bytesPerPix = Int(format.bitsPerPixel / format.bitsPerComponent)
        withUnsafePointer(to: &buffer) { (ptr) -> Void in
            vImageCopyBuffer(ptr, &sourceBuffer, bytesPerPix, vImage_Flags(kvImageNoFlags))
        }
        var floatPixels: [Float]
        let count = width * height
        
        if sourceBuffer.rowBytes == width * MemoryLayout<Pixel_8>.stride {
            let start = sourceBuffer.data.assumingMemoryBound(to: Pixel_8.self)
            floatPixels = vDSP.integerToFloatingPoint(
                UnsafeMutableBufferPointer(start: start,
                                           count: Int(count)),
                floatingPointType: Float.self)
        } else {
            floatPixels = [Float](unsafeUninitializedCapacity: Int(count)) {
                buffer, initializedCount in
                
                var floatBuffer = vImage_Buffer(data: buffer.baseAddress,
                                                height: sourceBuffer.height,
                                                width: sourceBuffer.width,
                                                rowBytes: Int(sourceBuffer.width) * MemoryLayout<Float>.size)
                
                vImageConvert_Planar8toPlanarF(&sourceBuffer,
                                               &floatBuffer,
                                               0, 255,
                                               vImage_Flags(kvImageNoFlags))
                
                initializedCount = Int(count)
            }
        }
        let laplacian: [Float] = [-1, -1, -1,
                                  -1,  8, -1,
                                  -1, -1, -1]
        floatPixels =  vDSP.convolve(floatPixels, rowCount: height, columnCount: width, with3x3Kernel: laplacian)
        //        var mean = Float.nan
        //        var stdDev = Float.nan
        //
        //        vDSP_normalize(floatPixels, 1,
        //                       nil, 1,
        //                       &mean, &stdDev,
        //                       vDSP_Length(count))
        //        print("mean is \(mean) stdDev: \(stdDev)")
        let clippedPixels = vDSP.clip(floatPixels, to: 0 ... 255)
        var pixel8Pixels = vDSP.floatingPointToInteger(clippedPixels,
                                                       integerType: UInt8.self,
                                                       rounding: .towardNearestInteger)
        pixel8Pixels.withUnsafeMutableBufferPointer {
            var resultBuffer = vImage_Buffer(data: $0.baseAddress!,
                                             height: vImagePixelCount(height),
                                             width: vImagePixelCount(width),
                                             rowBytes: width)
            vImagePiecewiseGamma_Planar8(&resultBuffer,
                                         &resultBuffer,
                                         [1, 0, 0],
                                         1 / 2.2,
                                         [1, 0],
                                         0,
                                         vImage_Flags(kvImageNoFlags))
            
            buffer = resultBuffer
        }
        return .success
    }
}
