# README.md

# 날씨정보 프로젝트

- **팀 구성원 : YesCoach(YesCoach) Jiss(hrjy6278)**
- **프로젝트 기간 : 2021.09.27 ~ 10.08**

## 목차

1. [**기능구현**](I.-기능-구현)
2. [**이를 위한 설계**](II.-이를-위한-설계)
3. [**Trouble Shooting**](III.-트러블-슈팅)
4. [**아쉽거나 해결하지 못한 부분**](IV.-해결하지-못한-문제)
5. [**관련 학습내용**](V.-관련-학습-내용)

## I. 기능 구현

- **범용성, 재사용성이 가능한 네트워크 모델 타입 구현**
- **`CodingKey`를 활용한 `Decodable` 모델 타입 구현**
- `**Core Location**` **을 활용한 현재 위치 정보 수신 기능 구현**

## II. 이를 위한 설계

### 1. 네트워크 모델 타입 설계
<details>
<summary>NetworkManager(네트워크 모델) 타입 코드</summary>
    
    ```swift
    enum NetworkError: Error {
        case invalidRequest
        case invalidResponse
    }
    
    class NetworkManager {
        private let session: URLSession
    
        init(session: URLSession = URLSession.shared) {
            self.session = session
        }
    
    func dataTask(url: URL, completion: @escaping (Result<Data, NetworkError>) -> Void) {
        session.dataTask(with: url) { data, response, error in
            guard error == nil else {
                completion(.failure(.invalidRequest))
                return
            }
    
            guard let response = response as? HTTPURLResponse,
            (200...299).contains(response.statusCode) else {
                completion(.failure(.invalidResponse))
                return
            }
    
            if let data = data {
                completion(.success(data))
                }
            }.resume()
        }
    
    protocol API {
        var url: String { get }
    }
    
    protocol Query {
        var description: String { get }
    }
    
    //프로토콜을 채택하고 준수한 타입
    
    enum WeatherAPI: API {
        static let baseURL = "https://api.openweathermap.org/data/2.5/"
    
        case current
        case forecast
    
        var url: String {
            switch self {
            case .current:
               return Self.baseURL + "weather"
            case .forecast:
               return Self.baseURL + "forecast"
            }
        }
    }
    
    enum CoordinatesQuery: Query {
        case lat
        case lon
        case appid
    
        var description: String {
            switch self {
            case .lat:
                return "lat"
            case .lon:
                return "lon"
            case .appid:
                return "appid"
            }
        }
    }
    
    // URL을 만들어 주는 메소드
    extension URL {
    func createURL<T: Query>(API: API, queryItems: [T: String]) -> URL? {
        var componets = URLComponents(string: API.url)
    
        for (key, value) in queryItems {
            let queryItem = URLQueryItem(name: key.description, value: value)
            componets?.queryItems?.append(queryItem)
        }
    
        return componets?.url
    	}
    }
    
    ```
</details>

<details>
    <summary>네트워크 모델 타입의 설계 이유</summary>
    1. 해당 네트워크 모델 타입 `NetworkManager` 는 해당 프로젝트 뿐만 아니라, 다른 프로젝트에서도 사용이 될 수 있게끔 생각을 가지고 구현을 해보았다. 초기화시에 `URLSession` 타입을 **주입**받도록 설계하였다.
    네트워크 통신을 하여 `Data` 타입을 받아오는`dataTask(url:completion:)` 메서드를 구현하였다.
    `dataTask(url:completion:)`은 **비동기**로 실행되는 메서드이기 때문에 값을 `return` 해 주는게 아닌 `completion` 파라미터로 **함수타입**을 받도록하여 완료되었을때의 행동을 구현하였다
    2. `createURL(API:queryItems:) -> URL?` 메서드를  URL 타입의의 `Extension` 으로 구현하여 `URL`를 설정하고 `URL`을 `return` 해주는 메서드를 구현하였다. 해당 메서드는 **범용성**과, **재사용성**을 높이기 위해 **제네릭 타입**과, **프로토콜**을 적극적으로 활용하였다. 매개변수 `API`는 `Protocol API` 타입만 받도록 설계하여 유연성을 높였다.
    또 다른 파라미터인 `queryItems`는 딕셔너리로써 키에 **제네릭 타입**인 `T`를 받도록 하였고,
    `T`는 프로토콜인 `Query`를 만족하는 타입은 전부 사용가능 하게 끔 만들었다.
    메서드 내부에서는 `URLComponents` 인스턴스를 활용하여 구현하였다.
    딕셔너리인 `quertItems` 를 순회하면서 `URLQueryItem` 를 만들어 주었고 `URLQueryItem` 인스턴스 생성시 `name` 과 `value` 는 딕셔너리의 **Key** 와 **value** 를 활용하였다.
    `URLQueryItem`이 인스턴스가 만들어졌으면, `URLComponents` 인스턴스의 프로퍼티인 `queryItems`에 **Append**를 해주었다.
    작업이 다 완료되었으면 `URLComponents`에 `url` 프로퍼티를 사용하여 `URL`을 `return` 하도록 설계하였다.
