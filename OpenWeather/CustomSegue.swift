//
//  CustomSegue.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 29.02.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit


class CustomSegue: UIStoryboardSegue {
    override func perform() {
        guard let container = source.view.superview else { return }
        
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
                self.source.view.frame = sourceViewTargetFrame
                self.destination.view.frame = destinationViewTargetFrame
            }) { result in
                self.source.present( self.destination, 
                                     animated: false) { 
                                        self.source.view.frame = destinationViewTargetFrame
                }
        }
    }
}

