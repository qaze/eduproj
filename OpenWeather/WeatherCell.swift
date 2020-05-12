//
//  WeatherCell.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 13.03.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit
import PromiseKit

class WeatherCell : UICollectionViewCell {
    @IBOutlet weak var mainLabel: UILabel!
    @IBOutlet weak var weatherIcon: UIImageView!
    
    @IBOutlet weak var shadowView: UIView! {
        didSet {
            self.shadowView.layer.shadowOffset = .zero
            self.shadowView.layer.shadowOpacity = 0.75
            self.shadowView.layer.shadowRadius = 6
            self.shadowView.backgroundColor = .clear
            self.shadowView.clipsToBounds = false
        }
    }
    
    @IBOutlet weak var containerView: UIView! {
        didSet {
            self.containerView.clipsToBounds = true
        }
    }
    
    
    override func layoutIfNeeded() {
        super.layoutIfNeeded()
        self.shadowView.layer.shadowPath = UIBezierPath(ovalIn: self.shadowView.bounds).cgPath
        self.containerView.layer.cornerRadius = self.containerView.frame.height / 2
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    @objc func tapped(_ sender: UITapGestureRecognizer) {
        mainLabel.text = "Hello, world!"
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        mainLabel.text = "Label"
    }
}
