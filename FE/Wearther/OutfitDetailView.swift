import SwiftUI

struct OutfitDetailView: View {
    let outfit: OutfitResponse
    @State private var isBookmarked: Bool
    @State private var isBookmarking = false

    init(outfit: OutfitResponse) {
        self.outfit = outfit
        self._isBookmarked = State(initialValue: outfit.bookmarked)
    }

    private var tempRange: String {
        if let min = outfit.temperatureMin, let max = outfit.temperatureMax {
            return "\(min)°–\(max)°"
        } else if let min = outfit.temperatureMin {
            return "\(min)° 이상"
        } else if let max = outfit.temperatureMax {
            return "\(max)° 이하"
        }
        return "–"
    }

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                outfitItemsCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                statsRow
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                itemsListCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                Button {
                    Task { await bookmarkOutfit() }
                } label: {
                    HStack(spacing: 8) {
                        if isBookmarking {
                            ProgressView().tint(.white).scaleEffect(0.8)
                        }
                        Text(isBookmarked ? "저장됨" : "이 코디 저장하기")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(.white)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(isBookmarked ? AppColor.darkBlue : AppColor.primary)
                    .cornerRadius(16)
                    .shadow(color: AppColor.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                }
                .disabled(isBookmarked || isBookmarking)
                .padding(.horizontal, 24)
                .padding(.bottom, 32)
            }
            .padding(.top, 16)
        }
        .background(AppColor.background.ignoresSafeArea())
        .navigationTitle("코디 상세")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button {
                    Task { await bookmarkOutfit() }
                } label: {
                    Image(systemName: isBookmarked ? "bookmark.fill" : "bookmark")
                        .font(.system(size: 18))
                        .foregroundColor(isBookmarked ? AppColor.primary : AppColor.darkText)
                }
                .disabled(isBookmarked || isBookmarking)
            }
        }
    }

    private func bookmarkOutfit() async {
        guard !isBookmarked else { return }
        isBookmarking = true
        do {
            let updated = try await APIClient.shared.toggleBookmark(outfitId: outfit.id)
            isBookmarked = updated.bookmarked
        } catch {
            print("북마크 오류: \(error)")
            isBookmarked = true
        }
        isBookmarking = false
    }

    private var outfitItemsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("AI PICK")
                .font(.system(size: 11, weight: .bold))
                .foregroundColor(.white)
                .padding(.horizontal, 10)
                .padding(.vertical, 4)
                .background(AppColor.primary)
                .cornerRadius(8)

            LazyVGrid(columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ], spacing: 12) {
                ForEach(outfit.items) { item in
                    ZStack {
                        LinearGradient(
                            colors: [AppColor.lightBlue.opacity(0.2), AppColor.primary.opacity(0.15)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                        VStack(spacing: 8) {
                            if let path = item.imageUrl, !path.isEmpty,
                               let url = URL(string: APIClient.shared.baseURL + path) {
                                CachedAsyncImage(url: url) {
                                    Image(systemName: "tshirt.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(AppColor.primary.opacity(0.5))
                                }
                                .frame(width: 52, height: 52)
                                .clipShape(RoundedRectangle(cornerRadius: 8))
                            } else {
                                Image(systemName: "tshirt.fill")
                                    .font(.system(size: 28))
                                    .foregroundColor(AppColor.primary.opacity(0.5))
                            }
                            Text(item.name)
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColor.darkText)
                                .multilineTextAlignment(.center)
                        }
                        .padding(12)
                    }
                    .frame(height: 110)
                    .cornerRadius(14)
                }
            }

            VStack(alignment: .leading, spacing: 4) {
                if let condition = outfit.weatherCondition {
                    Text("\(tempRange) · \(condition)")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundColor(.gray)
                }
                if let desc = outfit.description, !desc.isEmpty {
                    Text(desc)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColor.darkText)
                        .lineSpacing(4)
                }
            }
        }
        .padding(20)
        .background(.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            statCard(
                icon: "checkmark.circle.fill",
                label: "날씨 적합도",
                value: outfit.compatibilityScore.map { "\($0)%" } ?? "–"
            )
            statCard(icon: "thermometer.medium", label: "추천 기온", value: tempRange)
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
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var itemsListCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("구성 아이템")
                .font(.system(size: 18, weight: .bold))
                .foregroundColor(AppColor.darkText)

            VStack(spacing: 10) {
                ForEach(outfit.items) { item in
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppColor.primary)
                        VStack(alignment: .leading, spacing: 2) {
                            Text(item.name)
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(AppColor.darkText)
                            if let brand = item.brand, !brand.isEmpty {
                                Text(brand)
                                    .font(.system(size: 12))
                                    .foregroundColor(.gray)
                            }
                        }
                        Spacer()
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}
