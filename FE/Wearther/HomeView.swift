import SwiftUI

struct HomeView: View {
    @StateObject private var locationManager = LocationManager()
    @State private var weather: WeatherInfo?
    @State private var isLoading = true

    private let defaultLat = 37.5665
    private let defaultLon = 126.9780

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                Text("Wearther")
                    .font(.system(size: 26, weight: .bold))
                    .foregroundColor(AppColor.primary)
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

                Text("이 날씨 룩북")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(AppColor.darkText)
                    .padding(.bottom, 12)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(1...3, id: \.self) { _ in
                            LookbookCard(temperature: weather?.temperature, condition: weather?.conditionKorean)
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
        .task {
            locationManager.request()
            await fetchWeather(lat: defaultLat, lon: defaultLon)
        }
        .onChange(of: locationManager.latitude) { _, lat in
            guard let lat, let lon = locationManager.longitude else { return }
            Task { await fetchWeather(lat: lat, lon: lon) }
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Text("오늘의 추천 코디 ✨")
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

            VStack(alignment: .leading, spacing: 12) {
                Text("얇은 면 티셔츠 + 크롭 데님 재킷 + 흰 스니커즈")
                    .font(.system(size: 15, weight: .medium))
                    .foregroundColor(AppColor.darkText)
                    .lineSpacing(4)

                Text("날씨 적합도 92%")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(AppColor.darkBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppColor.lightBlue.opacity(0.3))
                    .cornerRadius(16)
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
    let temperature: Int?
    let condition: String?

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [AppColor.lightBlue.opacity(0.2), AppColor.primary.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                Image(systemName: "sparkles")
                    .font(.system(size: 40))
                    .foregroundColor(AppColor.primary.opacity(0.4))
            }
            .frame(width: 160, height: 200)

            HStack(spacing: 6) {
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
