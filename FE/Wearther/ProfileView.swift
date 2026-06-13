import SwiftUI
import UserNotifications

struct ProfileView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var profile: UserProfileResponse?
    @State private var nextTrip: TripResponse?
    @State private var nextTripDays: [TripDayResponse] = []

    @State private var showSavedOutfits = false
    @State private var showStyleSheet = false
    @State private var showLocationSheet = false
    @State private var showNotificationSheet = false

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 0) {
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
                            isLoggedIn = false
                            APIClient.shared.token = nil
                        } label: {
                            Image(systemName: "rectangle.portrait.and.arrow.right")
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

                    profileCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)

                    aiRecommendCard
                        .padding(.horizontal, 24)
                        .padding(.bottom, 16)

                    VStack(spacing: 10) {
                        menuRow(
                            icon: "sparkles",
                            label: "AI 추천 취향 설정",
                            detail: profile?.stylePreference ?? "설정 안됨"
                        ) { showStyleSheet = true }

                        menuRow(
                            icon: "mappin",
                            label: "기본 위치",
                            detail: profile?.defaultLocation ?? "서울"
                        ) { showLocationSheet = true }

                        menuRow(
                            icon: "bell.fill",
                            label: "날씨 알림",
                            detail: profile?.notificationTime ?? "설정 안됨"
                        ) { showNotificationSheet = true }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
                .padding(.top, 16)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationDestination(isPresented: $showSavedOutfits) {
                SavedOutfitsView()
            }
            .sheet(isPresented: $showStyleSheet, onDismiss: { Task { await load() } }) {
                StylePreferenceSheet(current: profile?.stylePreference ?? "")
            }
            .sheet(isPresented: $showLocationSheet, onDismiss: { Task { await load() } }) {
                LocationSheet(current: profile?.defaultLocation ?? "")
            }
            .sheet(isPresented: $showNotificationSheet, onDismiss: { Task { await load() } }) {
                NotificationTimeSheet(current: profile?.notificationTime)
            }
            .task { await load() }
        }
    }

    private func load() async {
        async let profileFetch = APIClient.shared.getProfile()
        async let tripsFetch = APIClient.shared.getTrips()
        profile = try? await profileFetch
        let trips = (try? await tripsFetch) ?? []
        nextTrip = trips.first
        if let trip = trips.first {
            nextTripDays = (try? await APIClient.shared.getTripDays(tripId: trip.id)) ?? []
        }
    }

    // MARK: - Profile Card

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
                            .fill(LinearGradient(
                                colors: [AppColor.primary, AppColor.lightBlue],
                                startPoint: .topLeading, endPoint: .bottomTrailing
                            ))
                            .frame(width: 76, height: 76)
                            .overlay(
                                Image(systemName: "person.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(.white)
                            )
                            .shadow(color: AppColor.primary.opacity(0.2), radius: 8, x: 0, y: 4)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("\(profile?.name ?? "–") 님")
                                .font(.system(size: 22, weight: .bold))
                                .foregroundColor(AppColor.darkText)
                            Text(profile?.stylePreference ?? "맑은 날씨에 어울리는 여행자")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.gray)

                            HStack(spacing: 6) {
                                Image(systemName: "cloud.sun.fill")
                                    .font(.system(size: 12))
                                    .foregroundColor(AppColor.darkBlue)
                                Text(profile?.defaultLocation ?? "Seoul")
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
                        Button { showSavedOutfits = true } label: {
                            statCell(value: "\(profile?.stats.savedOutfits ?? 0)", label: "저장한 코디")
                        }
                        .buttonStyle(.plain)

                        statCell(value: "\(profile?.stats.tripCount ?? 0)", label: "여행지")
                        statCell(value: "\(profile?.stats.closetItemCount ?? 0)", label: "옷장 아이템")
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

    private func statCell(value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Text(value)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColor.darkText)
            Text(label)
                .font(.system(size: 11, weight: .semibold))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(Color(red: 248/255, green: 253/255, blue: 255/255))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color(red: 221/255, green: 246/255, blue: 255/255), lineWidth: 1))
    }

    // MARK: - AI Card

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
                Image(systemName: "suitcase.fill")
                    .font(.system(size: 22))
                    .foregroundColor(AppColor.lightBlue)
            }

            if let trip = nextTrip {
                VStack(alignment: .leading, spacing: 8) {
                    HStack(spacing: 6) {
                        Image(systemName: "mappin.circle.fill")
                            .font(.system(size: 13))
                            .foregroundColor(AppColor.lightBlue)
                        Text("다음 여행: \(trip.destination)")
                            .font(.system(size: 14, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Text("\(trip.startDate) – \(trip.endDate)")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.white.opacity(0.65))

                    if let packing = trip.packingList, !packing.isEmpty {
                        Text(packing)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                            .lineSpacing(4)
                    } else if let firstDay = nextTripDays.first, let condition = firstDay.weatherCondition {
                        Text("\(firstDay.temperatureInt)° · \(condition) · 코디를 미리 준비해보세요!")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.85))
                    } else {
                        Text("여행 탭에서 AI 코디 추천을 받아보세요.")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.white.opacity(0.75))
                    }
                }
            } else {
                Text("아직 여행 계획이 없어요. 여행 탭에서 첫 여행을 추가해보세요.")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.white.opacity(0.85))
                    .lineSpacing(4)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(20)
        .background(LinearGradient(
            colors: [AppColor.darkText, AppColor.darkBlue],
            startPoint: .topLeading, endPoint: .bottomTrailing
        ))
        .cornerRadius(20)
        .shadow(color: AppColor.darkBlue.opacity(0.2), radius: 8, x: 0, y: 4)
    }

    // MARK: - Menu Row

    private func menuRow(icon: String, label: String, detail: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
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

// MARK: - Style Preference Sheet

private struct StylePreferenceSheet: View {
    @Environment(\.dismiss) private var dismiss
    let current: String
    @State private var text = ""
    @State private var isSaving = false

    private let presets = ["미니멀", "캐주얼", "스트리트", "포멀", "스포티", "빈티지", "럭셔리", "레이어드"]

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("나의 스타일")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                        TextField("예: 미니멀 · 캐주얼", text: $text)
                            .font(.system(size: 15))
                            .padding(14)
                            .background(.white)
                            .cornerRadius(12)
                            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                    }

                    VStack(alignment: .leading, spacing: 10) {
                        Text("빠른 선택")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundColor(.gray)
                        LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                            ForEach(presets, id: \.self) { preset in
                                Button {
                                    if text.isEmpty { text = preset }
                                    else if !text.contains(preset) { text += " · \(preset)" }
                                } label: {
                                    Text(preset)
                                        .font(.system(size: 13, weight: .semibold))
                                        .foregroundColor(text.contains(preset) ? .white : AppColor.darkBlue)
                                        .padding(.horizontal, 14)
                                        .padding(.vertical, 8)
                                        .frame(maxWidth: .infinity)
                                        .background(text.contains(preset) ? AppColor.primary : AppColor.background)
                                        .cornerRadius(12)
                                }
                            }
                        }
                    }

                    Button {
                        Task { await save() }
                    } label: {
                        ZStack {
                            Text("저장하기")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .opacity(isSaving ? 0 : 1)
                            if isSaving { ProgressView().tint(.white) }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColor.primary)
                        .cornerRadius(14)
                    }
                    .disabled(isSaving)
                }
                .padding(24)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("AI 취향 설정")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }.foregroundColor(.gray)
                }
            }
            .onAppear { text = current }
        }
    }

    private func save() async {
        isSaving = true
        _ = try? await APIClient.shared.updateProfile(stylePreference: text)
        isSaving = false
        dismiss()
    }
}

