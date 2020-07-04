//
//  ImageOperator.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/4.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import Accelerate
import simd

struct BufferProvider: ImageOperator {
    var debugDescription: String {
        return "set image source buffer"
    }
    let image: CGImage
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        guard let imageFormat = vImage_CGImageFormat(cgImage: image) else {
            return .error("get format err")
        }
        guard let imageBuffer = try? vImage_Buffer(cgImage: image, format: imageFormat) else {
            return .error("get image buffer err")
        }
        buffer = imageBuffer
        format = imageFormat
        return .success
        
    }
}

struct GrayOperator: ImageOperator {
    var debugDescription: String {
        return "convert image to gray image"
    }
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        let redCoefficient: Float = 0.2126
        let greenCoefficient: Float = 0.7152
        let blueCoefficient: Float = 0.0722
        
        let divisor: Int32 = 0x1000
        let fDivisor = Float(divisor)
        
        var coefficientsMatrix = [
            Int16(redCoefficient * fDivisor),
            Int16(greenCoefficient * fDivisor),
            Int16(blueCoefficient * fDivisor)
        ]
        
        let preBias: [Int16] = [0, 0, 0, 0]
        let postBias: Int32 = 0
        
        guard var destinationBuffer = try? vImage_Buffer(width: Int(buffer.width), height: Int(buffer.height), bitsPerPixel: 8) else {
            return ImageMakeBufferError
        }
        let destinationFormat = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 8, colorSpace: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue), renderingIntent: .defaultIntent)
        let error = vImageMatrixMultiply_ARGB8888ToPlanar8(&buffer, &destinationBuffer, &coefficientsMatrix, divisor, preBias, postBias, vImage_Flags(kvImageNoFlags))
        guard error == kvImageNoError else {
            return .error("\(error)")
        }
        
        buffer = destinationBuffer
        format = destinationFormat!
        
        return .success
    }
}


struct TranslateOperator: ImageOperator {
    var debugDescription: String {
        return "translate Image by x: \(x) y: \(y)"
    }
    
    let x: Int
    let y: Int
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        var transform = vImage_AffineTransform(a: 1, b: 0, c: 0, d: 1, tx: Float(x), ty: Float(y))
        
        guard var destinationBuffer = try? vImage_Buffer(width: Int(buffer.width) + x, height: Int(buffer.height) + y, bitsPerPixel: format.bitsPerPixel) else {
            return ImageMakeBufferError
        }
        
        let err = vImageAffineWarp_ARGB8888(&buffer, &destinationBuffer, nil, &transform, [0], vImage_Flags(kvImageHighQualityResampling))
        guard err == kvImageNoError else {
            destinationBuffer.free()
            return .error("\(err)")
        }
        buffer = destinationBuffer
        return .success
    }
    
}


struct RotateOperator: ImageOperator {
    var debugDescription: String {
        return "rotate image by angle: \(angle)"
    }
    
    let angle: Float
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        let width = Float(buffer.width)
        let height = Float(buffer.height)
        
        let angleM = (angle / 180) * Float.pi
        
        let sinValue = sin(angleM)
        let cosValue = cos(angleM)
        
        let hw = width / 2
        let hh = height / 2
        
        
        let forwardMatrix = simd_matrix(simd_float3(arrayLiteral: 1, 0, -hw), simd_float3(arrayLiteral: 0, -1, hh), simd_float3(arrayLiteral: 0, 0, 1))
        
        let backMatrix = simd_matrix(simd_float3(arrayLiteral: 1, 0, hw), simd_float3(arrayLiteral: 0, -1, hh), simd_float3(arrayLiteral: 0, 0, 1))
        
        let transforMatrix = simd_matrix(simd_float3(x: cosValue, y: sinValue, z: 0), simd_float3(x: -sinValue, y: cosValue, z: 0), simd_float3(x: 0, y: 0, z: 1))
        
        let finaleMatrix = forwardMatrix * transforMatrix * backMatrix
        
        let c0 = finaleMatrix.columns.0
        let c1 = finaleMatrix.columns.1
        
        var bufferTranform = vImage_AffineTransform(a: c0.x, b: c1.x, c: c0.y, d: c1.y, tx: c0.z, ty: c1.z)
        
        let new_w = ceil(abs(width * cosValue) + abs(height * sinValue));
        let new_h = ceil(abs(width * cosValue) + abs(height * sinValue));
        
        guard var destinationBuffer = try? vImage_Buffer(width: Int(new_w), height: Int(new_h), bitsPerPixel: format.bitsPerPixel) else {
            return ImageMakeBufferError
        }
        
        let err = vImageAffineWarp_ARGB8888(&buffer, &destinationBuffer, nil, &bufferTranform, [0], vImage_Flags(kvImageHighQualityResampling))
        guard err == kvImageNoError else {
            destinationBuffer.free()
            return .error("\(err)")
        }
        buffer = destinationBuffer
        return .success
    }
}

