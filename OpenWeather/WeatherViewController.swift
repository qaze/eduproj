//
//  WeatherViewController.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 13.03.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import UIKit
import RealmSwift

class WeatherViewController: UICollectionViewController {
    let weatherService: WeatherServiceProtocol = AlamofireWeatherService(parser: SwiftyJSONParser())
    
    var name: String?
    var weatherList: [Weather] = []
    var city: City? 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        if let name = name {
            weatherService.loadWeatherData(city: name) {
                self.loadData()
                self.collectionView.reloadData()
            }
        }
    }
    
    func loadData() {
        guard let city = city else { return }
        weatherList = Array(city.weathers)
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weatherList.count
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TestCell", for: indexPath) as? WeatherCell else {
            fatalError()
        }
        
        cell.mainLabel.text = "\(weatherList[indexPath.row].temp)"
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        return cell
    }
}
