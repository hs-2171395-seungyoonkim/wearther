import SwiftUI
import MapKit

struct TravelView: View {
    @State private var searchText = ""
    @State private var searchResults: [GeocodingResult] = []
    @State private var searchTask: Task<Void, Never>?
    @State private var selectedCityName = "서울"
    @State private var travelWeather: WeatherInfo?
    @State private var isLoading = false
    @State private var tappedCoordinate: CLLocationCoordinate2D?
    @State private var showAddTrip = false
    @State private var trips: [TripResponse] = []
    @State private var currentTripDays: [TripDayResponse] = []
    @State private var travelSuggestions: [OutfitSuggestion] = []
    @State private var dayOutfitCache: [Int: [OutfitSuggestion]] = [:]
    @State private var isGettingRecommendation = false
    @State private var showRecommendationSheet = false
    @State private var savingOutfitIndex: Int? = nil
    @State private var savedOutfitIndices: Set<Int> = []
    @State private var mapPosition: MapCameraPosition = .region(
        MKCoordinateRegion(
            center: CLLocationCoordinate2D(latitude: 37.5665, longitude: 126.9780),
            span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
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
        CityItem(flag: "🇰🇷", name: "서울", lat: 37.5665, lon: 126.9780),
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
        ZStack(alignment: .bottomTrailing) {
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
                        .padding(.bottom, 20)

                    tripItinerarySection
                        .padding(.horizontal, 24)
                        .padding(.bottom, 100)
                }
                .padding(.top, 16)
            }
            .background(AppColor.background.ignoresSafeArea())

            Button {
                showAddTrip = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(width: 56, height: 56)
                    .background(AppColor.primary)
                    .clipShape(Circle())
                    .shadow(color: AppColor.primary.opacity(0.4), radius: 8, x: 0, y: 4)
            }
            .padding(.trailing, 24)
            .padding(.bottom, 24)
        }
        .sheet(isPresented: $showAddTrip, onDismiss: {
            Task { await loadTrips() }
        }) {
            AddTripView()
        }
        .sheet(isPresented: $showRecommendationSheet) {
            if let weather = travelWeather {
                TravelOutfitSheet(
                    cityName: weather.cityName.isEmpty ? selectedCityName : weather.cityName,
                    flag: selectedFlag,
                    weather: weather,
                    suggestions: travelSuggestions,
                    savingIndex: $savingOutfitIndex,
                    savedIndices: $savedOutfitIndices
                )
            }
        }
        .task {
            await fetchWeather(lat: cities[0].lat, lon: cities[0].lon)
            await loadTrips()
        }
    }

    private var tripItinerarySection: some View {
        VStack(alignment: .leading, spacing: 12) {
            if trips.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "suitcase")
                        .font(.system(size: 32))
                        .foregroundColor(AppColor.primary.opacity(0.4))
                    Text("아직 여행 일정이 없어요")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.gray)
                    Text("+ 버튼을 눌러 여행을 추가해보세요")
                        .font(.system(size: 13))
                        .foregroundColor(.gray.opacity(0.8))
                }
                .frame(maxWidth: .infinity)
                .padding(32)
                .background(.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
            } else {
                ForEach(trips) { trip in
                    tripSection(trip: trip)
                }
            }
        }
    }

    private func tripSection(trip: TripResponse) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(trip.destination)
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColor.darkText)
                    Text("\(trip.startDate) – \(trip.endDate)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
                Spacer()
                Button {
                    Task { await deleteTrip(trip) }
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.gray.opacity(0.5))
                }
            }

            let days = currentTripDays.filter { $0.tripId == trip.id }
            if days.isEmpty {
                Text("날씨 데이터를 불러오는 중...")
                    .font(.system(size: 13))
                    .foregroundColor(.gray)
                    .padding(12)
            } else {
                VStack(spacing: 8) {
                    ForEach(days) { day in
                        NavigationLink(destination: TripDayDetailView(
                            day: day,
                            destination: trip.destination,
                            suggestions: Binding(
                                get: { dayOutfitCache[day.id] ?? [] },
                                set: { dayOutfitCache[day.id] = $0 }
                            )
                        )) {
                            tripDayRow(day: day, cachedSuggestions: dayOutfitCache[day.id] ?? [])
                        }
                        .buttonStyle(.plain)
                    }
                }
            }

            if let packing = trip.packingList, !packing.isEmpty {
                packingCard(text: packing)
            }
        }
    }

    private func tripDayRow(day: TripDayResponse, cachedSuggestions: [OutfitSuggestion]) -> some View {
        HStack(spacing: 14) {
            VStack(spacing: 2) {
                Text("\(day.dayNumber)일차")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(AppColor.primary)
                Text(day.conditionEmoji)
                    .font(.system(size: 22))
            }
            .frame(width: 48)

            VStack(alignment: .leading, spacing: 6) {
                HStack(spacing: 4) {
                    Text(day.formattedDate)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                }
                Text("\(day.temperatureInt)° \(day.weatherCondition ?? "–")")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColor.darkText)

                if !cachedSuggestions.isEmpty {
                    let firstOutfit = cachedSuggestions[0]
                    let catOrder = ["TOP": 0, "BOTTOM": 1, "OUTERWEAR": 2, "SHOES": 3]
                    let sorted = firstOutfit.items.sorted { (catOrder[$0.category] ?? 4) < (catOrder[$1.category] ?? 4) }
                    HStack(spacing: 4) {
                        ForEach(sorted, id: \.id) { item in
                            outfitPreviewThumb(item)
                        }
                        Text("코디 추천 완료")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(AppColor.primary)
                            .padding(.leading, 2)
                    }
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(Color.gray.opacity(0.4))
        }
        .padding(16)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func packingCard(text: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            Text("🧳")
                .font(.system(size: 28))

            VStack(alignment: .leading, spacing: 4) {
                Text("패킹 추천")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(.white)
                Text(text)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(3)
            }
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [AppColor.darkText, AppColor.darkBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: AppColor.darkBlue.opacity(0.2), radius: 8, x: 0, y: 4)
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
                        travelSuggestions = []
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
                travelSuggestions = []
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

            if isGettingRecommendation {
                HStack(spacing: 8) {
                    ProgressView().tint(AppColor.primary)
                    Text("AI가 코디를 분석 중...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(AppColor.background)
                .cornerRadius(12)
            } else if !travelSuggestions.isEmpty {
                // Preview: show first outfit's items as thumbnails
                VStack(alignment: .leading, spacing: 8) {
                    Text("코디 \(travelSuggestions.count)가지 추천 완료")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(AppColor.primary)
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 6) {
                            ForEach(travelSuggestions[0].items, id: \.id) { item in
                                outfitPreviewThumb(item)
                            }
                            if travelSuggestions.count > 1 {
                                Text("+\(travelSuggestions.count - 1)가지 더")
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.white)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(AppColor.darkBlue)
                                    .cornerRadius(10)
                            }
                        }
                    }
                }
                .padding(14)
                .background(AppColor.background)
                .cornerRadius(12)
            } else {
                Text("버튼을 눌러 내 옷장 기반 코디를 추천받아보세요")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.gray)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(16)
                    .background(AppColor.background)
                    .cornerRadius(12)
            }

            Button {
                if !travelSuggestions.isEmpty {
                    savedOutfitIndices = []
                    showRecommendationSheet = true
                } else {
                    Task { await getTravelRecommendation() }
                }
            } label: {
                ZStack {
                    Text(travelSuggestions.isEmpty ? "내 옷장에서 코디 받기" : "추천 코디 보기")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.white)
                        .opacity(isGettingRecommendation ? 0 : 1)
                    if isGettingRecommendation { ProgressView().tint(.white) }
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 16)
                .background(isGettingRecommendation ? AppColor.primary.opacity(0.5) : AppColor.primary)
                .cornerRadius(12)
            }
            .disabled(isGettingRecommendation || travelWeather == nil)
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
        travelSuggestions = []
        withAnimation(.easeInOut(duration: 0.5)) {
            mapPosition = .region(MKCoordinateRegion(
                center: CLLocationCoordinate2D(latitude: result.lat, longitude: result.lon),
                span: MKCoordinateSpan(latitudeDelta: 5, longitudeDelta: 5)
            ))
        }
        Task { await fetchWeather(lat: result.lat, lon: result.lon) }
    }

    private func outfitPreviewThumb(_ item: OutfitSuggestionItem) -> some View {
        Group {
            if let path = item.imageUrl, !path.isEmpty,
               let url = URL(string: APIClient.shared.baseURL + path) {
                CachedAsyncImage(url: url) {
                    placeholderThumb
                }
            } else { placeholderThumb }
        }
        .frame(width: 44, height: 50)
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }

    private var placeholderThumb: some View {
        ZStack {
            LinearGradient(colors: [AppColor.primary.opacity(0.4), AppColor.lightBlue.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing)
            Image(systemName: "tshirt.fill").font(.system(size: 14)).foregroundColor(.white.opacity(0.7))
        }
    }

    private func getTravelRecommendation() async {
        guard let weather = travelWeather else { return }
        isGettingRecommendation = true
        do {
            travelSuggestions = try await APIClient.shared.getOutfitSuggestionsForCity(
                temperature: weather.temperature,
                condition: weather.conditionKorean
            )
            showRecommendationSheet = true
        } catch {
            print("코디 추천 오류: \(error)")
        }
        isGettingRecommendation = false
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

    private func deleteTrip(_ trip: TripResponse) async {
        do {
            try await APIClient.shared.deleteTrip(id: trip.id)
            await loadTrips()
        } catch {
            print("여행 삭제 오류: \(error)")
        }
    }

    private func loadTrips() async {
        do {
            trips = try await APIClient.shared.getTrips()
            var allDays: [TripDayResponse] = []
            for trip in trips {
                let days = try await APIClient.shared.getTripDays(tripId: trip.id)
                allDays.append(contentsOf: days)
            }
            currentTripDays = allDays
        } catch {
            print("여행 로드 오류: \(error)")
        }
    }
}

private struct TravelOutfitSheet: View {
    @Environment(\.dismiss) private var dismiss
    let cityName: String
    let flag: String
    let weather: WeatherInfo
    let suggestions: [OutfitSuggestion]
    @Binding var savingIndex: Int?
    @Binding var savedIndices: Set<Int>

    private let catOrder = ["TOP": 0, "BOTTOM": 1, "OUTERWEAR": 2, "SHOES": 3]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                VStack(alignment: .leading, spacing: 16) {
                    HStack {
                        HStack(spacing: 6) {
                            Image(systemName: "wand.and.sparkles")
                                .font(.system(size: 12))
                                .foregroundColor(.white)
                            Text("AI 코디 추천")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(.white.opacity(0.25))
                        .cornerRadius(8)
                        Spacer()
                        Button { dismiss() } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 15, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 32, height: 32)
                                .background(.white.opacity(0.2))
                                .clipShape(Circle())
                        }
                    }
                    HStack(spacing: 12) {
                        Text(flag).font(.system(size: 36))
                        VStack(alignment: .leading, spacing: 4) {
                            Text(cityName)
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(.white)
                            HStack(spacing: 6) {
                                Text(weather.emoji).font(.system(size: 16))
                                Text("\(weather.temperature)° · \(weather.conditionKorean)")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.white.opacity(0.85))
                            }
                        }
                    }
                }
                .padding(24)
                .background(LinearGradient(
                    colors: [AppColor.primary, AppColor.darkBlue],
                    startPoint: .topLeading, endPoint: .bottomTrailing
                ))

                // Outfit Cards
                VStack(spacing: 16) {
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                        outfitCard(index: index, suggestion: suggestion)
                    }
                }
                .padding(20)
            }
        }
        .background(AppColor.background.ignoresSafeArea())
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    private func outfitCard(index: Int, suggestion: OutfitSuggestion) -> some View {
        let sortedItems = suggestion.items.sorted {
            (catOrder[$0.category] ?? 4) < (catOrder[$1.category] ?? 4)
        }
        return VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("코디 \(index + 1)")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(AppColor.primary)
                    Text(suggestion.description)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColor.darkText)
                        .lineLimit(2)
                }
                Spacer()
                Button {
                    Task { await saveOutfit(index: index, suggestion: suggestion) }
                } label: {
                    if savingIndex == index {
                        ProgressView().tint(AppColor.primary).frame(width: 60, height: 30)
                    } else if savedIndices.contains(index) {
                        Label("저장됨", systemImage: "checkmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(Color.gray)
                            .cornerRadius(10)
                    } else {
                        Label("저장", systemImage: "bookmark")
                            .font(.system(size: 12, weight: .bold))
                            .foregroundColor(AppColor.primary)
                            .padding(.horizontal, 12).padding(.vertical, 6)
                            .background(AppColor.primary.opacity(0.1))
                            .cornerRadius(10)
                    }
                }
                .disabled(savingIndex != nil || savedIndices.contains(index))
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(sortedItems, id: \.id) { item in
                        itemCell(item)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
        .padding(16)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func itemCell(_ item: OutfitSuggestionItem) -> some View {
        let label = item.category == "TOP" ? "상의"
            : item.category == "BOTTOM" ? "하의"
            : item.category == "OUTERWEAR" ? "아우터" : "신발"

        return VStack(spacing: 4) {
            Group {
                if let path = item.imageUrl, !path.isEmpty,
                   let url = URL(string: APIClient.shared.baseURL + path) {
                    CachedAsyncImage(url: url) {
                        gradientPlaceholder(item)
                    }
                } else {
                    gradientPlaceholder(item)
                }
            }
            .frame(width: 90, height: 104)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text(label)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColor.primary)
            Text(item.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColor.darkText)
                .lineLimit(1)
                .frame(width: 90)
        }
    }

    private func gradientPlaceholder(_ item: OutfitSuggestionItem) -> some View {
        let colors: [Color] = item.category == "TOP"
            ? [AppColor.primary.opacity(0.5), AppColor.lightBlue.opacity(0.7)]
            : item.category == "BOTTOM"
            ? [AppColor.darkBlue.opacity(0.4), AppColor.primary.opacity(0.35)]
            : item.category == "OUTERWEAR"
            ? [Color(red: 80/255, green: 60/255, blue: 120/255).opacity(0.5), AppColor.darkBlue.opacity(0.4)]
            : [Color.gray.opacity(0.35), Color.gray.opacity(0.5)]

        return ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 4) {
                Image(systemName: "tshirt.fill").font(.system(size: 20)).foregroundColor(.white.opacity(0.7))
                Text(item.name).font(.system(size: 9, weight: .semibold)).foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center).lineLimit(2).padding(.horizontal, 6)
            }
        }
    }

    private func saveOutfit(index: Int, suggestion: OutfitSuggestion) async {
        savingIndex = index
        do {
            _ = try await APIClient.shared.createOutfit(
                description: suggestion.description,
                weatherCondition: weather.conditionKorean,
                tempMin: weather.temperature - 2,
                tempMax: weather.temperature + 2,
                closetItemIds: suggestion.items.map { $0.id }
            )
            savedIndices.insert(index)
        } catch {
            print("코디 저장 오류: \(error)")
        }
        savingIndex = nil
    }
}
