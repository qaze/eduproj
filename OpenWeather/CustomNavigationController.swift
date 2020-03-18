//
//  CustomNavigationController.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 29.02.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit

class CustomNavigationViewController: UINavigationController, UINavigationControllerDelegate {
    private let interactiveTransition = CustomInteractiveTransition()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        delegate = self
    }
    
    func navigationController(_ navigationController: UINavigationController, 
                              interactionControllerFor animationController: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return interactiveTransition.hasStarted ? interactiveTransition : nil
    }
    
    func navigationController(_ navigationController: UINavigationController, 
                              animationControllerFor operation: UINavigationController.Operation, 
                              from fromVC: UIViewController, 
                              to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        
        if operation == .push {
            interactiveTransition.viewController = toVC
            return CustomPushAnimator()
        }
        else if operation == .pop {
            if navigationController.viewControllers.first != toVC {
                interactiveTransition.viewController = toVC
                
            }
            
            return CustomPopAnimator()
        }
        
        return nil
    }
}
