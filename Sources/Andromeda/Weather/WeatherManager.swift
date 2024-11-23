import Foundation

class WeatherManager: ObservableObject {
    @Published var temperature: String = "--"
    @Published var city: String = "Loading..."
    @Published var condition: String = "..."
    
    private let weatherApiKey = "3eaadf396e865907a967dd4b18e5ff8e"
    private let units = "imperial"
    
    func fetchWeather() {
        guard let url = URL(string: "https://ipinfo.io/json") else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("IP Info error:", error?.localizedDescription ?? "Unknown error")
                return
            }
            
            do {
                let locationInfo = try JSONDecoder().decode(LocationInfo.self, from: data)
                
                // Update city
                DispatchQueue.main.async {
                    self?.city = locationInfo.city
                }
                
                // Get coordinates
                let coordinates = locationInfo.loc.split(separator: ",")
                guard coordinates.count == 2,
                      let lat = Double(coordinates[0]),
                      let lon = Double(coordinates[1]) else {
                    print("Invalid coordinates format")
                    return
                }
                
                // Fetch weather with coordinates
                self?.fetchWeatherData(lat: lat, lon: lon)
            } catch {
                print("Location decode error:", error)
                DispatchQueue.main.async {
                    self?.city = "Location Unavailable"
                }
            }
        }
        task.resume()
    }
    
    private func fetchWeatherData(lat: Double, lon: Double) {
        let urlString = "https://api.openweathermap.org/data/2.5/weather?lat=\(lat)&lon=\(lon)&appid=\(weatherApiKey)&units=\(units)"
        guard let url = URL(string: urlString) else { return }
        
        let task = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            guard let data = data, error == nil else {
                print("Weather API error:", error?.localizedDescription ?? "Unknown error")
                return
            }
            
            do {
                let result = try JSONDecoder().decode(WeatherResponse.self, from: data)
                DispatchQueue.main.async {
                    self?.temperature = "\(Int(round(result.main.temp)))"
                    self?.condition = result.weather.first?.main ?? "Clear"
                }
            } catch {
                print("Weather decode error:", error)
                DispatchQueue.main.async {
                    self?.temperature = "--"
                    self?.condition = "Unavailable"
                }
            }
        }
        task.resume()
    }
}

struct LocationInfo: Codable {
    let city: String
    let loc: String
}

struct WeatherResponse: Codable {
    let main: MainWeather
    let weather: [Weather]
}

struct MainWeather: Codable {
    let temp: Double
}

struct Weather: Codable {
    let main: String
} 