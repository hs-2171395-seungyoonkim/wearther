import Foundation

struct WeatherResponse: Codable {
    let weather: [WeatherCondition]
    let main: MainWeather
    let wind: Wind
    let name: String
    let sys: Sys

    struct WeatherCondition: Codable {
        let main: String
        let description: String
    }

    struct MainWeather: Codable {
        let temp: Double
        let humidity: Int
    }

    struct Wind: Codable {
        let speed: Double
    }

    struct Sys: Codable {
        let country: String
    }
}

struct WeatherInfo {
    let temperature: Int
    let humidity: Int
    let windSpeed: Double
    let conditionKorean: String
    let emoji: String
    let cityName: String

    static func from(_ response: WeatherResponse) -> WeatherInfo {
        let condition = response.weather.first?.main ?? "Clear"
        return WeatherInfo(
            temperature: Int(response.main.temp.rounded()),
            humidity: response.main.humidity,
            windSpeed: response.wind.speed,
            conditionKorean: condition.toKorean(),
            emoji: condition.toEmoji(),
            cityName: response.name
        )
    }
}

struct GeocodingResult: Codable {
    let name: String
    let lat: Double
    let lon: Double
    let country: String
    let state: String?
    let localNames: [String: String]?

    enum CodingKeys: String, CodingKey {
        case name, lat, lon, country, state
        case localNames = "local_names"
    }

    var displayName: String {
        localNames?["ko"] ?? name
    }
}

private extension String {
    func toKorean() -> String {
        switch self {
        case "Clear": return "맑음"
        case "Clouds": return "흐림"
        case "Rain": return "비"
        case "Drizzle": return "이슬비"
        case "Thunderstorm": return "천둥번개"
        case "Snow": return "눈"
        case "Mist", "Fog", "Haze": return "안개"
        default: return "맑음"
        }
    }

    func toEmoji() -> String {
        switch self {
        case "Clear": return "☀️"
        case "Clouds": return "☁️"
        case "Rain": return "🌧️"
        case "Drizzle": return "🌦️"
        case "Thunderstorm": return "⛈️"
        case "Snow": return "❄️"
        case "Mist", "Fog", "Haze": return "🌫️"
        default: return "☀️"
        }
    }
}
