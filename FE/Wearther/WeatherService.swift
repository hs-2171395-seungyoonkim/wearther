import Foundation

struct WeatherService {
    static let shared = WeatherService()
    private let apiKey = Config.weatherAPIKey
    private let baseURL = "https://api.openweathermap.org/data/2.5/weather"

    func fetch(lat: Double, lon: Double) async throws -> WeatherInfo {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "lat", value: "\(lat)"),
            URLQueryItem(name: "lon", value: "\(lon)"),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return WeatherInfo.from(try JSONDecoder().decode(WeatherResponse.self, from: data))
    }

    func fetch(city: String) async throws -> WeatherInfo {
        var components = URLComponents(string: baseURL)!
        components.queryItems = [
            URLQueryItem(name: "q", value: city),
            URLQueryItem(name: "appid", value: apiKey),
            URLQueryItem(name: "units", value: "metric")
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return WeatherInfo.from(try JSONDecoder().decode(WeatherResponse.self, from: data))
    }

    func search(query: String) async throws -> [GeocodingResult] {
        var components = URLComponents(string: "https://api.openweathermap.org/geo/1.0/direct")!
        components.queryItems = [
            URLQueryItem(name: "q", value: query),
            URLQueryItem(name: "limit", value: "5"),
            URLQueryItem(name: "appid", value: apiKey)
        ]
        let (data, _) = try await URLSession.shared.data(from: components.url!)
        return try JSONDecoder().decode([GeocodingResult].self, from: data)
    }
}
