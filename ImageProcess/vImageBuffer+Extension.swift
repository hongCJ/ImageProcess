//
//  vImageBuffer+Extension.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/3.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import Accelerate

extension vImage_Buffer {
    func isSubRect(rect: CGRect) -> Bool {
        guard Int(rect.maxX) <= width && Int(rect.maxY) <= height else {
            return false
        }
        guard Int(rect.minX) >= 0 && Int(rect.minY) >= 0 else {
            return false
        }
        return true
    }
    
    func subBuffer(rect: CGRect, format: vImage_CGImageFormat) -> vImage_Buffer? {
        guard isSubRect(rect: rect) else {
            return nil
        }
        let bytesPerPixel = Int(format.bitsPerPixel / format.bitsPerComponent)
        
        let start = Int(rect.origin.y) * rowBytes + Int(rect.origin.x) * bytesPerPixel
        
        let blurDestination = vImage_Buffer(data: data.advanced(by: start),
                                            height: vImagePixelCount(rect.height),
                                            width: vImagePixelCount(rect.width),
                                            rowBytes: rowBytes)
        
        return blurDestination
    }
    
    func isGray() -> Bool {
        return rowBytes / Int(width) == 1
    }
}