</details>

### 2.`CodingKey`를 활용한 `Decodable` 모델 타입 구현
    
<details>
    <summary>CurrentWeather(현재 날씨정보) Decodable 모델 타입 코드</summary>
    
    ### CurrentWeather 타입 코드
    
    ```
    struct CurrentWeather: Decodable {
        let coordinate: Coordinate
        let weather: [Weather]
        let base: String
        let main: Main
        let wind: Wind
        let clouds: Clouds
        let rain: Rain?
        let snow: Snow?
        let dataReceivingTime: TimeInterval
        let system: System
        let timezone: TimeInterval
        let id: Int
        let name: String
        let cod: Int
    
        enum CodingKeys: String, CodingKey {
            case weather, base, main, wind, clouds, rain, snow, timezone, id, name, cod
            case coordinate = "coord"
            case dataReceivingTime = "dt"
            case system = "sys"
        }
    
        struct Coordinate: Decodable {
            let lon: Double
            let lat: Double
        }
    
        struct Weather: Decodable {
            let id: Int
            let main: String
            let description: String
            let icon: String
        }
    
        struct Main: Decodable {
            let temp: Double
            let feelsLike: Double
            let tempMin: Double
            let tempMax: Double
            let pressure: Int
            let humidity: Int
    
            enum CodingKeys: String, CodingKey {
                case temp, pressure, humidity
                case feelsLike = "feels_like"
                case tempMin = "temp_min"
                case tempMax = "temp_max"
            }
        }
    
        struct Wind: Decodable {
            let speed: Double
            let deg: Double
            let gust: Double
        }
    
        struct Clouds: Decodable {
            let all: Int
        }
    
        struct Rain: Decodable {
            let oneHour: Double
            let threeHour: Double
    
            enum CodingKeys: String, CodingKey {
                case oneHour = "1h"
                case threeHour = "3h"
            }
        }
    
        struct Snow: Decodable {
            let oneHour: Double
            let threeHour: Double
    
            enum CodingKeys: String, CodingKey {
                case oneHour = "1h"
                case threeHour = "3h"
            }
        }
    
        struct System: Decodable {
            let type: Int
            let id: Int
            let message: Double?
            let country: String
            let sunrise: TimeInterval
            let sunset: TimeInterval
        }
        }
    
    ```
</details>

