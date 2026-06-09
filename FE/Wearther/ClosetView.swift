import SwiftUI

struct ClosetItem: Identifiable {
    let id = UUID()
    let name: String
    let brand: String
    let tags: [String]
}

struct ClosetView: View {
    @State private var selectedCategory = 0

    private let categories = ["전체", "상의", "하의", "아우터", "신발"]
    private let items = [
        ClosetItem(name: "화이트 티셔츠", brand: "Uniqlo", tags: ["#봄", "#여름"]),
        ClosetItem(name: "블루 데님 재킷", brand: "Levi's", tags: ["#봄", "#가을"]),
        ClosetItem(name: "블랙 슬랙스", brand: "Zara", tags: ["#사계절"]),
        ClosetItem(name: "그레이 니트", brand: "COS", tags: ["#가을", "#겨울"]),
        ClosetItem(name: "화이트 스니커즈", brand: "Nike", tags: ["#사계절"]),
        ClosetItem(name: "트렌치코트", brand: "Burberry", tags: ["#봄", "#가을"])
    ]

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 8) {
                        Text("내 옷장")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColor.darkText)

                        Text("24개")
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
                .padding(.top, 16)
                .padding(.bottom, 100)
            }
            .background(AppColor.background.ignoresSafeArea())

            Button {
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

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [
                        AppColor.lightBlue.opacity(0.2),
                        AppColor.primary.opacity(0.2)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Image(systemName: "tshirt.fill")
                    .font(.system(size: 48))
                    .foregroundColor(AppColor.primary.opacity(0.4))
            }
            .frame(height: 180)

            VStack(alignment: .leading, spacing: 4) {
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(AppColor.darkText)

                        Text(item.brand)
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
                    ForEach(item.tags, id: \.self) { tag in
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
