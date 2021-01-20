
import Foundation

enum SystemFeature {
    case currentWeather
    case fiveDaysForecasting
    
    var pathKeyword: String {
        switch self {
        case .currentWeather:
            return "weather"
        case .fiveDaysForecasting:
            return "forecast"
        }
    }
}

enum NetworkError: Error {
    case invalidData
    case invalidValue
}

struct ForecastingSystem {
    private let myKey = "2ce6e0d6185aa981602d52eb6e89fa16"
    private let baseURL = "https://api.openweathermap.org/data/2.5"
    private var requestCall: URL?
    private let coordinateToSearch = GeographicCoordinate(latitude: 37.4943514, longitude: 127.0633398)
    
    func makeModel(responding feature: SystemFeature) {
        guard let requestCall = makeRequestCall(for: feature) else {
            print("URL 생성 실패")
            return
        }
        
        switch feature {
        case .currentWeather:
            matchDataWithCurrentWeather(with: requestCall) { result in
                switch result {
                case .success(let forecastInformation):
                    print(forecastInformation)
                case .failure(let error):
                    print(error)
                }
            }
        case .fiveDaysForecasting:
            matchDataWithFiveDaysForecasting(with: requestCall) { result in
                switch result {
                case .success(let forecastInformation):
                    print(forecastInformation)
                case .failure(let error):
                    print(error)
                }
            }
        }
    }
}
extension ForecastingSystem {
    private func makeRequestCall(for feature: SystemFeature) -> URL? {
        let requestURL = URL(string: "\(baseURL)/\(feature.pathKeyword)?lat=\(coordinateToSearch.latitude)&lon=\(coordinateToSearch.longitude)&units=metric&appid=\(myKey)")
        return requestURL
    }
    
    private func matchDataWithCurrentWeather(with requestURL: URL, completion: @escaping (Result<CurrentWeatherInformation, NetworkError>) -> Void) {
        let urlSession = URLSession.shared
        let dataTask = urlSession.dataTask(with: requestURL) { (data, response, error) in
            guard let receivedData = data else {
                completion(.failure(.invalidData))
                return
            }
            
            do {
                let forecastInformation = try JSONDecoder().decode(CurrentWeatherInformation.self, from: receivedData)
                completion(.success(forecastInformation))
            } catch {
                completion(.failure(.invalidValue))
            }
        }
        dataTask.resume()
    }
    
    private func matchDataWithFiveDaysForecasting(with requestURL: URL, completion: @escaping (Result<FiveDaysForecastingInformation, NetworkError>) -> Void) {
        let urlSession = URLSession.shared
        let dataTask = urlSession.dataTask(with: requestURL) { (data, response, error) in
            guard let receivedData = data else {
                completion(.failure(.invalidData))
                return
            }
            
            do {
                let forecastInformation = try JSONDecoder().decode(FiveDaysForecastingInformation.self, from: receivedData)
                completion(.success(forecastInformation))
            } catch {
                completion(.failure(.invalidValue))
            }
        }
        dataTask.resume()
    }
}
