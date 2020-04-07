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
    func loadWeatherData( city: String)
}


protocol WeatherParser {
    func parse( data: Data ) -> [Weather]
}


class SerializerParser: WeatherParser {
    func parse(data: Data) -> [Weather] {
        do{
            let json = try JSONSerialization.jsonObject(with: data, options: .mutableContainers)
            
            guard let jsonParsed = json as? [String: Any],
                let list = jsonParsed["list"] as? [Any] else { return [] }
            
            
            let result = list.compactMap { raw -> Weather? in 
                guard let item = raw as? [String:Any],
                    let date = item["dt"] as? Double else { return nil }
                
                guard let main = item["main"] as? [String:Any],
                    let temp = main["temp"] as? Double,
                    let pressure = main["pressure"] as? Double,
                    let humidity = main["humidity"] as? Int else { return nil }
                
                
                guard let weatherValues = item["weather"] as? [Any],
                    let firstWeatherValues = weatherValues.first as? [String:Any],
                    let weatherName = firstWeatherValues["main"] as? String,
                    let weatherIcon = firstWeatherValues["icon"] as? String else { return  nil }
                
                
                guard let windValues = item["wind"] as? [String: Any],
                    let windSpeed = windValues["speed"] as? Double,
                    let windDegrees = windValues["deg"] as? Double else { return nil }
                
                var weather = Weather()
                
                weather.date = date
                weather.temp = temp
                weather.pressure = pressure
                weather.humidity = humidity
                weather.weatherName = weatherName
                weather.weatherIcon = weatherIcon
                weather.windSpeed = windSpeed
                weather.windDegrees = windDegrees
                
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



class URLSessionWeatherService: WeatherServiceProtocol {
    let baseUrl = "api.openweathermap.org"
    let parser: WeatherParser
    
    init(parser: WeatherParser) {
        self.parser = parser
    }
    
    func loadWeatherData( city: String ) {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_KEY") as? String else { return }
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        
        var components = URLComponents()
        components.scheme = "http"
        components.host = baseUrl
        components.path = "/data/2.5/forecast"
        
        components.queryItems = [
            URLQueryItem(name: "q", value: city),
            URLQueryItem(name: "units", value: "metric"),
            URLQueryItem(name: "appid", value: apiKey)
        ]
        
        
        do {
            let request = try URLRequest(url: components.url!, method: .get)
            let task = session.dataTask(with: request) { (data, response, error) in
                guard let data = data else {
                    return
                }
                
                var weathers: [Weather] = self.parser.parse(data: data)
                print(weathers)
            }
            
            task.resume()
        }
        catch {
            print(error.localizedDescription)
        }
    }
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
    
    func loadWeatherData( city: String ) {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_KEY") as? String else { return }
        let path = "/data/2.5/forecast"
        
        let paramaters: Parameters = [
            "q" : city,
            "units": "metric",
            "appid": apiKey
        ]
        
        let url = baseUrl + path
        
        AF.request(url, parameters: paramaters).responseJSON { (response) in
            if let error = response.error {
                print(error)
            }
            else {
                guard let data = response.data else { return }
                
                var weathers: [Weather] = self.parser.parse(data: data)
                self.save(weathers: weathers, for: city)
                print(weathers)
            }
        }
    }
}
