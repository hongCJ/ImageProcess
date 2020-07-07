//
//  TestViewController.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/7.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import UIKit
import Accelerate

extension vImage_Buffer {
    mutating func desaturate_ARGB8888(regionOfInterest roi: CGRect) {
        guard Int(roi.maxX) <= width && Int(roi.maxY) <= height &&
            Int(roi.minX) >= 0 && Int(roi.minY) >= 0 else {
                print("ROI is out of bounds.")
                return
        }
        let bytesPerPixel = 4
        
        let start = Int(roi.origin.y) * rowBytes +
            Int(roi.origin.x) * bytesPerPixel
        
        var desaturationBuffer = vImage_Buffer(data: data.advanced(by: start),
                                                      height: vImagePixelCount(roi.height),
                                                      width: vImagePixelCount(roi.width),
                                                      rowBytes: rowBytes)
        
        let divisor: Int32 = 0x1000
               
               let desaturationMatrix = [
                   0.0722, 0.0722, 0.0722, 0,
                   0.7152, 0.7152, 0.7152, 0,
                   0.2126, 0.2126, 0.2126, 0,
                   0,      0,      0,      1
                   ].map {
                       return Int16($0 * Float(divisor))
               }
               
               let error = vImageMatrixMultiply_ARGB8888(&desaturationBuffer,
                                                         &desaturationBuffer,
                                                         desaturationMatrix,
                                                         divisor,
                                                         nil, nil,
                                                         vImage_Flags(kvImageNoFlags))
               
               if error != kvImageNoError {
                   print("Error: \(error)")
               }
    }
    
    func blurred_ARGB8888(regionOfInterest roi: CGRect, blurRadius: Int) -> vImage_Buffer? {
        guard Int(roi.maxX) <= width && Int(roi.maxY) <= height &&
            Int(roi.minX) >= 0 && Int(roi.minY) >= 0 else {
                print("ROI is out of bounds.")
                return nil
        }
        guard var destination = try? vImage_Buffer(width: Int(width),
                                                          height: Int(height),
                                                          bitsPerPixel: 32) else {
                                                           return nil
               }
               
               let bytesPerPixel = 4
               
               _ = withUnsafePointer(to: self) { src in
                   vImageCopyBuffer(src,
                                    &destination,
                                    bytesPerPixel,
                                    vImage_Flags(kvImageNoFlags))
               }
        let start = Int(roi.origin.y) * destination.rowBytes +
            Int(roi.origin.x) * bytesPerPixel
        
        var blurDestination = vImage_Buffer(data: destination.data.advanced(by: start),
                                            height: vImagePixelCount(roi.height),
                                            width: vImagePixelCount(roi.width),
                                            rowBytes: destination.rowBytes)
        var error = kvImageNoError
        
        _ = withUnsafePointer(to: self) { src in
            let blurDiameter = UInt32(blurRadius * 2 + 1)
            error = vImageTentConvolve_ARGB8888(src,
                                                &blurDestination,
                                                nil,
                                                vImagePixelCount(roi.origin.x),
                                                vImagePixelCount(roi.origin.y),
                                                blurDiameter, blurDiameter,
                                                [0],
                                                vImage_Flags(kvImageTruncateKernel))
        }
        
        if error != kvImageNoError {
            destination.free()
            print("Error: \(error)")
            return nil
        }
        
        return destination
    }
    
}

class TestViewController: UIViewController {

    @IBOutlet weak var v1: UIImageView!
    
    @IBOutlet weak var v2: UIImageView!
    override func viewDidLoad() {
        super.viewDidLoad()
        test()
        
    }
    
    func test() {
        let image = ImageSource.name(name: "opi3", type: .jpeg).cgImage!
        
        let opeartor = TentBlurOperator(kernel: 9)//BoxBlurOperator(kernelLength: 7)//GrayOperator()
        
        guard var format = vImage_CGImageFormat(cgImage: image) else {
            return
        }
        guard var buffer = try? vImage_Buffer(cgImage: image, format: format) else { return }
        
//        guard var desBuffer = try? vImage_Buffer(width: Int(buffer.width), height: Int(buffer.height), bitsPerPixel: format.bitsPerPixel) else { return }
//        withUnsafePointer(to: &buffer) { (ptr) -> Void in
//            vImageCopyBuffer(ptr, &desBuffer, 4, vImage_Flags(kvImageNoFlags))
//        }
//        guard let desBuffer = buffer.blurred_ARGB8888(regionOfInterest: CGRect(x: 50, y: 50, width: 200, height: 200), blurRadius: 7) else {
//            return
//        }
//
//        guard var blurBuffer = desBuffer.subBuffer(rect: CGRect(x: 0, y: 0, width: 200, height: 200), format: format) else {
//            return
//        }
//
        var grayBuffer = buffer
        var grayFormat = format
        
        
        
        
//        vImageBoxConvolve_ARGB8888(&buffer, &desBuffer, nil, 0, 0, 7, 7, nil, vImage_Flags(kvImageTruncateKernel))
        
        _ = opeartor.operateImage(buffer: &grayBuffer, format: &grayFormat)
        
//        desBuffer.desaturate_ARGB8888(regionOfInterest: CGRect(x: 50, y: 50, width: 200, height: 200))
        
        if let origin = try? buffer.createCGImage(format: format) {
            v1.image = UIImage(cgImage: origin)
        }
        
        if let gray = try? grayBuffer.createCGImage(format: format) {
            v2.image = UIImage(cgImage: gray)
        }
    }
}
