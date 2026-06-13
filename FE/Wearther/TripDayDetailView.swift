import SwiftUI

struct TripDayDetailView: View {
    let day: TripDayResponse
    let destination: String
    @Binding var suggestions: [OutfitSuggestion]

    @State private var isLoadingSuggestions = false
    @State private var savingIndex: Int? = nil
    @State private var savedIndices: Set<Int> = []

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                weatherCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                outfitSuggestionsSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("\(day.dayNumber)일차 · \(day.formattedDate)")
        .navigationBarTitleDisplayMode(.inline)
        .task { if suggestions.isEmpty { await loadSuggestions() } }
    }

    // MARK: - Weather Card

    private var weatherCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(day.locationName ?? destination)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.white)

            HStack(alignment: .center) {
                HStack(alignment: .firstTextBaseline, spacing: 6) {
                    Text("\(day.temperatureInt)°")
                        .font(.system(size: 52, weight: .bold))
                        .foregroundColor(.white)
                    Text(day.weatherCondition ?? "–")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white.opacity(0.85))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 4) {
                    Text(day.conditionEmoji)
                        .font(.system(size: 44))
                    Text("강수 \(day.rainChance ?? 0)%")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(.white.opacity(0.8))
                }
            }

            let rain = day.rainChance ?? 0
            HStack(spacing: 8) {
                Image(systemName: rain > 30 ? "umbrella.fill" : "sun.max.fill")
                    .font(.system(size: 13))
                    .foregroundColor(.white.opacity(0.7))
                Text(rain > 30 ? "우산을 챙기세요" : "우산은 필요 없어요")
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(.white.opacity(0.15))
            .cornerRadius(10)
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: [AppColor.primary, AppColor.darkBlue],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
        )
        .cornerRadius(20)
        .shadow(color: AppColor.primary.opacity(0.3), radius: 12, x: 0, y: 6)
    }

    // MARK: - Outfit Suggestions

    private var outfitSuggestionsSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Image(systemName: "wand.and.sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(AppColor.primary)
                Text("AI 코디 추천")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColor.darkText)
                Spacer()
                Text("AI")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.white)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(AppColor.primary)
                    .cornerRadius(8)
            }

            if isLoadingSuggestions {
                VStack(spacing: 12) {
                    ProgressView().tint(AppColor.primary)
                    Text("AI가 날씨에 맞는 코디를 추천하는 중...")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 32)
                .background(.white)
                .cornerRadius(16)
                .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)

            } else if suggestions.isEmpty {
                Button {
                    Task { await loadSuggestions() }
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "wand.and.sparkles")
                            .font(.system(size: 15))
                        Text("이 날씨에 맞는 코디 3가지 추천받기")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColor.primary)
                    .cornerRadius(16)
                    .shadow(color: AppColor.primary.opacity(0.25), radius: 8, x: 0, y: 4)
                }

            } else {
                VStack(spacing: 12) {
                    ForEach(Array(suggestions.enumerated()), id: \.offset) { index, suggestion in
                        outfitCard(index: index, suggestion: suggestion)
                    }

                    Button {
                        suggestions = []
                        Task { await loadSuggestions() }
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.clockwise")
                                .font(.system(size: 13, weight: .semibold))
                            Text("다시 추천받기")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(AppColor.primary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(AppColor.primary.opacity(0.08))
                        .cornerRadius(12)
                    }
                }
            }
        }
    }

    private func outfitCard(index: Int, suggestion: OutfitSuggestion) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(alignment: .top) {
                Text("코디 추천 \(index + 1)")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColor.primary)
                Spacer()
                Button {
                    Task { await saveOutfit(index: index, suggestion: suggestion) }
                } label: {
                    if savingIndex == index {
                        ProgressView().tint(AppColor.primary).frame(width: 60, height: 30)
                    } else if savedIndices.contains(index) {
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark").font(.system(size: 11, weight: .bold))
                            Text("저장됨").font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(Color.gray)
                        .cornerRadius(10)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "bookmark").font(.system(size: 11, weight: .bold))
                            Text("저장하기").font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(AppColor.primary)
                        .padding(.horizontal, 12).padding(.vertical, 6)
                        .background(AppColor.primary.opacity(0.1))
                        .cornerRadius(10)
                    }
                }
                .disabled(savingIndex != nil || savedIndices.contains(index))
            }

            let catOrder = ["TOP": 0, "BOTTOM": 1, "OUTERWEAR": 2, "SHOES": 3]
            let sortedItems = suggestion.items.sorted {
                (catOrder[$0.category] ?? 4) < (catOrder[$1.category] ?? 4)
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(sortedItems, id: \.id) { outfitItem in
                        itemCell(outfitItem)
                    }
                }
                .padding(.horizontal, 2)
            }

            VStack(alignment: .leading, spacing: 4) {
                Text("추천 이유")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColor.primary)
                Text(suggestion.description)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
                    .lineSpacing(3)
            }
            .padding(12)
            .background(AppColor.background)
            .cornerRadius(10)
        }
        .padding(16)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func itemCell(_ outfitItem: OutfitSuggestionItem) -> some View {
        let categoryLabel = outfitItem.category == "TOP" ? "상의"
            : outfitItem.category == "BOTTOM" ? "하의"
            : outfitItem.category == "OUTERWEAR" ? "아우터"
            : "신발"

        return VStack(spacing: 4) {
            Group {
                if let path = outfitItem.imageUrl, !path.isEmpty,
                   let url = URL(string: APIClient.shared.baseURL + path) {
                    CachedAsyncImage(url: url) {
                        gradientPlaceholder(name: outfitItem.name, category: outfitItem.category)
                    }
                } else {
                    gradientPlaceholder(name: outfitItem.name, category: outfitItem.category)
                }
            }
            .frame(width: 88, height: 100)
            .clipShape(RoundedRectangle(cornerRadius: 14))

            Text(categoryLabel)
                .font(.system(size: 10, weight: .bold))
                .foregroundColor(AppColor.primary)

            Text(outfitItem.name)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(AppColor.darkText)
                .lineLimit(1)
                .frame(width: 88)
        }
    }

    private func gradientPlaceholder(name: String, category: String) -> some View {
        let colors: [Color] = {
            switch category {
            case "TOP": return [AppColor.primary.opacity(0.6), AppColor.lightBlue.opacity(0.8)]
            case "BOTTOM": return [AppColor.darkBlue.opacity(0.5), AppColor.primary.opacity(0.4)]
            case "OUTERWEAR": return [Color(red: 80/255, green: 60/255, blue: 120/255).opacity(0.6), AppColor.darkBlue.opacity(0.5)]
            default: return [Color.gray.opacity(0.4), Color.gray.opacity(0.6)]
            }
        }()

        return ZStack {
            LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
            VStack(spacing: 4) {
                Image(systemName: category == "TOP" ? "tshirt.fill" : category == "BOTTOM" ? "rectangle.fill" : category == "OUTERWEAR" ? "cloud.fill" : "shoeprints.fill")
                    .font(.system(size: 18))
                    .foregroundColor(.white.opacity(0.7))
                Text(name)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundColor(.white.opacity(0.9))
                    .multilineTextAlignment(.center)
                    .lineLimit(2)
                    .padding(.horizontal, 6)
            }
        }
    }

    // MARK: - Actions

    private func loadSuggestions() async {
        isLoadingSuggestions = true
        do {
            suggestions = try await APIClient.shared.getOutfitSuggestionsForCity(
                temperature: day.temperatureInt,
                condition: day.weatherCondition ?? "맑음"
            )
        } catch {
            print("코디 추천 오류: \(error)")
        }
        isLoadingSuggestions = false
    }

    private func saveOutfit(index: Int, suggestion: OutfitSuggestion) async {
        savingIndex = index
        do {
            _ = try await APIClient.shared.createOutfit(
                description: suggestion.description,
                weatherCondition: day.weatherCondition ?? "맑음",
                tempMin: day.temperatureInt - 2,
                tempMax: day.temperatureInt + 2,
                closetItemIds: suggestion.items.map { $0.id }
            )
            savedIndices.insert(index)
        } catch {
            print("코디 저장 오류: \(error)")
        }
        savingIndex = nil
    }
}
