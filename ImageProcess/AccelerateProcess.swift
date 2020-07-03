//
//  AccelerateProcess.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/2.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import UIKit
import Accelerate

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
}
