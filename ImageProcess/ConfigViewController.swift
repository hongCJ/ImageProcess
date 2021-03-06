//
//  ConfigViewController.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/2.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import UIKit

class ConfiViewController: UIViewController {
    
    var data: [ImageOperator] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        let s1 = ImageSource.name(name: "color", type: .jpg)
        let s2 = ImageSource.name(name: "oip2", type: .jpeg)
        let s3 = ImageSource.name(name: "OIP", type: .jpeg)
        data.append(ImageProvider(source: s1))
        data.append(ImageProvider(source: s2))
        data.append(ImageProvider(source: s3))
        
        data.append(ChainOperator(operators: [ImageProvider(source: s2), CropOperator(rect: CGRect(x: 50, y: 50, width: 200, height: 100))]))
        
//        data.append(HistogramOperator(otherImage: .name(name: "color", type: .jpg)))
//        data.append(AlphaOperator(otherImage: .name(name: "OIP", type: .jpeg), isTop: true))
//        data.append(ChainOperator(operators: [ImageProvider(source: ImageSource.name(name: "color", type: .jpg)), GrayOperator()]))
//        data.append(GrayOperator())
//        data.append(RotateOperator(angle: 45.0))
//        data.append(TranslateOperator(x: 30, y: 40))
//        data.append(ScaleOperator(scale: 1.2))
//        data.append(ScaleOperator(scale: 0.8))
//        data.append(contentsOf: [BrightnessOperator(light: 6), BrightnessOperator(light: -7)])
//        data.append(SharpeOperator())
//        data.append(BoxBlurOperator(kernelLength: 5))
//        data.append(TentBlurOperator(kernel: 5))
//        let kernel2d: [Int16] = [
//            0,    0,    0,      0,      0,      0,      0,
//            0,    2025, 6120,   8145,   6120,   2025,   0,
//            0,    6120, 18496,  24616,  18496,  6120,   0,
//            0,    8145, 24616,  32761,  24616,  8145,   0,
//            0,    6120, 18496,  24616,  18496,  6120,   0,
//            0,    2025, 6120,   8145,   6120,   2025,   0,
//            0,    0,    0,      0,      0,      0,      0
//        ]
//        data.append(KernelOperator(kernel: kernel2d, type: .d2))
//
//        data.append(KernelOperator(kernel: [0, 45, 136, 181, 136, 45, 0], type: .d1))
//
//        data.append(GammaOperator(boundary: 255, linearCoefficients: [1, 0], gamma: 0))
//        data.append(GammaOperator(boundary: 255, linearCoefficients: [0.5, 0.5], gamma: 0))
//        data.append(GammaOperator(boundary: 255, linearCoefficients: [3, -1], gamma: 0))
//        data.append(GammaOperator(boundary: 255, linearCoefficients: [-1, 1], gamma: 0))
//        data.append(GammaOperator(boundary: 0, linearCoefficients: [1, 0], gamma: 2.2))
//        data.append(GammaOperator(boundary: 0, linearCoefficients: [1, 0], gamma: 1/2.2))
    }
    
}

extension ConfiViewController: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return data.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        var cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        if cell == nil {
            cell = UITableViewCell(style: .default, reuseIdentifier: "cell")
        }
        cell?.textLabel?.text = data[indexPath.row].debugDescription
        return cell!
    }
}

extension ConfiViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ope = data[indexPath.row]
        ProcesserBinder.shared.processer.performOperator(imageOperator: ope)
        
        dismiss(animated: true, completion: nil)
    }
}
