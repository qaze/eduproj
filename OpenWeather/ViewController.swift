//
//  ViewController.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 27.01.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit
import RealmSwift
import FirebaseAuth
import FirebaseAnalytics

class Test : Object {
    @objc dynamic var count = 0
}

class LoginViewController: UIViewController {
    @IBOutlet weak var scrollView: UIScrollView!
    
    @IBOutlet weak var loginTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var loginTitleLabel: UILabel!
    @IBOutlet weak var passwordTitleLabel: UILabel!
    @IBOutlet weak var goButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(hideKeyboard))
        scrollView.addGestureRecognizer(tapGesture)
        
        PurchaseManager.shared.addListener(listener: self)
        titleLabel.isHidden = true
        let recognizer = UIPanGestureRecognizer(target: self, action: #selector(onPan(_:)))
        self.goButton.addGestureRecognizer(recognizer)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShown(notification:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(notification:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        
        animateTitle()
        animateFields()
        animateGoButton()
        animateFieldTitles()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.removeObserver(self, name: UIResponder.keyboardWillHideNotification, object: nil)
    }
    
    @objc func keyboardWillShown( notification: Notification ) {
        let info = notification.userInfo! as NSDictionary
        let size = (info.value(forKey: UIResponder.keyboardFrameEndUserInfoKey) as! NSValue).cgRectValue.size
        
        let contentInsets = UIEdgeInsets(top: 0, left: 0, bottom: size.height, right: 0)
        self.scrollView?.contentInset = contentInsets
        self.scrollView.scrollIndicatorInsets = contentInsets
    }
    
    @objc func keyboardWillHide( notification: Notification ) {
        scrollView.contentInset = .zero
    }
    
    
    func animateTitle() {
        titleLabel.transform = CGAffineTransform(translationX: 0, y: -view.bounds.height / 2)
        UIView.animate(withDuration: 1, 
                       delay: 1, 
                       usingSpringWithDamping: 0.5, 
                       initialSpringVelocity: 0, 
                       options: .curveEaseInOut, 
                       animations: { 
                        self.titleLabel.transform = .identity
        })
    }
    
    
    var interactiveAnimator: UIViewPropertyAnimator!
    
    @objc func onPan(_ recognizer: UIPanGestureRecognizer) {
        switch recognizer.state {
        case .began:
            interactiveAnimator 
                = UIViewPropertyAnimator(duration: 0.5, 
                                         dampingRatio: 0.5, 
                                         animations: {
                                            self.goButton.transform = .init(translationX: 0, y: 200)
                })
            interactiveAnimator.pauseAnimation()
        case .changed:
            let translation = recognizer.translation(in: self.view)
            interactiveAnimator.fractionComplete = translation.y / 200
        case .ended:
            interactiveAnimator.stopAnimation(true)
            interactiveAnimator.addAnimations {
                self.goButton.transform = .identity
            }
            
            interactiveAnimator.startAnimation()
        default: return
        }
    }
    
    
    func animateFieldTitles() {
        let offset = abs(loginTextField.frame.midY - passwordTextField.frame.midY)
        loginTitleLabel.transform = CGAffineTransform(translationX: 0, y: offset)
        passwordTitleLabel.transform = CGAffineTransform(translationX: 0, y: -offset)
        
        UIView.animateKeyframes(withDuration: 1, 
                                delay: 1, 
                                options: [.calculationModeCubicPaced], 
                                animations: {
                                    UIView.addKeyframe(withRelativeStartTime: 0, 
                                                       relativeDuration: 0.5) { 
                                                        self.loginTitleLabel.transform = CGAffineTransform(translationX: 150, y: 50)
                                                        self.passwordTitleLabel.transform = CGAffineTransform(translationX: -150, y: -50)
                                    }
                                    
                                    UIView.addKeyframe(withRelativeStartTime: 0.5, 
                                                       relativeDuration: 0.5) { 
                                                        self.loginTitleLabel.transform = .identity
                                                        self.passwordTitleLabel.transform = .identity
                                    }
        })
    }   
    
    func animateFields() {
        let fadeInAnimation = CABasicAnimation(keyPath: "opacity")
        fadeInAnimation.fromValue = 0
        fadeInAnimation.toValue = 1
        fadeInAnimation.duration = 1
        fadeInAnimation.beginTime = CACurrentMediaTime() + 1
        fadeInAnimation.timingFunction = CAMediaTimingFunction(name: .easeOut)
        fadeInAnimation.fillMode = .backwards
        loginTextField.layer.add(fadeInAnimation, forKey: nil)
        passwordTextField.layer.add(fadeInAnimation, forKey: nil)
    }
    
    func animateGoButton() {
        let scaleAnimation = CASpringAnimation(keyPath: "transform.scale")
        scaleAnimation.fromValue = 0
        scaleAnimation.toValue = 1
        
        scaleAnimation.stiffness = 200
        scaleAnimation.mass = 2
        
        scaleAnimation.beginTime = CACurrentMediaTime() + 1
        scaleAnimation.fillMode = .backwards
        
        goButton.layer.add(scaleAnimation, forKey: nil)
    }
    
    @objc func hideKeyboard() {
        self.scrollView.endEditing(true)
    }
    
    func showAnauthorizedError() {
        let alertVC = UIAlertController(title: "Ошибка", message: "Неверный пароль или логин", preferredStyle: .alert)
        let action = UIAlertAction(title: "Ок", style: .default) { _ in
            print("Ok Clicked")
        }
        alertVC.addAction(action)
        
        present(alertVC, animated: true, completion: nil)
    }
    
    @IBAction func goNext(_ sender: Any) {
        PurchaseManager.shared.makePayment(product: .disable_ads)
        
//        Analytics.logEvent("goNextClicked", parameters: [:])
//        guard let email = loginTextField.text, let password = passwordTextField.text else { return }
//        
//        Auth.auth().signIn(withEmail: email, password: password) { (result, error) in
//            print(result?.user.uid)
//            
//            if result?.user != nil {
//                self.performSegue(withIdentifier: "next", sender: self)
//            }
//        }
    }
    
    func createCities() {
        let cities = [ "Moscow", "Voronezh", "Kazan", "Novosibirsk", "Samara", "Ufa" ]
            .enumerated().map { (offset, value) -> City in
                let city = City()
                city.id = offset
                city.name = value
                return city
        }
        
        do {
            Realm.Configuration.defaultConfiguration = Realm.Configuration(deleteRealmIfMigrationNeeded: true)
            let realm = try Realm()
            print(realm.configuration.fileURL)
            realm.beginWrite()
            realm.add(cities, update: .modified)
            try realm.commitWrite()
        }
        catch {
            print(error.localizedDescription)
        }
        
    }
}

extension LoginViewController: PurchaseListener {
    func productBought(product: Products) {
        if product == .disable_ads {
            titleLabel.isHidden = false
        }
    }
}

