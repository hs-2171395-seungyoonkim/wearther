import Foundation

// MARK: - Response Wrapper

struct ApiResponse<T: Decodable>: Decodable {
    let success: Bool
    let data: T?
    let message: String?
}

struct EmptyData: Decodable {}

// MARK: - Auth Models

struct LoginRequest: Encodable {
    let email: String
    let password: String
}

struct LoginResponse: Decodable {
    let accessToken: String
    let tokenType: String
}

struct SignupRequest: Encodable {
    let email: String
    let password: String
    let name: String
}

// MARK: - User Models

struct UserStats: Decodable {
    let savedOutfits: Int
    let tripCount: Int
    let closetItemCount: Int
}

struct UserProfileResponse: Decodable {
    let id: Int
    let name: String
    let email: String
    let defaultLocation: String?
    let stylePreference: String?
    let notificationTime: String?
    let stats: UserStats
}

// MARK: - Closet Models

struct ClosetItem: Identifiable, Decodable {
    let id: Int
    let name: String
    let brand: String?
    let category: String
    let tags: [String]
    let imageUrl: String?
    let wearCount: Int
    let lastWorn: String?
    let favorite: Bool
    let suitableTempMin: Int?
    let suitableTempMax: Int?
    let aiNotes: String?
}

// MARK: - Trip Models

struct TripResponse: Identifiable, Decodable {
    let id: Int
    let destination: String
    let startDate: String
    let endDate: String
    let travelStyle: String?
    let activities: [String]?
    let packingList: String?

    var activityList: [String] { activities ?? [] }
}

struct TripRequest: Encodable {
    let destination: String
    let startDate: String
    let endDate: String
    let travelStyle: String?
    let activities: [String]
}

// MARK: - TripDay Models

struct TripDayResponse: Identifiable, Decodable {
    let id: Int
    let tripId: Int
    let dayNumber: Int
    let date: String
    let locationName: String?
    let temperature: Double?
    let weatherCondition: String?
    let feelsLike: Double?
    let rainChance: Int?
    let outfitRecommendation: String?
    let weatherNotes: String?

    var temperatureInt: Int { Int(temperature ?? 20) }

    var conditionEmoji: String {
        let c = weatherCondition ?? ""
        if c.contains("맑") { return "☀️" }
        if c.contains("비") || c.contains("소나기") { return "🌧️" }
        if c.contains("눈") { return "❄️" }
        if c.contains("안개") { return "🌫️" }
        return "☁️"
    }

    var formattedDate: String {
        let parts = date.split(separator: "-")
        guard parts.count >= 3,
              let month = Int(parts[1]),
              let day = Int(parts[2]) else { return date }
        return "\(month).\(day)"
    }
}

// MARK: - Outfit Models

struct OutfitItemInResponse: Identifiable, Decodable {
    let id: Int
    let name: String
    let brand: String?
    let category: String
    let imageUrl: String?
}

struct OutfitResponse: Identifiable, Decodable {
    let id: Int
    let description: String?
    let weatherCondition: String?
    let temperatureMin: Int?
    let temperatureMax: Int?
    let compatibilityScore: Int?
    let saved: Bool
    let bookmarked: Bool
    let items: [OutfitItemInResponse]
}

struct OutfitRequest: Encodable {
    let description: String
    let weatherCondition: String
    let tempMin: Int
    let tempMax: Int
    let closetItemIds: [Int]
}

// MARK: - Closet Update

struct UpdateClosetItemRequest: Encodable {
    let name: String?
    let brand: String?
    let category: String?
    let tags: String?
    let suitableTempMin: Int?
    let suitableTempMax: Int?
}

// MARK: - Profile Update

struct UpdateProfileRequest: Encodable {
    let name: String?
    let defaultLocation: String?
    let stylePreference: String?
    let notificationTime: String?
}

// MARK: - WornLog Models

struct WornLogItem: Decodable {
    let id: Int
    let name: String
    let imageUrl: String?
    let category: String
}

struct WornLog: Decodable, Identifiable {
    let date: String
    let items: [WornLogItem]
    var id: String { date }
}

