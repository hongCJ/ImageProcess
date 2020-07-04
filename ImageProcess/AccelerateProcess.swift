//
//  AccelerateProcess.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/2.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import UIKit
import Accelerate

import simd



extension ImageProcesser {
    func Accelerate_gray() {
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
        
        guard var source = sourceBuffer else {
            return
        }
        guard var destinationBuffer = try? vImage_Buffer(width: image.width, height: image.height, bitsPerPixel: 8) else {
            return
        }
        let format = vImage_CGImageFormat(bitsPerComponent: 8, bitsPerPixel: 8, colorSpace: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGBitmapInfo(rawValue: CGImageAlphaInfo.none.rawValue), renderingIntent: .defaultIntent)
        
        vImageMatrixMultiply_ARGB8888ToPlanar8(&source, &destinationBuffer, &coefficientsMatrix, divisor, preBias, postBias, vImage_Flags(kvImageNoFlags))
        
        if let img =  try? destinationBuffer.createCGImage(format: format!) {
            self.image = img
            NotificationCenter.default.post(name: imageChangeNotification, object: nil)
        }
        source.free()
        sourceBuffer = destinationBuffer
        sourceFormat = format
    }

    
    func scale(scale: Float) {
        guard var buffer = sourceBuffer else {
            return
        }
        guard let format = sourceFormat else {
            return
        }
        let destinationHeight = Int(Float(buffer.height) * scale)
        let destinationWidth = Int(Float(buffer.width) * scale)
        
        guard var destinationBuffer = try? vImage_Buffer(width: destinationWidth, height: destinationHeight, bitsPerPixel: format.bitsPerPixel) else {
            return
        }
        
        if format.colorSpace.takeUnretainedValue().model == CGColorSpaceModel.rgb {
            vImageScale_ARGB8888(&buffer, &destinationBuffer, nil, vImage_Flags(kvImageHighQualityResampling))
        } else {
            vImageScale_Planar8(&buffer, &destinationBuffer, nil, vImage_Flags(kvImageHighQualityResampling))
        }
        
        if let img = try? destinationBuffer.createCGImage(format: format) {
            image = img
            sourceBuffer?.free()
            sourceBuffer = destinationBuffer
        } else {
            destinationBuffer.free()
        }
    }
    
    
    func blur(rect: CGRect) {
        guard let source = sourceBuffer, let format = sourceFormat else {
            return
        }
        guard var buffer = source.subBuffer(rect: rect, format: format) else {
            return
        }
        let divisor: Int32 = 0x1000
        
        let desaturationMatrix = [
            0.0722, 0.0722, 0.0722, 0,
            0.7152, 0.7152, 0.7152, 0,
            0.2126, 0.2126, 0.2126, 0,
            0,      0,      0,      1
            ].map {
                return Int16($0 * Float(divisor))
        }
        
        let error = vImageMatrixMultiply_ARGB8888(&buffer,
                                                  &buffer,
                                                  desaturationMatrix,
                                                  divisor,
                                                  nil, nil,
                                                  vImage_Flags(kvImageNoFlags))
        guard error == kvImageNoError  else {
            return
        }
        if let img = try? sourceBuffer?.createCGImage(format: sourceFormat!) {
            image = img
        }
    }
    
    func blur2(rect: CGRect) {
        guard var source = sourceBuffer, let format = sourceFormat else {
            return
        }
        guard var destinationBuffer = try? vImage_Buffer(width: Int(source.width), height: Int(source.height), bitsPerPixel: format.bitsPerPixel) else {
            return
        }
        let bytesPerPix = Int(format.bitsPerPixel / format.bitsPerComponent)
        withUnsafePointer(to: &source) { (ptr) -> Void in
            vImageCopyBuffer(ptr, &destinationBuffer, bytesPerPix, vImage_Flags(kvImageNoFlags))
        }
        
        guard var blurDestination = destinationBuffer.subBuffer(rect: rect, format: format) else {
            destinationBuffer.free()
            return
        }
        
        var error = kvImageNoError
        withUnsafePointer(to: &destinationBuffer) { (ptr) -> Void in
            let blurDiameter = UInt32(5 * 2 + 1)
            error = vImageTentConvolve_ARGB8888(ptr, &blurDestination, nil, vImagePixelCount(rect.origin.x), vImagePixelCount(rect.origin.y), blurDiameter, blurDiameter, [0], vImage_Flags(kvImageTruncateKernel))
        }
        
        guard error == kvImageNoError else {
            destinationBuffer.free()
            return
        }
        
        if let img = try? destinationBuffer.createCGImage(format: sourceFormat!) {
            image = img
            sourceBuffer?.free()
            sourceBuffer = destinationBuffer
        }
        
        
    }
    
    
    func translate(offSet: CGPoint) {
        guard var buffer = sourceBuffer, let format = sourceFormat else {
            return
        }
        
        var transform = vImage_AffineTransform(a: 1, b: 0, c: 0, d: 1, tx: Float(offSet.x), ty: Float(offSet.y))
        
        
        guard var destinationBuffer = try? vImage_Buffer(width: Int(buffer.width) + Int(offSet.x), height: Int(buffer.height) + Int(offSet.y), bitsPerPixel: format.bitsPerPixel) else {
            return
        }
        
        let err = vImageAffineWarp_ARGB8888(&buffer, &destinationBuffer, nil, &transform, [0], vImage_Flags(kvImageHighQualityResampling))
        guard err == kvImageNoError else {
            destinationBuffer.free()
            return
        }
        
        if let img = try? destinationBuffer.createCGImage(format: format) {
            image = img
            sourceBuffer?.free()
            sourceBuffer = destinationBuffer
        } else {
            destinationBuffer.free()
        }
    }
    
    func rotate(angle: Float) {
        guard var buffer = sourceBuffer, let format = sourceFormat else {
            return
        }
        
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
            return
        }
        
        let err = vImageAffineWarp_ARGB8888(&buffer, &destinationBuffer, nil, &bufferTranform, [0], vImage_Flags(kvImageHighQualityResampling))
        guard err == kvImageNoError else {
            destinationBuffer.free()
            return
        }
        
        if let img = try? destinationBuffer.createCGImage(format: format) {
            image = img
            sourceBuffer?.free()
            sourceBuffer = destinationBuffer
        } else {
            destinationBuffer.free()
        }
    }
    
}