<details>
    <summary>ForecastWeather(날씨 예보) Decodable 모델 타입 코드</summary>
    
    ### ForecastWeather 타입 코드
    
    ```
    struct ForecastWeather: Decodable {
        let cod: String
        let message: Int
        let cnt: Int
        let list: [List]
        let city: City
    
        struct List: Decodable {
            let dataReceivingTime: TimeInterval
            let main: Main
            let weather: [Weather]
            let clouds: Clouds
            let wind: Wind
            let visibility: Int
            let probabilityOfPrecipitation: Double
            let rain: Rain?
            let snow: Snow?
            let system: System
            let dataReceivingTimeText: String
    
            enum CodingKeys: String, CodingKey {
                case main, weather, clouds, wind, visibility, rain, snow
                case dataReceivingTime = "dt"
                case probabilityOfPrecipitation = "pop"
                case system = "sys"
                case dataReceivingTimeText = "dt_txt"
            }
        }
    
        struct Main: Decodable {
            let temp: Double
            let feelsLike: Double
            let tempMin: Double
            let tempMax: Double
            let pressure: Int
            let seaLevel: Int
            let grndLevel: Int
            let humidity: Int
            let tempKF: Double
    
            enum CodingKeys: String, CodingKey {
                case temp, pressure, humidity
                case feelsLike = "feels_like"
                case tempMin = "temp_min"
                case tempMax = "temp_max"
                case seaLevel = "sea_level"
                case grndLevel = "grnd_level"
                case tempKF = "temp_kf"
            }
        }
    
        struct Weather: Decodable {
            let id: Int
            let main: String
            let description: String
            let icon: String
        }
    
        struct Clouds: Decodable {
            let all: Int
        }
    
        struct Wind: Decodable {
            let speed: Double
            let deg: Double
            let gust: Double
        }
    
        struct Rain: Decodable {
            let threeHour: Double
    
            enum CodingKeys: String, CodingKey {
                case threeHour = "3h"
            }
        }
    
        struct Snow: Decodable {
            let threeHour: Double
    
            enum CodingKeys: String, CodingKey {
                case threeHour = "3h"
            }
        }
    
        struct System: Decodable {
            let partOfDay: String
    
            enum Codingkeys: String, CodingKey {
                case partOfDay = "pod"
            }
        }
    
        struct City: Decodable {
            let id: Int
            let name: String
            let coordinate: Coordinate
            let country: String
            let timezone: TimeInterval
            let sunrise: TimeInterval?
            let sunset: TimeInterval?
    
            enum Codingkeys: String, CodingKey {
                case id, name, country, timezone, sunrise, sunset
                case coordinate = "coord"
            }
        }
    
        struct Coordinate: Decodable {
            let lat: Double
            let lon: Double
        }
    }
    
    ```
</details>

<details>
    <summary>Decodable한 모델 타입 설계와 그 이유</summary>
    
    CodingKey를 활용하여 Snake Case 나 줄임말이 포함된 `key` 가 있는 경우 다른 개발자가 보더라도 해당 프로퍼티들이 어떤 Data들을 가지고 있을지에 대하여 한눈에 알 수 있도록 최대한 고쳐보았다.
    
    각각의 타입에 대해 중복되는 Type 을 Nested Type이 아닌 일반 타입으로 구현하려고 했었으나, 타입안에 Key 값들이 다른경우가 있어  Nested type 으로 설계하였다. 
</details>

 

### 3.`Core Location` 을 활용한 현재 위치 정보 수신 기능 구현

<details>
    <summary>LocationManagerDelegate 프로토콜과 LocationManager 타입 코드</summary>
    
    ```swift
    import CoreLocation
    
    protocol LocationManagerDelegate: AnyObject {
        func didUpdateLocation(_ location: CLLocation)
    }
    
    enum LocationManagerError: Error {
        case emptyPlacemark
        case invalidLocation
    }
    
    class LocationManager: NSObject {
        private var manager: CLLocationManager?
        private var currentLocation: CLLocation?
        **weak var delegate: LocationManagerDelegate?**
    
        init(manager: CLLocationManager = CLLocationManager()) {
            super.init()
            self.manager = manager
            self.manager?.delegate = self
            self.manager?.desiredAccuracy = kCLLocationAccuracyBest
        }
    
        func getCoordinate() -> CLLocationCoordinate2D? {
            return currentLocation?.coordinate
        }
    
        func getAddress(completion: @escaping (Result<CLPlacemark, Error>) -> Void) {
            guard let currentLocation = currentLocation else {
                return
            }
            CLGeocoder().reverseGeocodeLocation(currentLocation, preferredLocale: Locale.current) { placemark, error in
                guard error == nil else {
                    return completion(.failure(LocationManagerError.invalidLocation))
                }
                guard let placemark = placemark?.last else {
                    return completion(.failure(LocationManagerError.emptyPlacemark))
                }
                completion(.success(placemark))
            }
        }
    }
    
    extension LocationManager: CLLocationManagerDelegate {
        func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
            switch status {
            case .notDetermined:
                manager.requestWhenInUseAuthorization()
            case .authorizedWhenInUse, .authorizedAlways:
                manager.requestLocation()
            case .denied, .restricted:
                print("권한없음")
            default:
                print("알수없음")
            }
        }
    
        func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.last else {
                return
            }
            currentLocation = location
            **delegate?.didUpdateLocation(location)**
        }
    
        func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
            manager.stopUpdatingLocation()
        }
    }
    ```