struct WornLogRequest: Encodable {
    let date: String
    let closetItemIds: [Int]
}

// MARK: - Outfit Suggestion Models

struct OutfitSuggestionItem: Decodable {
    let id: Int
    let name: String
    let imageUrl: String?
    let category: String
}

struct OutfitSuggestion: Decodable, Identifiable {
    let description: String
    let items: [OutfitSuggestionItem]
    var id: String { description + items.map { String($0.id) }.joined() }
}

extension Notification.Name {
    static let didReceiveUnauthorized = Notification.Name("didReceiveUnauthorized")
}

// MARK: - APIClient

final class APIClient {
    static let shared = APIClient()
    private init() {}

    let baseURL = "http://localhost:8080"

    var token: String? {
        get { UserDefaults.standard.string(forKey: "accessToken") }
        set { UserDefaults.standard.set(newValue, forKey: "accessToken") }
    }

    // MARK: - Generic Request

    func request<T: Decodable>(
        _ path: String,
        method: String = "GET",
        body: (any Encodable)? = nil,
        requiresAuth: Bool = true
    ) async throws -> T {
        guard let url = URL(string: baseURL + path) else { throw URLError(.badURL) }

        var req = URLRequest(url: url)
        req.httpMethod = method
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        if requiresAuth, let token {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        if let body {
            req.httpBody = try JSONEncoder().encode(body)
        }

        let (data, response) = try await URLSession.shared.data(for: req)
        if let http = response as? HTTPURLResponse, http.statusCode == 401 {
            token = nil
            NotificationCenter.default.post(name: .didReceiveUnauthorized, object: nil)
            throw URLError(.userAuthenticationRequired)
        }
        return try JSONDecoder().decode(T.self, from: data)
    }

    // MARK: - Auth

    func login(email: String, password: String) async throws {
        let resp: ApiResponse<LoginResponse> = try await request(
            "/api/auth/login",
            method: "POST",
            body: LoginRequest(email: email, password: password),
            requiresAuth: false
        )
        if let data = resp.data {
            token = data.accessToken
        }
    }

    func signup(name: String, email: String, password: String) async throws {
        let _: ApiResponse<EmptyData> = try await request(
            "/api/auth/signup",
            method: "POST",
            body: SignupRequest(email: email, password: password, name: name),
            requiresAuth: false
        )
    }

    // MARK: - User

    func getProfile() async throws -> UserProfileResponse {
        let resp: ApiResponse<UserProfileResponse> = try await request("/api/user/profile")
        guard let data = resp.data else { throw URLError(.badServerResponse) }
        return data
    }

    // MARK: - Closet

    func getClosetItems(category: String? = nil) async throws -> [ClosetItem] {
        var path = "/api/closet/items"
        if let category { path += "?category=\(category)" }
        let resp: ApiResponse<[ClosetItem]> = try await request(path)
        return resp.data ?? []
    }

    func updateClosetItemImage(id: Int, imageData: Data) async throws -> ClosetItem {
        guard let url = URL(string: baseURL + "/api/closet/items/\(id)/image") else { throw URLError(.badURL) }
        let boundary = UUID().uuidString
        var req = URLRequest(url: url)
        req.httpMethod = "PATCH"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        var body = Data()
        body.append("--\(boundary)\r\n".data(using: .utf8)!)
        body.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
        body.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
        body.append(imageData)
        body.append("\r\n--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = body

        let (data, _) = try await URLSession.shared.data(for: req)
        let resp = try JSONDecoder().decode(ApiResponse<ClosetItem>.self, from: data)
        guard let item = resp.data else { throw URLError(.badServerResponse) }
        return item
    }

    func updateClosetItem(id: Int, name: String, brand: String, category: String, tags: String, tempMin: Int, tempMax: Int) async throws -> ClosetItem {
        let resp: ApiResponse<ClosetItem> = try await request(
            "/api/closet/items/\(id)",
            method: "PATCH",
            body: UpdateClosetItemRequest(name: name, brand: brand, category: category, tags: tags, suitableTempMin: tempMin, suitableTempMax: tempMax)
        )
        guard let data = resp.data else { throw URLError(.badServerResponse) }
        return data
    }

    func deleteClosetItem(id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await request("/api/closet/items/\(id)", method: "DELETE")
    }

    func wearItem(id: Int) async throws -> ClosetItem {
        let resp: ApiResponse<ClosetItem> = try await request("/api/closet/items/\(id)/wear", method: "POST")
        guard let data = resp.data else { throw URLError(.badServerResponse) }
        return data
    }

    func toggleFavorite(id: Int) async throws -> ClosetItem {
        let resp: ApiResponse<ClosetItem> = try await request("/api/closet/items/\(id)/favorite", method: "PATCH")
        guard let data = resp.data else { throw URLError(.badServerResponse) }
        return data
    }

    func createClosetItem(name: String, brand: String, category: String, tags: String, tempMin: Int? = nil, tempMax: Int? = nil, imageData: Data? = nil) async throws -> ClosetItem {
        guard let url = URL(string: baseURL + "/api/closet/items") else { throw URLError(.badURL) }

        let boundary = UUID().uuidString
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
        if let token { req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization") }

        var bodyData = Data()

        func appendField(_ fieldName: String, value: String) {
            bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
            bodyData.append("Content-Disposition: form-data; name=\"\(fieldName)\"\r\n\r\n".data(using: .utf8)!)
            bodyData.append("\(value)\r\n".data(using: .utf8)!)
        }

        appendField("name", value: name)
        appendField("brand", value: brand)
        appendField("category", value: category)
        appendField("tags", value: tags)
        if let tempMin { appendField("suitableTempMin", value: "\(tempMin)") }
        if let tempMax { appendField("suitableTempMax", value: "\(tempMax)") }

        if let imageData {
            bodyData.append("--\(boundary)\r\n".data(using: .utf8)!)
            bodyData.append("Content-Disposition: form-data; name=\"image\"; filename=\"photo.jpg\"\r\n".data(using: .utf8)!)
            bodyData.append("Content-Type: image/jpeg\r\n\r\n".data(using: .utf8)!)
            bodyData.append(imageData)
            bodyData.append("\r\n".data(using: .utf8)!)
        }

        bodyData.append("--\(boundary)--\r\n".data(using: .utf8)!)
        req.httpBody = bodyData

        let (data, _) = try await URLSession.shared.data(for: req)
        let resp = try JSONDecoder().decode(ApiResponse<ClosetItem>.self, from: data)
        guard let item = resp.data else { throw URLError(.badServerResponse) }
        return item
    }

    // MARK: - Trips

    func getTrips() async throws -> [TripResponse] {
        let resp: ApiResponse<[TripResponse]> = try await request("/api/trips")
        return resp.data ?? []
    }

    func createTrip(destination: String, startDate: String, endDate: String, travelStyle: String?, activities: [String]) async throws -> TripResponse {
        let resp: ApiResponse<TripResponse> = try await request(
            "/api/trips",
            method: "POST",
            body: TripRequest(destination: destination, startDate: startDate, endDate: endDate, travelStyle: travelStyle, activities: activities)
        )
        guard let data = resp.data else { throw URLError(.badServerResponse) }
        return data
    }

    func deleteTrip(id: Int) async throws {
        let _: ApiResponse<EmptyData> = try await request("/api/trips/\(id)", method: "DELETE")
    }

    // MARK: - Outfits

    func getOutfits() async throws -> [OutfitResponse] {
        let resp: ApiResponse<[OutfitResponse]> = try await request("/api/outfits")
        return resp.data ?? []
    }

    func toggleBookmark(outfitId: Int) async throws -> OutfitResponse {
        let resp: ApiResponse<OutfitResponse> = try await request("/api/outfits/\(outfitId)/bookmark", method: "PATCH")
        guard let data = resp.data else { throw URLError(.badServerResponse) }
        return data
    }

    // MARK: - Trip Days

    func getTripDays(tripId: Int) async throws -> [TripDayResponse] {
        let resp: ApiResponse<[TripDayResponse]> = try await request("/api/trips/\(tripId)/days")
        return resp.data ?? []
    }

    func getTripDay(tripId: Int, dayNumber: Int) async throws -> TripDayResponse {
        let resp: ApiResponse<TripDayResponse> = try await request("/api/trips/\(tripId)/days/\(dayNumber)")
        guard let data = resp.data else { throw URLError(.badServerResponse) }
        return data
    }

    // MARK: - AI

    func analyzeClosetItem(id: Int) async throws -> ClosetItem {
        let resp: ApiResponse<ClosetItem> = try await request("/api/ai/closet/items/\(id)/analyze", method: "POST")
        guard let data = resp.data else { throw URLError(.badServerResponse) }
        return data
    }

    func recommendOutfits(tripId: Int) async throws -> [TripDayResponse] {
        let resp: ApiResponse<[TripDayResponse]> = try await request("/api/ai/trips/\(tripId)/recommend", method: "POST")
        return resp.data ?? []
    }

    func recommendToday(temperature: Int, condition: String) async throws -> String {
        let encoded = condition.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? condition
        let resp: ApiResponse<String> = try await request(
            "/api/ai/recommend-today?temperature=\(temperature)&condition=\(encoded)",
            method: "POST"
        )
        guard let data = resp.data else { throw URLError(.badServerResponse) }
        return data
    }

    // MARK: - Profile Update

    func updateProfile(name: String? = nil, defaultLocation: String? = nil, stylePreference: String? = nil, notificationTime: String? = nil) async throws -> UserProfileResponse {
        let resp: ApiResponse<UserProfileResponse> = try await request(
            "/api/user/profile",
            method: "PATCH",
            body: UpdateProfileRequest(name: name, defaultLocation: defaultLocation, stylePreference: stylePreference, notificationTime: notificationTime)
        )
        guard let data = resp.data else { throw URLError(.badServerResponse) }
        return data
    }

    // MARK: - WornLog

    func logWorn(date: String, closetItemIds: [Int]) async throws -> WornLog {
        let resp: ApiResponse<WornLog> = try await request(
            "/api/worn-logs",
            method: "POST",
            body: WornLogRequest(date: date, closetItemIds: closetItemIds)
        )
        guard let data = resp.data else { throw URLError(.badServerResponse) }
        return data
    }

    func getWornLogs(year: Int, month: Int) async throws -> [WornLog] {
        let resp: ApiResponse<[WornLog]> = try await request("/api/worn-logs?year=\(year)&month=\(month)")
        return resp.data ?? []
    }

    func getWornLogByDate(date: String) async throws -> WornLog {
        let resp: ApiResponse<WornLog> = try await request("/api/worn-logs/\(date)")
        guard let data = resp.data else { throw URLError(.badServerResponse) }
        return data
    }

    func getOutfitSuggestionsForCity(temperature: Int, condition: String) async throws -> [OutfitSuggestion] {
        let encoded = condition.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? condition
        let resp: ApiResponse<[OutfitSuggestion]> = try await request(
            "/api/ai/outfit-suggestions?temperature=\(temperature)&condition=\(encoded)",
            method: "POST"
        )
        return resp.data ?? []
    }

    func getOutfitSuggestions(itemId: Int, temperature: Int, condition: String) async throws -> [OutfitSuggestion] {
        let encoded = condition.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed) ?? condition
        let resp: ApiResponse<[OutfitSuggestion]> = try await request(
            "/api/ai/closet/items/\(itemId)/outfit-suggestions?temperature=\(temperature)&condition=\(encoded)",
            method: "POST"
        )
        return resp.data ?? []
    }

    func createOutfit(description: String, weatherCondition: String, tempMin: Int, tempMax: Int, closetItemIds: [Int]) async throws -> OutfitResponse {
        let resp: ApiResponse<OutfitResponse> = try await request(
            "/api/outfits",
            method: "POST",
            body: OutfitRequest(description: description, weatherCondition: weatherCondition, tempMin: tempMin, tempMax: tempMax, closetItemIds: closetItemIds)
        )
        guard let data = resp.data else { throw URLError(.badServerResponse) }
        return data
    }
}
