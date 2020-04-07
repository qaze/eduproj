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
    var weatherList: List<Weather>?
    var city: City? 
    
    var notificationToken: NotificationToken?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observeWeathers()
        if let name = name {
            weatherService.loadWeatherData(city: name)
        }
    }
    
    func observeWeathers() {
        guard let city = city else { return }
        weatherList = city.weathers
        notificationToken = city.weathers.observe { (changes) in
            switch changes {
            case .initial:
                self.collectionView.reloadData()
                
            case .update(_, let deletions, let insertions, let modifications):
                self.collectionView.performBatchUpdates({ 
                    self.collectionView.deleteItems(at: deletions.map{ IndexPath(row: $0, section: 0) })
                    self.collectionView.insertItems(at: insertions.map{ IndexPath(row: $0, section: 0) })
                    self.collectionView.reloadItems(at: modifications.map{ IndexPath(row: $0, section: 0) })
                }, completion: nil)
            case .error(let error):
                print(error.localizedDescription)
            }
        }
    }
    
    
    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return weatherList?.count ?? 0
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TestCell", for: indexPath) as? WeatherCell else {
            fatalError()
        }
        
        cell.mainLabel.text = "\(weatherList?[indexPath.row].temp ?? 0)"
        cell.setNeedsLayout()
        cell.layoutIfNeeded()
        
        return cell
    }
}
