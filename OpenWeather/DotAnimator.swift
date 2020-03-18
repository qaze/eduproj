//
//  DotAnimator.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 03.03.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit

class DotAnimator : UIView {
    private var dots: [UIView] = []
    private let duration: Double = 1.0
    private var _animating: Bool = false
    var isAnimating: Bool {
        get {
            return _animating
        }
    }
    
    init(count: Int) {
        super.init(frame: .zero)
        backgroundColor = .white
        translatesAutoresizingMaskIntoConstraints = false
        initDots(count: count)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        dots.forEach{ 
            $0.layer.cornerRadius = $0.frame.width / 2
        }
    }
    
    private func initDots( count: Int ) {
        for i in 0..<count {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.backgroundColor = .gray
            addSubview(dot)
            
            NSLayoutConstraint.activate([
                dot.centerYAnchor.constraint(equalTo: self.centerYAnchor),
                NSLayoutConstraint(item: dot, attribute: .width, relatedBy: .equal, toItem: dot, attribute: .height, multiplier: 1.0, constant: 0.0) 
            ])
            
            let isFirst = i == 0
            let isLast = i == count - 1
            
            if isFirst {
                NSLayoutConstraint.activate([
                    dot.leftAnchor.constraint(equalTo: self.leftAnchor)
                ])
            }
            else {
                NSLayoutConstraint.activate([
                    dot.leftAnchor.constraint(equalTo: dots[i - 1].rightAnchor, constant: 10),
                    dot.widthAnchor.constraint(equalTo: dots[i - 1].widthAnchor)
                ])
            }
            
            
            if isLast {
                NSLayoutConstraint.activate([
                    dot.rightAnchor.constraint(equalTo: self.rightAnchor)
                ])
            }
            
            dots.append(dot)
        }
    }
    
    func startAnimating( completion: @escaping () -> Void ) {
        _animating = true
        
        let relativeDuration = duration / Double(dots.count)
        UIView.animateKeyframes(withDuration: duration, delay: 0, options: [.autoreverse], animations: {
            self.dots.enumerated().forEach{ (arg) in
                let (index, dot) = arg
                let startTime = Double(index) / Double(self.dots.count)
                UIView.addKeyframe(withRelativeStartTime: startTime, relativeDuration: relativeDuration) { 
                    dot.alpha = 0.3
                }
            }
        }) { _ in
            completion()
        }
    }
    
    func stopAnimation() {
        _animating = false
        dots.forEach{
            $0.alpha = 1
            $0.layer.removeAllAnimations()
        }
    }
}
