//
//  CustomAnimationTransitioning.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 29.02.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit


class CustomAnimationTransitioning: NSObject, UIViewControllerAnimatedTransitioning {
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 1
    }
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        guard let source = transitionContext.viewController(forKey: .from),
            let destination = transitionContext.viewController(forKey: .to) else { return }
        
        let container = transitionContext.containerView
        
        let containerViewFrame = container.frame
        let sourceViewTargetFrame = CGRect(x: 0, 
                                           y: -containerViewFrame.height, 
                                           width: source.view.frame.width, 
                                           height: source.view.frame.height)
        
        let destinationViewTargetFrame = source.view.frame
        container.addSubview(destination.view)
        
        destination.view.frame = CGRect(x: 0, 
                                        y: containerViewFrame.height, 
                                        width: source.view.frame.width, 
                                        height: source.view.frame.height)
        
        
        UIView
            .animate(withDuration: 0.5, animations: { 
                source.view.frame = sourceViewTargetFrame
                destination.view.frame = destinationViewTargetFrame
            }) { result in
                transitionContext.completeTransition(result)
        }
    }
}
