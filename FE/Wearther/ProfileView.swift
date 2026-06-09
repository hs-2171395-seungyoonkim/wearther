import SwiftUI

struct ProfileView: View {
    private let stats = [
        ("18", "저장한 코디"),
        ("7", "여행지"),
        ("24", "옷장 아이템")
    ]

    private let menus: [(icon: String, label: String, detail: String)] = [
        ("sparkles", "AI 추천 취향 설정", "미니멀 · 캐주얼"),
        ("mappin", "기본 위치", "서울, 마포구"),
        ("bell.fill", "날씨 알림", "오전 8:00"),
        ("shield.fill", "개인정보 및 연결", "안전")
    ]

    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 0) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("MY WEARTHER")
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.darkBlue)
                        Text("프로필")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColor.darkText)
                    }
                    Spacer()
                    Button {
                    } label: {
                        Image(systemName: "gearshape.fill")
                            .font(.system(size: 18))
                            .foregroundColor(AppColor.darkText)
                            .frame(width: 40, height: 40)
                            .background(.white)
                            .clipShape(Circle())
                            .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 20)

                // Profile card
                profileCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                // AI recommendation card
                aiRecommendCard
                    .padding(.horizontal, 24)
                    .padding(.bottom, 16)

                // Settings menus
                VStack(spacing: 10) {
                    ForEach(menus, id: \.label) { menu in
                        menuRow(icon: menu.icon, label: menu.label, detail: menu.detail)
                    }
                }
                .padding(.horizontal, 24)
            }
            .padding(.top, 16)
            .padding(.bottom, 24)
        }
        .background(AppColor.background.ignoresSafeArea())
    }

    private var profileCard: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .topTrailing) {
                Circle()
                    .fill(AppColor.lightBlue.opacity(0.35))
                    .frame(width: 144, height: 144)
                    .offset(x: 40, y: -40)

                VStack(alignment: .leading, spacing: 0) {
                    HStack(spacing: 16) {
                        RoundedRectangle(cornerRadius: 26)
                            .fill(
                                LinearGradient(
                                    colors: [AppColor.primary, AppColor.lightBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 76, height: 76)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: AppColor.primary.opacity(0.2), radius: 8, x: 0, y: 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("지민 님")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppColor.darkText)
                            Text("맑은 날씨에 어울리는 여행자")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)

                            HStack(spacing: 6) {
                                Image(systemName: "cloud.sun.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColor.darkBlue)
                                Text("Seoul · 23°")
                                    .font(.system(size: 12, weight: .bold))
                                    .foregroundColor(AppColor.darkBlue)
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 4)
                            .background(AppColor.background)
                            .cornerRadius(20)
                        }
                    }
                    .padding(.bottom, 20)

                    HStack(spacing: 8) {
                        ForEach(stats, id: \.0) { stat in
                            VStack(spacing: 4) {
                                Text(stat.0)
                                    .font(.system(size: 20, weight: .bold))
                                    .foregroundColor(AppColor.darkText)
                                Text(stat.1)
                                    .font(.system(size: 11, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .multilineTextAlignment(.center)
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(red: 248/255, green: 253/255, blue: 255/255))
                            .cornerRadius(16)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color(red: 221/255, green: 246/255, blue: 255/255), lineWidth: 1)
                            )
                        }
                    }
                }
                .padding(20)
            }
            .background(.white)
            .cornerRadius(24)
            .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

            Text("🌤️")
                .font(.system(size: 44))
                .offset(x: 80, y: -44)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.trailing, 32)
                .allowsHitTesting(false)
        }
        .clipped()
    }

    private var aiRecommendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("WEARTHER AI")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(.white.opacity(0.7))
                    Text("여행 전 체크리스트")
                        .font(.system(size: 19, weight: .bold))
                        .foregroundColor(.white)
                }
                Spacer()
                Image(systemName: "heart.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppColor.lightBlue)
            }

            Text("이번 주 도쿄는 일교차가 커요. 얇은 아우터와 레이어드 가능한 상의를 옷장에 추가해보세요.")
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.white.opacity(0.85))
                .lineSpacing(4)
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

    private func menuRow(icon: String, label: String, detail: String) -> some View {
        Button {
        } label: {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 18))
                    .foregroundColor(AppColor.primary)
                    .frame(width: 40, height: 40)
                    .background(AppColor.background)
                    .cornerRadius(14)

                VStack(alignment: .leading, spacing: 2) {
                    Text(label)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(AppColor.darkText)
                    Text(detail)
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14))
                    .foregroundColor(Color.gray.opacity(0.4))
            }
            .padding(16)
            .background(.white)
            .cornerRadius(16)
            .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}
