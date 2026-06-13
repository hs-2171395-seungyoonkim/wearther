import SwiftUI

struct AddTripView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var destination = ""
    @State private var startDate = Date()
    @State private var endDate = Date().addingTimeInterval(86400 * 2)
    @State private var travelStyle = ""
    @State private var selectedActivities: Set<String> = ["관광"]
    @State private var isLoading = false
    @State private var errorMessage: String?

    private let activities = ["관광", "맛집", "쇼핑", "야외", "문화", "휴양"]
    private let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyy-MM-dd"
        return f
    }()

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("NEW TRIP")
                                .font(.system(size: 12, weight: .bold))
                                .foregroundColor(AppColor.primary)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(AppColor.primary.opacity(0.1))
                                .cornerRadius(8)

                            Text("어디로 떠나시나요?")
                                .font(.system(size: 26, weight: .bold))
                                .foregroundColor(AppColor.darkText)

                            Text("여행지와 날짜를 넣으면 일정별 날씨와 옷차림을 미리 추천해요.")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                                .lineSpacing(4)
                        }

                        VStack(spacing: 16) {
                            formField(label: "여행지", placeholder: "도쿄, 일본", text: $destination)

                            VStack(alignment: .leading, spacing: 6) {
                                Text("출발일")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $startDate, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.white)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.15)))
                            }

                            VStack(alignment: .leading, spacing: 6) {
                                Text("귀국일")
                                    .font(.system(size: 14, weight: .semibold))
                                    .foregroundColor(.gray)
                                DatePicker("", selection: $endDate, in: startDate..., displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .padding(.horizontal, 16)
                                    .padding(.vertical, 10)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(.white)
                                    .cornerRadius(12)
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.15)))
                            }

                            formField(label: "여행 스타일", placeholder: "가볍게 걷는 도시 여행", text: $travelStyle)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("활동")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 80))], spacing: 8) {
                                ForEach(activities, id: \.self) { activity in
                                    Button {
                                        if selectedActivities.contains(activity) {
                                            selectedActivities.remove(activity)
                                        } else {
                                            selectedActivities.insert(activity)
                                        }
                                    } label: {
                                        Text(activity)
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(selectedActivities.contains(activity) ? .white : AppColor.darkText)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedActivities.contains(activity) ? AppColor.primary : .white)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedActivities.contains(activity) ? AppColor.primary : Color.gray.opacity(0.2))
                                            )
                                    }
                                }
                            }
                        }

                        HStack(alignment: .top, spacing: 16) {
                            Image(systemName: "suitcase.fill")
                                .font(.system(size: 22))
                                .foregroundColor(.white)

                            VStack(alignment: .leading, spacing: 4) {
                                Text("Wearther가 준비할 것")
                                    .font(.system(size: 15, weight: .bold))
                                    .foregroundColor(.white)
                                Text("일정별 날씨, 체감온도, 강수 확률을 확인해서 내 옷장 속 아이템으로 코디와 패킹 리스트를 만들어요.")
                                    .font(.system(size: 13, weight: .medium))
                                    .foregroundColor(.white.opacity(0.8))
                                    .lineSpacing(4)
                            }
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                colors: [AppColor.darkText, AppColor.darkBlue],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(20)

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                        }

                        Button {
                            Task { await save() }
                        } label: {
                            ZStack {
                                Text("여행계획 저장하기")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white)
                                    .opacity(isLoading ? 0 : 1)
                                if isLoading { ProgressView().tint(.white) }
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(AppColor.primary)
                            .cornerRadius(14)
                            .shadow(color: AppColor.primary.opacity(0.3), radius: 8, x: 0, y: 4)
                        }
                        .disabled(isLoading)
                        .padding(.bottom, 24)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 24)
                }
            }
            .navigationTitle("새 여행 계획")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button { dismiss() } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(AppColor.darkText)
                    }
                }
            }
        }
    }

    private func save() async {
        guard !destination.isEmpty else {
            errorMessage = "여행지를 입력해주세요."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            _ = try await APIClient.shared.createTrip(
                destination: destination,
                startDate: dateFormatter.string(from: startDate),
                endDate: dateFormatter.string(from: endDate),
                travelStyle: travelStyle.isEmpty ? nil : travelStyle,
                activities: Array(selectedActivities)
            )
            dismiss()
        } catch {
            print("여행 저장 오류: \(error)")
            errorMessage = "저장에 실패했어요. 서버 연결을 확인해주세요."
        }
        isLoading = false
    }

    private func formField(label: String, placeholder: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.gray)

            TextField(placeholder, text: text)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(.white)
                .cornerRadius(12)
                .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.15)))
        }
    }
}