struct BlurInPlaceOperator: ImageOperator {
    var debugDescription: String {
        return "in place blur with  rect: \(rect) matrix: \(matrix)"
    }
    let rect: CGRect
    let matrix: [Float]
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        assert(matrix.count == 16, "unsupport matrix")
        guard var buffer = buffer.subBuffer(rect: rect, format: format) else {
            return .error("out of rect")
        }
        let divisor: Int32 = 0x1000
        
        let desaturationMatrix = matrix.map {
            return Int16($0 * Float(divisor))
        }
        let err = vImageMatrixMultiply_ARGB8888(&buffer,
                                                &buffer,
                                                desaturationMatrix,
                                                divisor,
                                                nil, nil,
                                                vImage_Flags(kvImageNoFlags))
        guard err == kvImageNoError  else {
            return .error("\(err)")
        }
        
        
        return .success
    }
}

struct BlurOutPlaceOperator: ImageOperator {
    var debugDescription: String {
        return "BlurOutPlaceOperator with \(rect) \(width)"
    }
    let rect: CGRect
    let width: Float
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        guard var destinationBuffer = try? vImage_Buffer(width: Int(buffer.width), height: Int(buffer.height), bitsPerPixel: format.bitsPerPixel) else {
            return ImageMakeBufferError
        }
        let bytesPerPix = Int(format.bitsPerPixel / format.bitsPerComponent)
        withUnsafePointer(to: &buffer) { (ptr) -> Void in
            vImageCopyBuffer(ptr, &destinationBuffer, bytesPerPix, vImage_Flags(kvImageNoFlags))
        }
        
        guard var blurDestination = destinationBuffer.subBuffer(rect: rect, format: format) else {
            destinationBuffer.free()
            return ImageMakeBufferError
        }
        
        var err = kvImageNoError
        withUnsafePointer(to: &destinationBuffer) { (ptr) -> Void in
            let blurDiameter = UInt32(5 * 2 + 1)
            err = vImageTentConvolve_ARGB8888(ptr, &blurDestination, nil, vImagePixelCount(rect.origin.x), vImagePixelCount(rect.origin.y), blurDiameter, blurDiameter, [0], vImage_Flags(kvImageTruncateKernel))
        }
        
        guard err == kvImageNoError else {
            destinationBuffer.free()
            return .error("\(err)")
        }
        buffer = destinationBuffer
        return .success
        
    }
}

struct ScaleOperator: ImageOperator {
    var debugDescription: String {
        return "ScaleOperator with: \(scale)"
    }
    let scale: Float
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        let destinationHeight = Int(Float(buffer.height) * scale)
        let destinationWidth = Int(Float(buffer.width) * scale)
        
        guard var destinationBuffer = try? vImage_Buffer(width: destinationWidth, height: destinationHeight, bitsPerPixel: format.bitsPerPixel) else {
            return ImageMakeBufferError
        }
        
        if format.colorSpace.takeUnretainedValue().model == CGColorSpaceModel.rgb {
            vImageScale_ARGB8888(&buffer, &destinationBuffer, nil, vImage_Flags(kvImageHighQualityResampling))
        } else {
            vImageScale_Planar8(&buffer, &destinationBuffer, nil, vImage_Flags(kvImageHighQualityResampling))
        }
        
        buffer = destinationBuffer
        return .success
    }
    
}

struct BrightnessOperator: ImageOperator {
    var debugDescription: String {
        return "BrightnessOperator image with \(light)"
    }
    let light: Int
    
    func operateImage(buffer: inout vImage_Buffer, format: inout vImage_CGImageFormat) -> ImageResult {
        let width = buffer.width
        let height = buffer.height
        
        guard var destinationBuffer = try? vImage_Buffer(width: Int(width), height: Int(height), bitsPerPixel: format.bitsPerPixel) else {
            return ImageMakeBufferError
        }
        let bytesPerPix = UInt(format.bitsPerPixel / format.bitsPerComponent)
        
        withUnsafePointer(to: &buffer) { (ptr) -> Void in
            vImageCopyBuffer(ptr, &destinationBuffer, Int(bytesPerPix), vImage_Flags(kvImageNoFlags))
        }
        
        func lighterFilter(offSet: UInt8)-> ((UInt8) -> UInt8) {
            return {
                (value: UInt8) -> UInt8 in
                return 255 - value < offSet ? 255 : value + offSet
            }
        }
        
        func darkFilter(offSet: UInt8) -> ((UInt8) -> UInt8) {
            return {
                (value: UInt8) -> UInt8 in
                return  value < offSet ? 0 : value - offSet
            }
        }
        
        let filter = light > 0 ? lighterFilter(offSet: UInt8(light)) : darkFilter(offSet: UInt8(0 - light))
        
        guard let data = destinationBuffer.data else {
            destinationBuffer.free()
           return .error("data error")
           }
               
        
        let rebind = data.assumingMemoryBound(to: UInt8.self)
        for i in 0..<Int(width * height * bytesPerPix){
            let v = rebind[i]
            rebind[i] = filter(v)
        }
        buffer = destinationBuffer
        
        return .success
    }
}
