import SwiftUI

struct ClosetView: View {
    @State private var selectedCategory = 0
    @State private var showAddClothing = false
    @State private var items: [ClosetItem] = []
    @State private var isLoading = true

    private let categories = ["전체", "상의", "하의", "아우터", "신발"]
    private let categoryValues: [String?] = [nil, "TOP", "BOTTOM", "OUTERWEAR", "SHOES"]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Text("내 옷장")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColor.darkText)

                        Text("\(items.count)개")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 4)
                            .background(AppColor.primary)
                            .cornerRadius(16)

                        Spacer()
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 20)

                    categoryTabs
                        .padding(.bottom, 16)

                    if isLoading {
                        ProgressView()
                            .tint(AppColor.primary)
                            .frame(maxWidth: .infinity)
                            .padding(.top, 60)
                    } else if items.isEmpty {
                        VStack(spacing: 12) {
                            Image(systemName: "tshirt")
                                .font(.system(size: 48))
                                .foregroundColor(AppColor.primary.opacity(0.4))
                            Text("아직 등록된 옷이 없어요")
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.gray)
                            Text("+ 버튼으로 첫 아이템을 추가해보세요")
                                .font(.system(size: 13))
                                .foregroundColor(.gray.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        LazyVGrid(
                            columns: [
                                GridItem(.flexible(), spacing: 12),
                                GridItem(.flexible(), spacing: 12)
                            ],
                            spacing: 12
                        ) {
                            ForEach(items) { item in
                                NavigationLink(destination: ClosetDetailView(item: item)) {
                                    ClosetItemCard(item: item)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(AppColor.background.ignoresSafeArea())

            Button {
                showAddClothing = true
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
        .sheet(isPresented: $showAddClothing, onDismiss: { Task { await loadItems() } }) {
            AddClothingView()
        }
        .task { await loadItems() }
        .onChange(of: selectedCategory) { _, _ in Task { await loadItems() } }
    }

    private func loadItems() async {
        isLoading = true
        let cat = categoryValues[selectedCategory]
        items = (try? await APIClient.shared.getClosetItems(category: cat)) ?? []
        isLoading = false
    }

    private var categoryTabs: some View {
        VStack(spacing: 0) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 20) {
                    ForEach(categories.indices, id: \.self) { index in
                        Button {
                            selectedCategory = index
                        } label: {
                            VStack(spacing: 0) {
                                Text(categories[index])
                                    .font(.system(size: 15, weight: .semibold))
                                    .foregroundColor(selectedCategory == index ? AppColor.primary : Color.gray.opacity(0.7))
                                    .padding(.bottom, 10)

                                Rectangle()
                                    .fill(selectedCategory == index ? AppColor.primary : Color.clear)
                                    .frame(height: 2)
                                    .cornerRadius(1)
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
            }

            Divider()
        }
    }
}

private struct ClosetItemCard: View {
    let item: ClosetItem

    private var imageURL: URL? {
        guard let path = item.imageUrl, !path.isEmpty else { return nil }
        return URL(string: APIClient.shared.baseURL + path)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [AppColor.lightBlue.opacity(0.2), AppColor.primary.opacity(0.2)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                if let url = imageURL {
                    CachedAsyncImage(url: url) {
                        Image(systemName: "tshirt.fill")
                            .font(.system(size: 48))
                            .foregroundColor(AppColor.primary.opacity(0.4))
                    }
                } else {
                    Image(systemName: "tshirt.fill")
                        .font(.system(size: 48))
                        .foregroundColor(AppColor.primary.opacity(0.4))
                }
            }
            .frame(height: 180)
            .clipped()

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColor.darkText)

                        Text(item.brand ?? "")
                            .font(.system(size: 12))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white)
                        .frame(width: 28, height: 28)
                        .background(AppColor.primary)
                        .clipShape(Circle())
                }
                .padding(.bottom, 8)

                HStack(spacing: 6) {
                    ForEach(item.tags.prefix(2), id: \.self) { tag in
                        Text(tag)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(AppColor.darkBlue)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(AppColor.background)
                            .cornerRadius(10)
                    }
                }
            }
            .padding(14)
        }
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
        .clipped()
    }
}
