//
//  ConfigViewController.swift
//  ImageProcess
//
//  Created by 郑红 on 2020/7/2.
//  Copyright © 2020 com.zhenghong. All rights reserved.
//

import UIKit

struct CellData {
    var title: String
    var sel: Selector
}

enum ProcessType {
    case scale(Float)
    case blur(Float)
    case blur2(Float)
    case bright(UInt8)
    case dark(UInt8)
    case gray
    case reset
    case translate(CGPoint)
    case rotate(Float)
}

extension ProcessType {
    func title() -> String {
        switch self {
        case .scale(let x):
            let str = x > 1 ? "big" : "small"
            return "scale \(str)"
        case .blur(_):
            return "blur black"
        case .blur2(_):
            return "blur filter"
        case .bright(_):
            return "bright image"
        case .dark(_):
            return "dark image"
        case .gray:
            return "gray image"
        case .reset:
            return "reset image"
        case .translate(let point):
            return "translate x: \(point.x) y: \(point.y)"
        case .rotate(let x):
            return "rotate \(x)"
        }
    }
}

class ConfiViewController: UIViewController {
    
    var data: [ProcessType] = []
    override func viewDidLoad() {
        super.viewDidLoad()
        data = [
            .scale(1.2),
            .scale(0.8),
            .blur(5),
            .blur2(5),
            .bright(8),
            .dark(8),
            .gray,
            .reset,
            .translate(CGPoint.init(x: 100, y: 100)),
            .rotate(-90.0)
        ]
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
        cell?.textLabel?.text = data[indexPath.row].title()
        return cell!
    }
}

extension ConfiViewController: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = data[indexPath.row]
        switch item {
        case .scale(let x):
            ProcesserBinder.shared.processer?.scale(scale: x)
        case .blur(_):
            let rect = ProcesserBinder.shared.size
            
            ProcesserBinder.shared.processer?.blur(rect: CGRect.init(x: rect.width / 4, y:rect.height / 4, width: rect.width / 2, height: rect.height/2))
        case .blur2(_):
            let rect = ProcesserBinder.shared.size
            
            ProcesserBinder.shared.processer?.blur2(rect: CGRect.init(x: rect.width / 4, y:rect.height / 4, width: rect.width / 2, height: rect.height/2))
        case .bright(let x):
            ProcesserBinder.shared.processer?.lighten(by: x)
        case .dark(let x):
            ProcesserBinder.shared.processer?.darken(by: x)
        case .gray:
            ProcesserBinder.shared.processer?.gray()
        case .reset:
            ProcesserBinder.shared.reset()
        case .translate(let p):
            ProcesserBinder.shared.processer?.translate(offSet: p)
        case .rotate(let x):
            ProcesserBinder.shared.processer?.rotate(angle: x)
        }
    }
}
