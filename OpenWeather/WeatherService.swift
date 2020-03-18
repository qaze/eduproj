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

class WeatherResponse: Decodable {
    var list: [Weather]
}

//struct MainInfo: Codable {
//    var temp = 0.0
//    var pressure = 0.0
//    var humidity = 0
//}
//
//struct WeatherInfo: Codable {
//    var name = ""
//    var icon = ""
//    
//    enum CodingKeys: String, CodingKey {
//        case name = "main"
//        case icon
//    }
//}
//
//struct WindInfo: Codable {
//    var speed = 0.0
//    var deg = 0.0
//}
//
//struct Weather: Codable {
//    var date = 0.0
//    var main: MainInfo
//    var weather: [WeatherInfo]
//    var wind: WindInfo
//    
//    enum CodingKeys: String, CodingKey {
//        case date = "dt"
//        case main
//        case weather
//        case wind
//    }
//}

class Weather: Decodable {
    var date = 0.0
    var temp = 0.0
    var pressure = 0.0
    var humidity = 0
    var weatherName = ""
    var weatherIcon = ""
    var windSpeed = 0.0
    var windDegrees = 0.0
    
    enum CodingKeys: String, CodingKey {
        case date = "dt"
        case main
        case weather
        case wind
    }
    
    enum MainKeys: String, CodingKey {
        case temp
        case pressure
        case humidity
    }
    
    enum WeatherKeys: String, CodingKey {
        case main
        case icon
    }
    
    enum WindKeys: String, CodingKey {
        case speed
        case deg
    }
    
    
    convenience required init(from decoder: Decoder) throws {
        self.init()
        
        let values = try decoder.container(keyedBy: CodingKeys.self)
        self.date = try values.decode(Double.self, forKey: .date)
        
        let mainValues = try values.nestedContainer(keyedBy: MainKeys.self, forKey: .main)
        self.temp = try mainValues.decode(Double.self, forKey: .temp)
        self.pressure = try mainValues.decode(Double.self, forKey: .pressure)
        self.humidity = try mainValues.decode(Int.self, forKey: .humidity)
        
        var weatherValues = try values.nestedUnkeyedContainer(forKey: .weather)
        let firstWeatherValues = try weatherValues.nestedContainer(keyedBy: WeatherKeys.self)
        self.weatherName = try firstWeatherValues.decode(String.self, forKey: .main)
        self.weatherIcon = try firstWeatherValues.decode(String.self, forKey: .icon)
        
        let windValues = try values.nestedContainer(keyedBy: WindKeys.self, forKey: .wind)
        self.windSpeed = try windValues.decode(Double.self, forKey: .speed)
        self.windDegrees = try windValues.decode(Double.self, forKey: .deg)
    }
    
}

protocol WeatherServiceProtocol {
    func loadWeatherData( city: String, completion: @escaping ([Weather]) -> Void )
}


protocol WeatherParser {
    func parse( data: Data ) -> [Weather]
}


class CodableParser: WeatherParser {
    func parse(data: Data) -> [Weather] {
        do {
            let weather = try JSONDecoder().decode(WeatherResponse.self, from: data).list
            return weather
        }
        catch {
            print(error.localizedDescription)
            return []
        }
    }
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
    
    func loadWeatherData( city: String, completion: @escaping ([Weather]) -> Void ) {
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
            let task = session.dataTask(with: request) { [completion] (data, response, error) in
                guard let data = data else {
                    return
                }
                
                var weathers: [Weather] = self.parser.parse(data: data)
                print(weathers)
                completion(weathers)
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
    
    init(parser: WeatherParser) {
        self.parser = parser
    }
    
    func loadWeatherData( city: String, completion: @escaping ([Weather]) -> Void ) {
        guard let apiKey = Bundle.main.object(forInfoDictionaryKey: "OPENWEATHER_KEY") as? String else { return }
        let path = "/data/2.5/forecast"
        
        let paramaters: Parameters = [
            "q" : city,
            "units": "metric",
            "appid": apiKey
        ]
        
        let url = baseUrl + path
        
        AF.request(url, parameters: paramaters).responseJSON { [completion] (response) in
            if let error = response.error {
                print(error)
            }
            else {
                guard let data = response.data else { return }
                
                var weathers: [Weather] = self.parser.parse(data: data)
                print(weathers)
                
                completion(weathers)
            }
        }
    }
}