// MARK: - Location Sheet

private struct LocationSheet: View {
    @Environment(\.dismiss) private var dismiss
    let current: String
    @State private var text = ""
    @State private var isSaving = false

    var body: some View {
        NavigationStack {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("기본 위치")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.gray)
                    TextField("예: 서울, 마포구", text: $text)
                        .font(.system(size: 15))
                        .padding(14)
                        .background(.white)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.2)))
                }

                Button {
                    Task { await save() }
                } label: {
                    ZStack {
                        Text("저장하기")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .opacity(isSaving ? 0 : 1)
                        if isSaving { ProgressView().tint(.white) }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColor.primary)
                    .cornerRadius(14)
                }
                .disabled(isSaving)

                Spacer()
            }
            .padding(24)
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("기본 위치")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }.foregroundColor(.gray)
                }
            }
            .onAppear { text = current }
        }
    }

    private func save() async {
        isSaving = true
        _ = try? await APIClient.shared.updateProfile(defaultLocation: text)
        isSaving = false
        dismiss()
    }
}

// MARK: - Notification Time Sheet

private struct NotificationTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    let current: String?
    @State private var selectedTime = Date()
    @State private var isSaving = false
    @State private var permissionDenied = false

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Image(systemName: "bell.badge.fill")
                        .font(.system(size: 40))
                        .foregroundColor(AppColor.primary)
                    Text("날씨 알림")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(AppColor.darkText)
                    Text("매일 아침 날씨와 코디 알림을 받아보세요")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.gray)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 20)

                DatePicker("알림 시각", selection: $selectedTime, displayedComponents: .hourAndMinute)
                    .datePickerStyle(.wheel)
                    .labelsHidden()

                if permissionDenied {
                    Text("알림 권한이 필요합니다. 설정 > Wearther에서 알림을 허용해주세요.")
                        .font(.system(size: 13))
                        .foregroundColor(.red)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }

                Button {
                    Task { await save() }
                } label: {
                    ZStack {
                        Text("알림 설정하기")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                            .opacity(isSaving ? 0 : 1)
                        if isSaving { ProgressView().tint(.white) }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(AppColor.primary)
                    .cornerRadius(14)
                }
                .disabled(isSaving)
                .padding(.horizontal, 24)

                Spacer()
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("날씨 알림")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }.foregroundColor(.gray)
                }
            }
            .onAppear { setInitialTime() }
        }
    }

    private func setInitialTime() {
        guard let t = current else { return }
        let parts = t.split(separator: ":")
        guard parts.count == 2,
              let h = Int(parts[0]), let m = Int(parts[1]) else { return }
        var comps = Calendar.current.dateComponents([.year, .month, .day], from: Date())
        comps.hour = h; comps.minute = m
        selectedTime = Calendar.current.date(from: comps) ?? Date()
    }

    private func save() async {
        isSaving = true
        let center = UNUserNotificationCenter.current()
        let status = await center.notificationSettings().authorizationStatus

        if status == .notDetermined {
            let granted = (try? await center.requestAuthorization(options: [.alert, .sound, .badge])) ?? false
            if !granted { permissionDenied = true; isSaving = false; return }
        } else if status == .denied {
            permissionDenied = true; isSaving = false; return
        }

        let cal = Calendar.current
        let hour = cal.component(.hour, from: selectedTime)
        let minute = cal.component(.minute, from: selectedTime)
        let timeStr = String(format: "%02d:%02d", hour, minute)

        center.removePendingNotificationRequests(withIdentifiers: ["wearther_daily"])
        let content = UNMutableNotificationContent()
        content.title = "오늘의 날씨 & 코디"
        content.body = "오늘 날씨를 확인하고 옷장에서 코디를 추천받아보세요! ☀️"
        content.sound = .default

        var triggerComps = DateComponents()
        triggerComps.hour = hour
        triggerComps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: triggerComps, repeats: true)
        let request = UNNotificationRequest(identifier: "wearther_daily", content: content, trigger: trigger)
        try? await center.add(request)

        _ = try? await APIClient.shared.updateProfile(notificationTime: timeStr)
        isSaving = false
        dismiss()
    }
}
