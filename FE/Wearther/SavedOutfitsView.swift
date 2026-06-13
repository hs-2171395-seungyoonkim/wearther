import SwiftUI

struct SavedOutfitsView: View {
    @State private var outfits: [OutfitResponse] = []
    @State private var isLoading = true
    @State private var selectedOutfit: OutfitResponse?

    var savedOutfits: [OutfitResponse] { outfits }

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().tint(AppColor.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if savedOutfits.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bookmark.slash")
                            .font(.system(size: 48))
                            .foregroundColor(AppColor.primary.opacity(0.4))
                        Text("저장된 코디가 없어요")
                            .font(.system(size: 17, weight: .semibold))
                            .foregroundColor(AppColor.darkText)
                        Text("옷장에서 코디 추천을 받고\n마음에 드는 코디를 저장해보세요")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVStack(spacing: 16) {
                            ForEach(savedOutfits) { outfit in
                                OutfitCard(outfit: outfit) {
                                    selectedOutfit = outfit
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                    }
                }
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("저장된 코디")
            .navigationBarTitleDisplayMode(.inline)
            .task { await load() }
            .sheet(item: $selectedOutfit) { outfit in
                NavigationStack {
                    OutfitDetailView(outfit: outfit)
                }
            }
        }
    }

    private func load() async {
        isLoading = true
        outfits = (try? await APIClient.shared.getOutfits()) ?? []
        isLoading = false
    }
}

private struct OutfitCard: View {
    let outfit: OutfitResponse
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(outfit.description ?? "코디")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundColor(AppColor.darkText)
                        if let score = outfit.compatibilityScore {
                            HStack(spacing: 4) {
                                Image(systemName: "star.fill")
                                    .font(.system(size: 11))
                                    .foregroundColor(.orange)
                                Text("호환성 \(score)점")
                                    .font(.system(size: 12, weight: .medium))
                                    .foregroundColor(.gray)
                            }
                        }
                    }
                    Spacer()
                    Image(systemName: "bookmark.fill")
                        .font(.system(size: 16))
                        .foregroundColor(AppColor.primary)
                }

                if !outfit.items.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 8) {
                            ForEach(outfit.items) { item in
                                itemThumb(item)
                            }
                        }
                    }
                }

                if let min = outfit.temperatureMin, let max = outfit.temperatureMax {
                    Text("\(min)°–\(max)°")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColor.darkBlue)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(AppColor.background)
                        .cornerRadius(10)
                }
            }
            .padding(16)
            .background(.white)
            .cornerRadius(20)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }

    private func itemThumb(_ item: OutfitItemInResponse) -> some View {
        Group {
            if let path = item.imageUrl, !path.isEmpty,
               let url = URL(string: APIClient.shared.baseURL + path) {
                CachedAsyncImage(url: url) {
                    placeholderView
                }
            } else {
                placeholderView
            }
        }
        .frame(width: 72, height: 80)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var placeholderView: some View {
        ZStack {
            LinearGradient(
                colors: [AppColor.primary.opacity(0.3), AppColor.lightBlue.opacity(0.4)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Image(systemName: "tshirt.fill")
                .font(.system(size: 22))
                .foregroundColor(.white.opacity(0.7))
        }
    }
}
