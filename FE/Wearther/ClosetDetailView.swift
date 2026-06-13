import SwiftUI

struct ClosetDetailView: View {
    @State private var item: ClosetItem
    var temperature: Int = 20
    var condition: String = "맑음"

    @State private var isFavorited: Bool
    @State private var aiNotes: String?
    @State private var isAnalyzing = false
    @State private var suggestions: [OutfitSuggestion] = []
    @State private var isLoadingSuggestions = false
    @State private var savingIndex: Int? = nil
    @State private var savedIndices: Set<Int> = []
    @State private var showEditSheet = false

    init(item: ClosetItem, temperature: Int = 20, condition: String = "맑음") {
        self._item = State(initialValue: item)
        self.temperature = temperature
        self.condition = condition
        self._isFavorited = State(initialValue: item.favorite)
        self._aiNotes = State(initialValue: item.aiNotes)
    }

    private var chips: [String] {
        var result = ["#\(item.category == "TOP" ? "상의" : item.category == "BOTTOM" ? "하의" : item.category == "OUTERWEAR" ? "아우터" : "신발")"]
        result += item.tags.map { $0.hasPrefix("#") ? $0 : "#\($0)" }
        return result
    }

    private var tempRange: String {
        if let min = item.suitableTempMin, let max = item.suitableTempMax {
            return "\(min)°–\(max)°"
        }
        return "–"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                imageCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                statsGrid
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                aiMemoCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                outfitSuggestionsSection
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("상세보기")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("수정하기", systemImage: "pencil")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(AppColor.darkText)
                }
            }
        }
        .sheet(isPresented: $showEditSheet) {
            EditClothingView(item: item) { updated in
                item = updated
                aiNotes = updated.aiNotes
                isFavorited = updated.favorite
            }
        }
    }

    // MARK: - Image Card

    private var imageCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [.white, Color(red: 234/255, green: 251/255, blue: 255/255), AppColor.lightBlue.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Text("착용 \(item.wearCount)회")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColor.darkBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.8))
                    .cornerRadius(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(20)

                Button {
                    isFavorited.toggle()
                } label: {
                    Image(systemName: isFavorited ? "heart.fill" : "heart")
                        .font(.system(size: 20))
                        .foregroundColor(isFavorited ? Color(red: 255/255, green: 107/255, blue: 122/255) : .gray)
                        .frame(width: 40, height: 40)
                        .background(.white.opacity(0.8))
                        .clipShape(Circle())
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                .padding(20)

                RoundedRectangle(cornerRadius: 36)
                    .fill(.white)
                    .frame(width: 190, height: 220)
                    .shadow(color: AppColor.primary.opacity(0.15), radius: 20, x: 0, y: 8)
                    .overlay(
                        Group {
                            if let path = item.imageUrl, !path.isEmpty,
                               let url = URL(string: APIClient.shared.baseURL + path) {
                                CachedAsyncImage(url: url) {
                                    Image(systemName: "tshirt")
                                        .font(.system(size: 60))
                                        .foregroundColor(AppColor.primary.opacity(0.55))
                                }
                            } else {
                                Image(systemName: "tshirt")
                                    .font(.system(size: 60))
                                    .foregroundColor(AppColor.primary.opacity(0.55))
                            }
                        }
                        .clipShape(RoundedRectangle(cornerRadius: 36))
                    )
            }
            .frame(height: 340)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppColor.darkText)
                        Text(item.brand ?? "")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Text(item.category == "TOP" ? "상의" : item.category == "BOTTOM" ? "하의" : item.category == "OUTERWEAR" ? "아우터" : "신발")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(AppColor.darkBlue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(AppColor.background)
                        .cornerRadius(12)
                }
                .padding(.bottom, 16)

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 6) {
                        ForEach(chips, id: \.self) { chip in
                            Text(chip)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColor.darkBlue)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppColor.background)
                                .cornerRadius(20)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(.white)
        .cornerRadius(28)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .overlay(RoundedRectangle(cornerRadius: 28).stroke(Color.gray.opacity(0.08)))
    }

    // MARK: - Stats Grid

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(icon: "thermometer.sun.fill", label: "적정 기온", value: tempRange)
            statCard(icon: "calendar", label: "최근 착용", value: item.lastWorn ?? "없음")
        }
    }

    private func statCard(icon: String, label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18))
                .foregroundColor(AppColor.primary)

            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundColor(.gray)

            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColor.darkText)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white)
        .cornerRadius(18)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - AI Memo Card

    private var aiMemoCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(AppColor.primary)
                Text("AI 코디 메모")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(AppColor.darkText)
            }

            if let notes = aiNotes, !notes.isEmpty {
                MarkdownText(text: notes)
            } else if isAnalyzing {
                HStack(spacing: 8) {
                    ProgressView().tint(AppColor.primary)
                    Text("AI가 분석 중...")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                }
            } else {
                Button {
                    Task { await analyzeItem() }
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 14))
                        Text("AI 스타일 분석 받기")
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
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    // MARK: - Outfit Suggestions Section

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
                    Text("AI가 오늘 날씨에 맞는 코디를 추천하는 중...")
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
                        Text("오늘 날씨에 맞는 코디 3가지 추천받기")
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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top, spacing: 8) {
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
                        HStack(spacing: 4) {
                            Image(systemName: "checkmark")
                                .font(.system(size: 11, weight: .bold))
                            Text("저장됨")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.gray)
                        .cornerRadius(10)
                    } else {
                        HStack(spacing: 4) {
                            Image(systemName: "bookmark")
                                .font(.system(size: 11, weight: .bold))
                            Text("저장하기")
                                .font(.system(size: 12, weight: .bold))
                        }
                        .foregroundColor(AppColor.primary)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
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

    private func analyzeItem() async {
        isAnalyzing = true
        do {
            let updated = try await APIClient.shared.analyzeClosetItem(id: item.id)
            aiNotes = updated.aiNotes
        } catch {
            print("AI 분석 오류: \(error)")
        }
        isAnalyzing = false
    }

    private func loadSuggestions() async {
        isLoadingSuggestions = true
        do {
            suggestions = try await APIClient.shared.getOutfitSuggestions(
                itemId: item.id,
                temperature: temperature,
                condition: condition
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
                weatherCondition: condition,
                tempMin: temperature - 2,
                tempMax: temperature + 2,
                closetItemIds: suggestion.items.map { $0.id }
            )
            savedIndices.insert(index)
        } catch {
            print("코디 저장 오류: \(error)")
        }
        savingIndex = nil
    }
}