</details>
<details>
    <summary>ViewController 코드</summary>
    
    ```swift
    import UIKit
    import CoreLocation
    class ViewController: UIViewController {
    
        private var locationManager = LocationManager()
        private var networkManager = NetworkManager()
        private var currentData: CurrentWeather?
        private var forecastData: ForecastWeather?
    
        override func viewDidLoad() {
            super.viewDidLoad()
            locationManager.delegate = self
        }
    }
    
    extension ViewController: LocationManagerDelegate {
        func didUpdateLocation(_ location: CLLocation) {
            fetchingWeatherData(api: WeatherAPI.current, type: CurrentWeather.self)
            fetchingWeatherData(api: WeatherAPI.forecast, type: ForecastWeather.self)
        }
    
        func fetchingWeatherData<T: Decodable>(api: WeatherAPI, type: T.Type) {
            guard let coordinate = locationManager.getCoordinate() else {
                return
            }
    
            let queryItems = [CoordinatesQuery.lat: String(coordinate.latitude),
                              CoordinatesQuery.lon: String(coordinate.longitude),
                              CoordinatesQuery.appid: "e6f23abdc0e7e9080761a3cfbbdafc90"]
    
            guard let url = URL.createURL(API: api, queryItems: queryItems) else { return }
            networkManager.dataTask(url: url) { result in
                if case .success(let data) = result {
                    let data = try? JSONDecoder().decode(type, from: data)
                    print(data)
                }
            }
        }
    ```
</details>
    
<details>
    <summary>LocationManager 타입 설계와 그 이유</summary>
    
    ViewController에서 직접 하는 것이 아닌 따로 타입을 분리하고자 LocationManager를 생성하였다.
    
    - `CLLocationManager`를 주입받아 Core Location을 수행하는 **LocationManager** 타입 구현하였다.
    - `CLLocationManagerDelegate`를 채택하여 `didChangeAuthorization`, `didUpdateLocations`, `didFailWithError` 메서드를 구현하였다.
    - Location이 변하는 시점에 서버로부터 해당 Location 값을 가지고 데이터를 받아오기 위해서, `delegate` 패턴을 사용

</details>
    
## III. 트러블 슈팅

1. 프로젝트 포크 직후 AppDelegate와 SceneDelegate에서 `'***' is only available in iOS 13.0 or newer` 에러 발생.
    
    원인 : Targets → WeatherForecast → Deployment Info 의 ios 버전이 iOS 12.1로 설정되어 있었음. iOS 13부터 UIScene 개념이 등장함에 따라서 UISceneSession Lifecycle을 AppDelegate에서 관리할 경우 iOS 13 이후의 버전으로 타겟 설정을 해야함
    
    해결방법 : 해당 버전을 iOS 13.0 으로 상향 설정하였음. PROJECT의 DeploymentTarget과 TARGETS의 DeploymentTarget이 다르면 기본적으로 TARGETS의 DeploymentTarget이 minimum target 이 된다.
