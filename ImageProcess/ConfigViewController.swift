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
        data = [GrayOperator(), RotateOperator(angle: 45.0), TranslateOperator(x: 200, y: 100)]
        data.append(BlurInPlaceOperator(rect: CGRect(x: 100, y: 100, width: 200, height: 200), matrix: [
        0.0722, 0.0722, 0.0722, 0,
        0.7152, 0.7152, 0.7152, 0,
        0.2126, 0.2126, 0.2126, 0,
        0,      0,      0,      1
        ]))
        data.append(BlurOutPlaceOperator(rect: CGRect(x: 100, y: 100, width: 300, height: 300), width: 4))
        data.append(ScaleOperator(scale: 1.2))
        data.append(ScaleOperator(scale: 0.8))
        if let img = UIImage.loadFromBundle(name: "color", type: "jpg"), let cgImage = img.cgImage {
            data.append(BufferProvider(image: cgImage))
        }
        data.append(contentsOf: [BrightnessOperator(light: 6), BrightnessOperator(light: -7)])
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
    }
}
