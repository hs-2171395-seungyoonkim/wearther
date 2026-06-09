import SwiftUI

struct ClosetDetailView: View {
    let item: ClosetItem

    private let pairings = ["블루 데님 재킷", "블랙 슬랙스", "화이트 스니커즈"]
    private let chips = ["#상의", "#봄", "#여름", "#레이어드", "#여행필수"]

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

                todayPairingCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                Button {
                } label: {
                    Text("이 옷으로 코디 추천 받기")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColor.primary)
                        .cornerRadius(16)
                        .shadow(color: AppColor.primary.opacity(0.25), radius: 8, x: 0, y: 4)
                }
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
                Button {
                } label: {
                    Image(systemName: "ellipsis")
                        .foregroundColor(AppColor.darkText)
                }
            }
        }
    }

    private var imageCard: some View {
        VStack(alignment: .leading, spacing: 0) {
            ZStack {
                LinearGradient(
                    colors: [.white, Color(red: 234/255, green: 251/255, blue: 255/255), AppColor.lightBlue.opacity(0.45)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                Text("착용 12회")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(AppColor.darkBlue)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(.white.opacity(0.8))
                    .cornerRadius(20)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                    .padding(20)

                Image(systemName: "heart.fill")
                    .font(.system(size: 20))
                    .foregroundColor(Color(red: 255/255, green: 107/255, blue: 122/255))
                    .frame(width: 40, height: 40)
                    .background(.white.opacity(0.8))
                    .clipShape(Circle())
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                    .padding(20)

                RoundedRectangle(cornerRadius: 36)
                    .fill(.white)
                    .frame(width: 190, height: 220)
                    .shadow(color: AppColor.primary.opacity(0.15), radius: 20, x: 0, y: 8)
                    .overlay(
                        Image(systemName: "tshirt")
                            .font(.system(size: 60))
                            .foregroundColor(AppColor.primary.opacity(0.55))
                    )
            }
            .frame(height: 340)

            VStack(alignment: .leading, spacing: 0) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(item.name)
                            .font(.system(size: 26, weight: .bold))
                            .foregroundColor(AppColor.darkText)
                        Text("\(item.brand) · AIRism Cotton")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                    }

                    Spacer()

                    Text("상의")
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

    private var statsGrid: some View {
        HStack(spacing: 12) {
            statCard(icon: "thermometer.sun.fill", label: "적정 기온", value: "18°–27°")
            statCard(icon: "calendar", label: "최근 착용", value: "6월 3일")
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

            Text("습도가 높은 날에도 산뜻해요. 여행지에서는 데님 재킷을 걸치면 아침저녁 일교차까지 커버할 수 있어요.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.gray)
                .lineSpacing(4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private var todayPairingCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "cloud.sun.fill")
                    .font(.system(size: 18))
                    .foregroundColor(AppColor.lightBlue)
                Text("오늘 함께 입기")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(pairings, id: \.self) { pairing in
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.lightBlue)
                        Text(pairing)
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
}
