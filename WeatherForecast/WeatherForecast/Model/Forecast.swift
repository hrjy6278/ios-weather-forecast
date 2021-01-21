//
//  Forecast.swift
//  WeatherForecast
//
//  Created by Yeon on 2021/01/18.
//

import Foundation

struct Forecast: Decodable {
    let dateTime: String
    let weatehrIcon: [WeatherIcon]
    let temperature: Temperature
    
    enum CodingKeys: String, CodingKey {
        case dateTime = "dt_txt"
        case weatehrIcon = "weather"
        case temperature = "main"
    }
}
