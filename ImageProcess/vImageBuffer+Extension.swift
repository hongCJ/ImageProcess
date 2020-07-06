//
//  vImageBuffer+Extension.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/3.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import Accelerate
import simd
import UIKit

enum ImageSource {
    enum FileType: String {
        case jpeg
        case png
        case jpg
    }
    
    case name(name: String, type: FileType)
    case image(img: UIImage)
    case asset(name: String)
}

extension ImageSource {
    var cgImage: CGImage? {
       var cg: CGImage?
        switch self {
        case let .image(img: img):
            cg = img.cgImage
        case let .name(name: name, type: type):
            let img = UIImage.loadFromBundle(name: name, type: type.rawValue)
            cg = img?.cgImage
        case let .asset(name: name):
            let img = UIImage(named: name)
            cg = img?.cgImage
        }
        return cg
    }
}


extension Array where Element == Float {
    func simd3() -> simd_float3 {
        assert(count == 3, "error count")
        return simd_float3(self[0], self[1], self[2])
    }
    
    func simd33() -> simd_float3x3 {
        assert(count == 9, "error count")
        let c0 = simd_float3(self[0], self[3], self[6])
        let c1 = simd_float3(self[1], self[4], self[7])
        let c2 = simd_float3(self[2], self[5], self[8])
        return simd_float3x3(columns: (c0, c1, c2))
    }
}

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
