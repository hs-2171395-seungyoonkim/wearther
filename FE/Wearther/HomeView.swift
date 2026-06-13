import SwiftUI

struct HomeView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var weather: WeatherInfo?
    @State private var isLoading = true
    @State private var todayRecommendation: String?
    @State private var isLoadingRecommendation = false
    @State private var todayWornLog: WornLog?
    @State private var showWornLogSheet = false
    @State private var showCalendar = false

    private let defaultLat = 37.5665
    private let defaultLon = 126.9780

    private let lookbookTempOffsets: [Int] = [-2, 0, 3, -1, 2, -3, 1, 4, -1]
    private let lookbookConditions: [String] = ["맑음", "구름 조금", "흐림", "맑음", "구름 많음", "맑음", "흐림", "맑음", "구름 조금"]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Image("WeartherLogo")
                    .resizable()
                    .scaledToFit()
                    .frame(height: 52)
                    .padding(.bottom, 12)

                HStack(spacing: 6) {
                    Image(systemName: "mappin")
                        .font(.system(size: 12))
                        .foregroundColor(AppColor.darkBlue)
                    Text(locationManager.displayName)
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(AppColor.darkBlue)
                }
                .padding(.bottom, 24)

                weatherCard
                    .padding(.bottom, 24)

                aiOutfitCard
                    .padding(.bottom, 24)

                wornLogSection
                    .padding(.bottom, 24)

                Text("이 날씨 룩북")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColor.darkText)
                    .padding(.bottom, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(0..<9, id: \.self) { i in
                            LookbookCard(
                                imageName: "lookbook\(i + 1)",
                                temperature: (weather?.temperature ?? 23) + lookbookTempOffsets[i],
                                condition: lookbookConditions[i]
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 4)
                }
                .padding(.horizontal, -24)
            }
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(AppColor.background.ignoresSafeArea())
        .sheet(isPresented: $showWornLogSheet, onDismiss: { Task { await loadTodayLog() } }) {
            WornLogSheet(onSave: { await loadTodayLog() })
        }
        .navigationDestination(isPresented: $showCalendar) {
            WornLogCalendarView()
        }
        .task {
            locationManager.request()
            await fetchWeather(lat: defaultLat, lon: defaultLon)
            await loadTodayLog()
        }
        .onChange(of: locationManager.latitude) { _, lat in
            guard let lat, let lon = locationManager.longitude else { return }
            Task { await fetchWeather(lat: lat, lon: lon) }
        }
    }

    private func loadTodayLog() async {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        todayWornLog = try? await APIClient.shared.getWornLogByDate(date: f.string(from: Date()))
    }

    private var wornLogSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("오늘 착용 기록")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColor.darkText)
                Spacer()
                Button {
                    showCalendar = true
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                            .font(.system(size: 13))
                        Text("캘린더")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundColor(AppColor.primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColor.primary.opacity(0.1))
                    .cornerRadius(10)
                }
            }

            VStack(alignment: .leading, spacing: 12) {
                if let log = todayWornLog, !log.items.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(log.items, id: \.id) { item in
                                wornItemCell(item)
                            }
                        }
                        .padding(.horizontal, 2)
                    }
                    Button {
                        showWornLogSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "pencil")
                                .font(.system(size: 13))
                            Text("수정하기")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(Color.gray.opacity(0.08))
                        .cornerRadius(10)
                    }
                } else {
                    HStack(spacing: 10) {
                        Image(systemName: "questionmark.circle")
                            .font(.system(size: 28))
                            .foregroundColor(AppColor.primary.opacity(0.5))
                        VStack(alignment: .leading, spacing: 2) {
                            Text("오늘은 무엇을 입으셨나요?")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(AppColor.darkText)
                            Text("내 옷장에서 오늘 착용한 옷을 기록해보세요")
                                .font(.system(size: 12, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    Button {
                        showWornLogSheet = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "plus")
                                .font(.system(size: 13, weight: .semibold))
                            Text("착용 기록하기")
                                .font(.system(size: 13, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColor.primary)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(16)
            .background(.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

    private func wornItemCell(_ item: WornLogItem) -> some View {
        VStack(spacing: 4) {
            Group {
                if let path = item.imageUrl, !path.isEmpty,
                   let url = URL(string: APIClient.shared.baseURL + path) {
                    CachedAsyncImage(url: url) {
                        ZStack {
                            LinearGradient(colors: [AppColor.primary.opacity(0.3), AppColor.lightBlue.opacity(0.4)],
                                startPoint: .topLeading, endPoint: .bottomTrailing)
                            Image(systemName: "tshirt.fill").foregroundColor(.white.opacity(0.7))
                        }
                    }
                } else {
                    ZStack {
                        LinearGradient(colors: [AppColor.primary.opacity(0.3), AppColor.lightBlue.opacity(0.4)],
                            startPoint: .topLeading, endPoint: .bottomTrailing)
                        Image(systemName: "tshirt.fill").foregroundColor(.white.opacity(0.7))
                    }
                }
            }
            .frame(width: 72, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(item.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppColor.darkText)
                .lineLimit(1)
                .frame(width: 72)
        }
    }

    private func fetchWeather(lat: Double, lon: Double) async {
        do {
            weather = try await WeatherService.shared.fetch(lat: lat, lon: lon)
        } catch {
            print("날씨 오류: \(error)")
        }
        isLoading = false
    }

    private func requestTodayRecommendation() async {
        guard let weather else { return }
        isLoadingRecommendation = true
        do {
            todayRecommendation = try await APIClient.shared.recommendToday(
                temperature: weather.temperature,
                condition: weather.conditionKorean
            )
        } catch {
            print("오늘 코디 추천 오류: \(error)")
        }
        isLoadingRecommendation = false
    }

    private var weatherCard: some View {
        ZStack(alignment: .topLeading) {
            LinearGradient(
                colors: [AppColor.primary, AppColor.lightBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .cornerRadius(20)

            if isLoading {
                HStack {
                    ProgressView()
                        .tint(.white)
                        .scaleEffect(1.5)
                    Spacer()
                }
                .padding(24)
                .frame(height: 140)
            } else {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("\(weather?.temperature ?? 23)°")
                            .font(.system(size: 64, weight: .bold))
                            .foregroundColor(.white)

                        HStack(spacing: 20) {
                            HStack(spacing: 6) {
                                Image(systemName: "drop.fill")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.95))
                                Text("\(weather?.humidity ?? 58)%")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.95))
                            }
                            HStack(spacing: 6) {
                                Image(systemName: "wind")
                                    .font(.system(size: 14))
                                    .foregroundColor(.white.opacity(0.95))
                                Text(String(format: "%.1fm/s", weather?.windSpeed ?? 3.0))
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundColor(.white.opacity(0.95))
                            }
                        }
                    }

                    Spacer()

                    Text(weather?.emoji ?? "☀️")
                        .font(.system(size: 60))
                }
                .padding(24)
            }
        }
        .shadow(color: AppColor.primary.opacity(0.3), radius: 12, x: 0, y: 6)
    }

    private var aiOutfitCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            HStack(spacing: 8) {
                Text("오늘의 추천 코디")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColor.darkText)
                Text("AI")
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(AppColor.primary)
                    .cornerRadius(12)
            }
            .padding(.bottom, 12)

            VStack(alignment: .leading, spacing: 16) {
                if let w = weather {
                    HStack(spacing: 10) {
                        Text(w.emoji)
                            .font(.system(size: 28))
                        VStack(alignment: .leading, spacing: 2) {
                            Text(locationManager.displayName)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundColor(AppColor.darkBlue)
                            Text("\(w.temperature)° · \(w.conditionKorean)")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                }

                if let rec = todayRecommendation {
                    MarkdownText(text: rec, fontSize: 15, textColor: AppColor.darkText)
                        .frame(maxWidth: .infinity, alignment: .leading)
                } else if isLoadingRecommendation {
                    HStack(spacing: 8) {
                        ProgressView().tint(AppColor.primary)
                        Text("AI가 코디 추천 중...")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                    }
                }

                Button {
                    Task { await requestTodayRecommendation() }
                } label: {
                    Text(todayRecommendation == nil ? "내 옷장에서 코디 받기" : "다시 추천받기")
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(isLoadingRecommendation ? AppColor.primary.opacity(0.5) : AppColor.primary)
                        .cornerRadius(14)
                }
                .disabled(isLoadingRecommendation || weather == nil)
            }
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
    }

}

private struct LookbookCard: View {
    let imageName: String
    let temperature: Int?
    let condition: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Image(imageName)
                .resizable()
                .scaledToFill()
                .frame(width: 160, height: 200)
                .clipped()

            HStack(spacing: 4) {
                if let temp = temperature {
                    tagView("#\(temp)도")
                }
                if let cond = condition {
                    tagView("#\(cond)")
                }
            }
            .padding(12)
        }
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .clipped()
    }

    private func tagView(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(AppColor.darkBlue)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColor.background)
            .cornerRadius(12)
    }
}