![스크린샷 2021-10-08 18 02 56](https://user-images.githubusercontent.com/59643667/136529281-fd78e9a0-297a-4359-8726-d000f7edb068.png)
[수정전]
![스크린샷 2021-10-08 18 03 14](https://user-images.githubusercontent.com/59643667/136529313-4df98a71-c740-4ca4-87bd-c4dcb0d841f4.png)
[수정후]

    
2. API와 쿼리를 통해 URL을 생성하는데, 쿼리 부분이 담기지 않고 URL이 리턴되었음. 
    
    원인 : `URLComponents`의 `queryItems` 에 `URLQueryItem`이 append되지 않았는데, 생성해준 URLComponents 객체의 queryItems가 nil 이였기 때문임을 확인했다.
    
    해결방법 : `queryItems` 프로퍼티에 직접 append하지 않고, 새로운 배열에 append 한 다음 직접 할당함.
    
    ```swift
    extension URL {
        static func createURL<T: Query>(API: API, queryItems: [T: String]) -> URL? {
            var components = URLComponents(string: API.url)
            var queryArray: [URLQueryItem] = []
            for (key, value) in queryItems {
                let queryItem = URLQueryItem(name: key.description, value: value)
                queryArray.append(queryItem)
            }
            componets?.queryItems = queryArray
            return componets?.url
        }
    }
    ```
    
3. 현재 날씨의 데이터를 네트워크를 통하여 가져오는 중 데이터는 정상적으로 받아오나, Data를 Decoding 하는 과정에서 계속 실패함.
    - 파라미터중 `Snow`, `Rain` 이 있었는데 아마 해당 지역에 비와 눈이 내릴경우 값이 담기는 파라미터 였다.해당 파라미터 내부에는 1h, 3h의 key와 value가 있었고. 둘다 값이 있는 경우도 있었고, 1h or 3h만 값이 있는 경우가 있어 해당 프로퍼티들을 옵셔널 처리를 진행하여 Decoding을 성공하였다.

1. `func manager(_:didUpdatingLocation)` 메서드가 호출 된 뒤에 날씨데이터를 불러오는 네트워크 작업을 시작해야하나 현재 `CLLocationManager Delegate`가 `ViewController`에서 채택하고 호출하는게 아닌, `LocationManager`에서 채택하고 준수 하고 있어 해당 시점을 `ViewController`에게 어떻게 알려줄 것인가에 대한 문제가 있었다.
    - 먼저 Location update가 진행된 시점을  Notification 을 이용하여 처리해 보았다.
    <details>    
        <summary>코드</summary>
            
            ```swift
            extension Notification.Name {
            	static let didUpdateLocation = Notification.Name("didUpdateLocation")
            } 
            
            //Location Update 메서드 부분
            func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                    guard let location = locations.last else {
                        return
                    }
                  //위치 서비스가 업데이트가 되었을때 nofi로 알림을 보낸다  
            		NotificationCenter.default.post(name: .didUpdateLocation, object: nil)
                }
            
            //noti를 받는 부분
            class ViewController: UIViewController {
            	override viewDidLoad() {
            		NotificationCenter.default.addObserver(<#T##observer: self>, 
            																						selector: #selector(fetchingWeather)>, 
            																						name: .didUpdateLocation>,
            																						object: nil)
            	}
            
            	@objc func 
            }
            ```
            
            ```swift
            //Notification 이름 설정
            extension Notification.Name {
              static let didUpdateLocation = Notification.Name("didUpdateLocation")
            }
            
            //위치정보가 업데이트 된 경우 Notification을 Post해준다.
            class LocationManager: CLLocationManagerDelegate {
              func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                NotificationCenter.default.post(name: .didUpdateLocation, object: nil)
              }
            }
            
            //위치정보를 받았을때 메서드를 실행시킨다.
            class ViewController: UIViewController {
              override func viewDidLoad() {
                NotificationCenter.default.addObserver(self, selector: #selector(AnyFunc...), name: .didUpdateLocation, object: nil)
              }
            }
            ```
        </details>
        
        하지만 Notification은 1 : N 상황에서 많이 쓰이고, 메모리 해제도 관리해줘야 되기 때문에, Notification을 사용하지 않았다.
        

- Delegate 패턴을 사용하여 처리해보았다.
    <details>
        <summary>코드</summary>
        
        ```swift
        //델리게이트 패턴을 위한 프로토콜 선언
        protocol LocationManagerDelegate: AnyObject {
          func didUpdateLocation(_ location: CLLocation)
        }
        
        // 위임자를 프로퍼티로 지정하고 업데이트가 되었을때 대리자에게 행동을 위임한다.
        class LocationManager: NSObject, CLLocationManagerDelegate  {
          weak var delegate: LocationManagerDelegate?
          
          func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
            guard let location = locations.first else { return }
            delegate?.didUpdateLocation(location)
          }
        }
        
        //대리자를 설정하고, 해당 메서드를 구현한다.
        class ViewController: UIViewController, LocationManagerDelegate {
          var locationManager = LocationManager()
          
          override func viewDidLoad() {
            locationManager.delegate = self
          }
          
          func didUpdateLocation(_ location: CLLocation) {
            //메서드를 구현한다.
          }
        }
        ```
        
        ```swift
        //델리게이트 프로토콜 구현
        protocol LocationManagerDelegate {
        		func didUpdateLocation(_ location: CLLocation)
        }
        
        // 위임자 프로퍼티 생성 및 위임자에게 행동을 위임한다.
        class LocationManager {
        	weak var delegate: LocationManagerDelegate?
        
        	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
                guard let location = locations.last else {
                    return
                }
                currentLocation = location
        
        			// 위임자에게 행동을 위임한다
                **delegate?.didUpdateLocation(location)**
            }
        }
        
        // 위임해줄 인스턴스 구현
        class ViewController: LocationManagerDelegate {
        	private var locationManager: LocationManager?
        
        	viewDidLoad() {
        		locationManager.delegate = self
        	}
        	
        	func didUpdateLocation(_ location: CLLocation) {
        		//메서드를 구현함.
        	}
        
        }
        ```
        </details>
    
     Delegate 패턴을 사용하는 것이 Notification을 쓰는 것 보다 깔끔해보였고 이에따라 프로젝트에는   Delegate를 사용하여 문제를 해결하였다.
    

- 클로저의 사용
    - 리뷰어인 오늘날씨맑음이 클로저를 사용 할  수도 있을 것 같다고 말씀해주셨다.
    해당방법은 따로 구현을한번 해봐야겠다.

## IV. 해결하지 못한 문제

1. CLLocationManager의 `startUpdatingLocation()` 메서드를 호출하고 위치정보가 바뀌었을때 `func manager(_:didUpdatingLocation)` 메서드가 계속 호출되는 문제를 해결하지 못하였다. 
    1. 해결방법은 위치정보가 필요할때만 `requestLocation()` 을 통하여 사용 하는 방법이 있을 수 있을 것 같다.
2. `ViewController`에서 `fetchingWeather(api: type:)` 메서드가 구현되어있는데 해당 메서드의 역활이 `ViewController`의 역활이 맞을까? 또는 분리할 수 없을까라는 고민이 있었다. 
    1. `ViewController`의 역활이 Model에 있는 데이터를 가져와 가공한뒤 View에게 뿌려주는 역활을 하는 것이 맞다곤 생각하지만 이럴경우 요구사항이 많아 질 수록 `ViewController`가 점점 커지는 현상을 우려했기 때문이다. 
    2. 하지만 시간이 부족하여 처리하지 못한채 이번 프로젝트를 종료하게 되었다. 욕심상 `MVVM` 패턴을 이용하여 `ViewModel`을 구현하여 처리를 해보고 싶다.

1. 시간이 없어 `OpenWeatherAPI` 의 `APIKey`를 하드코딩을 했다. APIKey는 보안상 숨기거나 했어야 될 것 같았는데 알아볼 시간이 없어 따로 처리를 하지 못하였다. 

1. ForecastWeather 파싱이 실패하였다. 현재 어떤 지역에서는 파싱이 되고 어떤 지역에서는 파싱이 안되는 걸 보니 서버측에서 옵셔널인 파라미터가 있는듯 싶다. 하지만 시간이 부족해 어디가 옵셔널인지는 파악하지 못하였고, 다음 프로젝트때는 필요한 파라미터만 받아와서 처리를 하는게 어떨까하는 생각이 든다.
    
    
    ```swift
    if case .success(let data) = result {
         do {
                 try JSONDecoder().decode(type, from: data)
             } catch {
                 print(error)
             }
         }
    }
    /* 에러 내용
    keyNotFound(CodingKeys(stringValue: "partOfDay", intValue: nil), Swift.DecodingError.Context(codingPath: [CodingKeys(stringValue: "list", intValue: nil), _JSONKey(stringValue: "Index 0", intValue: 0), CodingKeys(stringValue: "sys", intValue: nil)], debugDescription: "No value associated with key CodingKeys(stringValue: \"partOfDay\", intValue: nil) (\"partOfDay\").", underlyingError: nil))
    */
    ```
    
    > Decoding시 throw를 캐치해서 에러 발생 시 어떤 내용의 에러인지를 확인하면 문제를 해결할 수 있다.
    `try?` 로 무조건 에러 발생시 nil을 할당하지 말고, `do - catch` 를 통해 에러에 대한 처리를 해주는 것이 행여나 발생할지 모르는 문제에 대한 적절한 조치가 가능할 것이다.
    > 
    

## V. 관련 학습 내용

<details>
    <summary>Core Location</summary>
    - 장치의 위치, 방향, iBeacon에 장치에 대한 상대적인 위치를 결정하는 서비스를 제공한다.
    - `CLLocationManager` 를 사용하여 `CoreLocation`을 구성 하고, 시작 및 중지를 할 수 있다.
    - 위치 서비스를 사용하기위해 사용자의 권한이 필요하다.
        - 사용자는 설정앱에서 언제든지 위치 서비스를 변경 할 수 있으며, 이는 개별앱이나, 기기전체에 영향을 미친다. 앱은 `CLLocationMangerDelegate` 프로토콜을 준수하는 대리자 인스턴스에서 권한 부여 변경을 포함한 이벤트를 수신한다.
        - 사용자의 권한을 얻기 위해 `CLLocation Manger`의 `requestWhenInUseAuthorization` 또는 `requestAlwaysAuthorization` 메서드를 호출해야 한다.
        - 그전에 앱의 `Info.plist` 파일에 **위치서비스를 사용하려는 이유(문자열)**과 **키**가 필요합니다.
            
            [info.plist ](https://www.notion.so/b6f6c5248d63401dbebdf4ae213279d9)
</details>

<details>
    <summary>URL Componets</summary>
    - URL을 구성하는 구조체
    - base URL(String)을 가지고 `URLComponents` 인스턴스를 생성하고, 프로퍼티인 queryItems에 URLQueryItem을 넣음으로써 URL 쿼리 문자열을 구성할 수 있다.
    - URLComponents 객체의 `url` 프로퍼티를 통해 구성된 url을 반환한다.
    
    [참고] [https://developer.apple.com/documentation/foundation/urlcomponents](https://developer.apple.com/documentation/foundation/urlcomponents) , [https://zeddios.tistory.com/1103?category=685736](https://zeddios.tistory.com/1103?category=685736)
</details>

<details>
    <summary>CLLocation Manager</summary>
    
    [CLLocation Manager](https://developer.apple.com/documentation/corelocation/cllocationmanager)
    
    - 앱에 대한 위치 관련 이벤트 전달을 시작 및 중지하는 데 사용하는 개체이다.
    - `requestWhenInUseAuthorization()` 또는 `requestAlwaysAuthorization()` 메서드의 사용으로 사용자에게 위치 권한을 요청 할 수 있다.
    - CLLocation Manager Delegate 를 이용하여 위치정보가 업데이트 되었을때나, 에러가 발생되었을때 델리게이트 메서드를 호출하게 된다. 대리자 인스턴스를 지정하여 메서드들을 구현해야 한다.
        - 위치 정보가 업데이트 되었을때는 `manager(_:didUpdateLocations:)` 메서드를 호출한다.
</details>

<details>
    <summary>GeoCoding</summary>
    - 위도, 경도 값으로 지역 이름을 얻는 것을 뜻한다. (vice versa)
    - `CLGeocoder` 타입으로 구현 가능하다. 결과는 `CLPlacemark` 타입의 객체로 반환한다.
    - geocoder를 사용하려면 객체를 생성하고, `forward-` 혹은 `reverse-` geocoding 메소드를 호출한다.
        - Reverse-geocoding은 위도와 경도 값을 받고 주소를 찾아준다.
        - Forward-geocoding은 주소를 받고 이에 해당하는 위도와 경도 값을 찾아준다.
            - 만약 복수의 유효한 위치 정보를 전달할 경우 복수의 placemark 객체를 반환한다.
    - `reverseGeocodeLocation(CLLocation, preferredLocale: Locale?, completionHandler: CLGeocodeCompletionHandler)` 로 지역 이름을 얻어올 수 있다.
    
    [참고] [https://developer.apple.com/documentation/corelocation/clgeocoder](https://developer.apple.com/documentation/corelocation/clgeocoder)
</details>

<details>
    <summary>Locale</summary>
    
    > data formatting시 사용하기 위한 언어적, 문화적, 기술적 컨벤션에 대한 정보를 나타내는 타입
    > 
    - Locale.current - 현재 기기에서 사용하고 있는 언어에 대한 Locale 타입
    - Locale.preferredLanguages - 선호하는 언어에 대한 String 타입의 배열
    - 직접 identifier를 주고 싶을때 → `Locale.init(identifier: "kr-KR")`
    
    [참고] [https://developer.apple.com/documentation/foundation/locale](https://developer.apple.com/documentation/foundation/locale)
</details>

<details>
    <summary>Placemark</summary>
    - 장소 이름, 주소 등등 관련 정보를 포함하는, 사용자 친화적으로 표현된 지리적 좌표
    - CLPlacemark 객체는 주어진 위도 경도에 대한 placemark 데이터를 가지며, 나라나 지역, 주, 도시, 도로명 등 특정 좌표값과 관련된 정보를 포함하고 있다.
    
    [참고] [https://developer.apple.com/documentation/corelocation/clplacemark](https://developer.apple.com/documentation/corelocation/clplacemark)
</details>
