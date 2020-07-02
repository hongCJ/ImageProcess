//
//  Util.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/1.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import Foundation
import UIKit
import CoreGraphics

extension UIImage {
    
    func exif() -> CFDictionary? {
        guard let data = jpegData(compressionQuality: 1.0) else {
            return nil
        }
        print(data.count)
        var info: CFDictionary?
        data.withUnsafeBytes({ (ptr) -> Void in
            let bytes = ptr.baseAddress?.assumingMemoryBound(to: UInt8.self)
            if let cfData = CFDataCreate(kCFAllocatorDefault, bytes, data.count),
                let source = CGImageSourceCreateWithData(cfData, nil) {
                info = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
            }
        })
        return info
    }
    static func loadFromBundle(name: String, type: String = "jpeg") -> UIImage? {
        let path = Bundle.main.path(forResource: name, ofType: type)
        guard let filePath = path else {
            return nil
        }
        guard let img = UIImage(contentsOfFile: filePath) else {
            return nil
        }
        return img
    }
    
    
    func gray() -> UIImage? {
        guard let cgImg = cgImage else {
            return nil
        }
        let w = cgImg.width
        let h = cgImg.height
        let rect = CGRect(x: 0, y: 0, width: w, height: h)
        let colorSpace = CGColorSpaceCreateDeviceGray()
        
        let context = CGContext.init(data: nil, width: w, height: h, bitsPerComponent: 8, bytesPerRow: 0,  space: colorSpace, bitmapInfo: CGImageAlphaInfo.none.rawValue)
        context?.draw(cgImg, in: rect)
        if let imageRef = context?.makeImage() {
            let grayImage = UIImage(cgImage: imageRef)
            return grayImage
        }
        return nil
        
    }
    
    func loadData() -> UnsafeMutablePointer<UInt8>? {
        guard let cgimg = cgImage else {
            return nil
        }
        
        let width = cgimg.width
        let height = cgimg.height
        
        let data = UnsafeMutablePointer<UInt32>.allocate(capacity: width * height)
        let space = CGColorSpaceCreateDeviceRGB()
        let uint32Size = MemoryLayout<UInt32>.size
        let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * uint32Size, space: space, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue | CGImageByteOrderInfo.order32Little.rawValue)
        context?.draw(cgimg, in: CGRect(x: 0, y: 0, width: width, height: height))
        
        let result = UnsafeMutablePointer<UInt8>.allocate(capacity: width * height)
        defer {
            data.deinitialize(count: width * height)
        }
        
        for row in 0..<height {
            for column in 0..<width {
                let rgba = data.advanced(by: row * width + column)
                let rgb = unsafeBitCast(rgba, to: UnsafeMutablePointer<UInt8>.self)
                let gray = UInt8(0.3  * Double(rgb[3]) +
                                 0.59 * Double(rgb[2]) +
                                 0.11 * Double(rgb[1]))
                result.advanced(by: row * width + column).pointee = gray
            }
        }
        return result
    }
    
    static func makeGrayImage(data: UnsafeMutablePointer<UInt8>, width: Int, height: Int) -> UIImage? {
        let context = CGContext(data: data, width: width, height: height, bitsPerComponent: 8, bytesPerRow: width * MemoryLayout<UInt8>.size, space: CGColorSpaceCreateDeviceGray(), bitmapInfo: CGImageAlphaInfo.none.rawValue)
        if let image = context?.makeImage() {
            return UIImage(cgImage: image)
        }
        return nil
    }
}
