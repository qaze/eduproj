//
//  CustomInteractiveTransition.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 29.02.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit

class CustomInteractiveTransition: UIPercentDrivenInteractiveTransition {
    var viewController: UIViewController? {
        didSet {
            let recongizer = UIScreenEdgePanGestureRecognizer(target: self, action: #selector(handleScreenEdgeGesture(_:)) )
            recongizer.edges = [.left]
            viewController?.view.addGestureRecognizer(recongizer)
        }
    }
    
    var hasStarted: Bool = false
    var shouldFinish: Bool = false
    
    @objc func handleScreenEdgeGesture(_ gesture: UIScreenEdgePanGestureRecognizer) {
        switch gesture.state {
        case .began:
            hasStarted = true
            viewController?.navigationController?.popViewController(animated: true)
            
        case .changed:
            let translation = gesture.translation(in: gesture.view)
            let relativeTransition = translation.x / (gesture.view?.bounds.width ?? 1)
            let progress = max(0, min(1, relativeTransition)) // 0 <= progress <= 1
            shouldFinish = progress > 0.33
            update(progress)
            
        case .ended:
            hasStarted = false
            if shouldFinish {
                finish()
            }
            else {
                cancel()
            }
            
        case .cancelled:
            hasStarted = false
            cancel()
            
        default:
            return
        }
        
    }
}
