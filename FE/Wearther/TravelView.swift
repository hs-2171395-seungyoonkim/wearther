import SwiftUI
import MapKit

struct TravelView: View {
    @State private var searchText = ""
    @State private var searchResults: [GeocodingResult] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedCityName = "도쿄"
    @State private var travelWeather: WeatherInfo?
    @State private var isLoading = false
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 35.6762, longitude: 139.6503),
            span: MKCoordinateSpan(latitudeDelta: 10, longitudeDelta: 10)
        )
    )

    private struct CityItem {
        let flag: String
        let name: String
        let lat: Double
        let lon: Double
        var coordinate: CLLocationCoordinate2D {
            CLLocationCoordinate2D(latitude: lat, longitude: lon)
        }
    }

    private let cities: [CityItem] = [
        CityItem(flag: "🇯🇵", name: "도쿄", lat: 35.6762, lon: 139.6503),
        CityItem(flag: "🇹🇭", name: "방콕", lat: 13.7563, lon: 100.5018),
        CityItem(flag: "🇫🇷", name: "파리", lat: 48.8566, lon: 2.3522),
        CityItem(flag: "🇮🇹", name: "로마", lat: 41.9028, lon: 12.4964),
        CityItem(flag: "🇻🇳", name: "다낭", lat: 16.0544, lon: 108.2022)
    ]

    private var selectedFlag: String {
        cities.first { $0.name == selectedCityName }?.flag ?? "📍"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                searchSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                cityChips
                    .padding(.bottom, 20)

                realMap
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                cityWeatherCard
                    .padding(.horizontal, 24)
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(AppColor.background.ignoresSafeArea())
        .task {
            await fetchWeather(lat: cities[0].lat, lon: cities[0].lon)
        }
    }

    private var searchSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack {
                Image(systemName: "magnifyingglass")
                    .foregroundColor(.gray)
                TextField("여행지를 검색하세요 🔍", text: $searchText)
                    .font(.system(size: 15))
                    .onChange(of: searchText) { _, text in
                        handleSearchChange(text)
                    }
                if !searchText.isEmpty {
                    Button {
                        searchText = ""
                        searchResults = []
                        searchTask?.cancel()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(.white)
            .cornerRadius(searchResults.isEmpty ? 12 : 0)
            .clipShape(
                UnevenRoundedRectangle(
                    topLeadingRadius: 12,
                    bottomLeadingRadius: searchResults.isEmpty ? 12 : 0,
                    bottomTrailingRadius: searchResults.isEmpty ? 12 : 0,
                    topTrailingRadius: 12
                )
            )

            if !searchResults.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(searchResults.enumerated()), id: \.element.name) { index, result in
                        Button {
                            selectSearchResult(result)
                        } label: {
                            HStack(spacing: 12) {
                                Image(systemName: "mappin.circle.fill")
                                    .font(.system(size: 18))
                                    .foregroundColor(AppColor.primary)

                                VStack(alignment: .leading, spacing: 2) {
                                    Text(result.displayName)
                                        .font(.system(size: 15, weight: .semibold))
                                        .foregroundColor(AppColor.darkText)
                                    Text("\(result.name), \(result.country)\(result.state.map { ", \($0)" } ?? "")")
                                        .font(.system(size: 12))
                                        .foregroundColor(.gray)
                                }
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .padding(.vertical, 12)
                            .background(.white)
                            .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)

                        if index < searchResults.count - 1 {
                            Divider().padding(.leading, 46)
                        }
                    }
                }
                .clipShape(
                    UnevenRoundedRectangle(
                        topLeadingRadius: 0,
                        bottomLeadingRadius: 12,
                        bottomTrailingRadius: 12,
                        topTrailingRadius: 0
                    )
                )
            }
        }
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.gray.opacity(0.2))
        )
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var cityChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(cities, id: \.name) { city in
                    Button {
                        selectedCityName = city.name
                        tappedCoordinate = nil
                        searchText = ""
                        searchResults = []
                        withAnimation(.easeInOut(duration: 0.5)) {
                            mapPosition = .region(MKCoordinateRegion(
                                center: city.coordinate,
                                span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
                            ))
                        }
                        Task { await fetchWeather(lat: city.lat, lon: city.lon) }
                    } label: {
                        HStack(spacing: 8) {
                            Text(city.flag).font(.system(size: 18))
                            Text(city.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColor.darkText)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.white)
                        .cornerRadius(12)
                        .overlay(
                            RoundedRectangle(cornerRadius: 12).stroke(
                                selectedCityName == city.name && tappedCoordinate == nil
                                    ? AppColor.primary : Color.gray.opacity(0.2),
                                lineWidth: selectedCityName == city.name && tappedCoordinate == nil ? 1.5 : 1
                            )
                        )
                        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.vertical, 4)
        }
    }

    private var realMap: some View {
        MapReader { proxy in
            Map(position: $mapPosition) {
                ForEach(cities, id: \.name) { city in
                    Marker(city.flag + " " + city.name, coordinate: city.coordinate)
                        .tint(
                            selectedCityName == city.name && tappedCoordinate == nil
                                ? AppColor.primary : .gray
                        )
                }

                if let coord = tappedCoordinate {
                    Marker(travelWeather?.cityName ?? "선택한 위치", coordinate: coord)
                        .tint(AppColor.primary)
                }
            }
            .frame(height: 360)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .onTapGesture { screenPosition in
                guard let coordinate = proxy.convert(screenPosition, from: .local) else { return }
                tappedCoordinate = coordinate
                selectedCityName = ""
                searchText = ""
                searchResults = []
                Task { await fetchWeather(lat: coordinate.latitude, lon: coordinate.longitude) }
            }
        }
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }

    private var cityWeatherCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                HStack(spacing: 6) {
                    Text(selectedFlag).font(.system(size: 20))
                    Text(travelWeather?.cityName ?? (selectedCityName.isEmpty ? "선택된 위치" : selectedCityName))
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColor.darkText)
                }

                if isLoading {
                    ProgressView().tint(AppColor.primary)
                } else {
                    HStack(alignment: .center, spacing: 8) {
                        Text("\(travelWeather?.temperature ?? 18)°")
                            .font(.system(size: 36, weight: .bold))
                            .foregroundColor(AppColor.darkBlue)

                        HStack(spacing: 4) {
                            Text(travelWeather?.emoji ?? "☁️").font(.system(size: 22))
                            Text(travelWeather?.conditionKorean ?? "흐림")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }
            }

            Text("트렌치코트 + 두꺼운 니트 + 슬랙스")
                .font(.system(size: 15, weight: .medium))
                .foregroundColor(AppColor.darkText)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppColor.background)
                .cornerRadius(12)

            Button {
            } label: {
                Text("내 옷장에서 코디 받기")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColor.primary)
                    .cornerRadius(12)
            }
        }
        .padding(24)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func handleSearchChange(_ text: String) {
        searchTask?.cancel()
        guard !text.trimmingCharacters(in: .whitespaces).isEmpty else {
            searchResults = []
            return
        }
        searchTask = Task {
            try? await Task.sleep(for: .milliseconds(500))
            guard !Task.isCancelled else { return }
            do {
                searchResults = try await WeatherService.shared.search(query: text)
            } catch {
                searchResults = []
            }
        }
    }

    private func selectSearchResult(_ result: GeocodingResult) {
        searchText = result.displayName
        searchResults = []
        searchTask?.cancel()
        selectedCityName = result.displayName
        tappedCoordinate = CLLocationCoordinate2D(latitude: result.lat, longitude: result.lon)
        withAnimation(.easeInOut(duration: 0.5)) {
            mapPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: result.lat, longitude: result.lon),
                span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
            ))
        }
        Task { await fetchWeather(lat: result.lat, lon: result.lon) }
    }

    private func fetchWeather(lat: Double, lon: Double) async {
        isLoading = true
        do {
            travelWeather = try await WeatherService.shared.fetch(lat: lat, lon: lon)
        } catch {
            print("여행지 날씨 오류: \(error)")
        }
        isLoading = false
    }
}
