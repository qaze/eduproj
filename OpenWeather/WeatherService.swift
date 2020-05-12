//
//  WeatherService.swift
//  OpenWeather
//
//  Created by Nik Rodionov on 13.03.2020.
//  Copyright © 2020 nrodionov. All rights reserved.
//

import Foundation
import Alamofire
import SwiftyJSON
import RealmSwift
import PromiseKit

class City: Object {
    @objc dynamic var name: String = ""
    @objc dynamic var id: Int = 0
    var weathers: List<Weather> = .init()
    
    override class func primaryKey() -> String? {
        return "id"
    }
}

class Weather: Object {
    @objc dynamic var date = 0.0
    @objc dynamic var temp = 0.0
    @objc dynamic var pressure = 0.0
    @objc dynamic var humidity = 0
    @objc dynamic var weatherName = ""
    @objc dynamic var weatherIcon = ""
    @objc dynamic var windSpeed = 0.0
    @objc dynamic var windDegrees = 0.0
}

protocol WeatherServiceProtocol {
    func loadWeatherData( city: String ) -> Promise<String>
    func loadImageData( for path: String ) -> Promise<UIImage>
}


protocol WeatherParser {
    func parse( data: Data ) -> [Weather]
}


class SwiftyJSONParser: WeatherParser {
    func parse(data: Data) -> [Weather] {
        do {
            let json = try JSON(data: data)
            let array = json["list"].arrayValue
            
            let result = array.map { item -> Weather in
                let weather = Weather()
                weather.date = item["dt"].doubleValue
                
                let main = item["main"]
                weather.temp = main["temp"].doubleValue
                weather.pressure = main["pressure"].doubleValue
                weather.humidity = main["humidity"].intValue
                
                let weatherValues = item["weather"].arrayValue
                if let first = weatherValues.first {
                    weather.weatherName = first["main"].stringValue
                    weather.weatherIcon = first["icon"].stringValue
                }
                
                let windValues = item["wind"]
                weather.windSpeed = windValues["speed"].doubleValue
                weather.windDegrees = windValues["deg"].doubleValue
                
                return weather
            }
            
            return result
        }
        catch {
            print(error.localizedDescription)
            return []
        }
    }
}


class AlamofireWeatherService: WeatherServiceProtocol {
    let baseUrl = "http://api.openweathermap.org"
    let parser: WeatherParser
    
    enum ServiceError: Error {
        case notFound, noApiKey
    }
    
    func save( weathers: [Weather], for cityName: String ) {
        do {
            let realm = try Realm()
            guard let city = realm.objects(City.self).filter("name = %@", cityName).first else { return }
            realm.beginWrite()
            if city.weathers.count > 0 {
                realm.delete(city.weathers)
            }
            
            city.weathers.append(objectsIn: weathers)
            try realm.commitWrite()
        }
        catch {
            print(error.localizedDescription)
        }
    }
    
    init(parser: WeatherParser) {
        self.parser = parser
    }
    
    func loadImageData( for path: String ) -> Promise<UIImage> {
        guard let url = URL(string: path) else { return Promise(error: ServiceError.notFound) }
        
        
        return URLSession.shared.dataTask(.promise, with: url) // Promise<(Data, Response)>
            .then(on: DispatchQueue.global()) { (data, response) -> Promise<UIImage> in
                if let image = UIImage(data: data) {
                    return Promise.value(image)
                }
                else {
                    return Promise(error: ServiceError.notFound)
                }
        }
    }
    
    func loadWeatherData( city: String ) -> Promise<String> {
        return Promise { (resolver) in
            guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_KEY") as? String else { resolver.reject(ServiceError.noApiKey); return }
            let path = "/data/2.5/forecast"
            
            let paramaters: Parameters = [
                "q" : city,
                "units": "metric",
                "appid": apiKey
            ]
            
            let url = baseUrl + path
            
            Alamofire.request(url, parameters: paramaters).responseJSON { (response) in
                if let error = response.error {
                    print(error)
                }
                else {
                    guard let data = response.data else { return }
                    
                    var weathers: [Weather] = self.parser.parse(data: data)
                    self.save(weathers: weathers, for: city)
                    print(weathers)
                    
                    resolver.fulfill(city)
                }
            }
            
        }
    }
}
