import SwiftUI

struct SignupView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var name = ""
    @State private var email = ""
    @State private var password = ""
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Text("Wearther")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(AppColor.primary)
                        Text("처음 만나서 반가워요 🎉")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 40)

                    VStack(spacing: 16) {
                        inputField(placeholder: "이름", text: $name, isSecure: false, keyboardType: .default)
                        inputField(placeholder: "이메일", text: $email, isSecure: false, keyboardType: .emailAddress)
                        inputField(placeholder: "비밀번호", text: $password, isSecure: true, keyboardType: .default)
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)

                    if let error = errorMessage {
                        Text(error)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundColor(.red)
                            .padding(.horizontal, 24)
                            .padding(.bottom, 16)
                    }

                    VStack(spacing: 10) {
                        featureCard(icon: "cloud.sun.fill", text: "여행지 날씨 기반 코디 추천")
                        featureCard(icon: "tshirt.fill", text: "내 옷장 아이템 저장")
                        featureCard(icon: "suitcase.fill", text: "일정별 패킹 리스트 생성")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 32)

                    Button {
                        Task { await signup() }
                    } label: {
                        ZStack {
                            Text("회원가입 완료")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .opacity(isLoading ? 0 : 1)
                            if isLoading {
                                ProgressView().tint(.white)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(AppColor.primary)
                        .cornerRadius(14)
                    }
                    .disabled(isLoading)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 24)
                }
            }
        }
        .navigationTitle("회원가입")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func signup() async {
        guard !name.isEmpty, !email.isEmpty, !password.isEmpty else {
            errorMessage = "모든 항목을 입력해주세요."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await APIClient.shared.signup(name: name, email: email, password: password)
            try await APIClient.shared.login(email: email, password: password)
            isLoggedIn = true
        } catch {
            errorMessage = "회원가입에 실패했어요. 이미 사용 중인 이메일일 수 있어요."
        }
        isLoading = false
    }

    private func inputField(placeholder: String, text: Binding<String>, isSecure: Bool, keyboardType: UIKeyboardType) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
                    .font(.system(size: 15))
            } else {
                TextField(placeholder, text: text)
                    .font(.system(size: 15))
                    .keyboardType(keyboardType)
                    .autocapitalization(.none)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.15)))
    }

    private func featureCard(icon: String, text: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(AppColor.primary)
                .frame(width: 36, height: 36)
                .background(AppColor.primary.opacity(0.1))
                .cornerRadius(10)

            Text(text)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(AppColor.darkText)

            Spacer()
        }
        .padding(14)
        .background(.white)
        .cornerRadius(14)
        .shadow(color: .black.opacity(0.04), radius: 4, x: 0, y: 2)
    }
}
