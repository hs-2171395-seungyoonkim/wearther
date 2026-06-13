import SwiftUI

struct LoginView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                VStack(spacing: 0) {
                    Spacer()

                    VStack(spacing: 12) {
                        Image("WeartherLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 100)

                        Text("여행 날씨에 맞춰 내 옷장으로 코디하기")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.bottom, 52)

                    VStack(spacing: 12) {
                        featureRow(icon: "cloud.sun.fill", color: AppColor.primary,
                                   title: "날씨 기반 추천", subtitle: "여행지 기온 분석")
                        featureRow(icon: "tshirt.fill", color: AppColor.darkBlue,
                                   title: "내 옷장 코디", subtitle: "보유 의류 매칭")
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)

                    Spacer()

                    VStack(spacing: 12) {
                        NavigationLink(destination: EmailLoginView()) {
                            Text("이메일로 로그인")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(AppColor.primary)
                                .cornerRadius(14)
                        }

                        NavigationLink(destination: SignupView()) {
                            Text("새 계정 만들기")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundColor(AppColor.darkText)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(.white)
                                .cornerRadius(14)
                                .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.2)))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 48)
                }
            }
            .navigationBarHidden(true)
        }
    }

    private func featureRow(icon: String, color: Color, title: String, subtitle: String) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 20))
                .foregroundColor(color)
                .frame(width: 48, height: 48)
                .background(color.opacity(0.1))
                .cornerRadius(14)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(AppColor.darkText)
                Text(subtitle)
                    .font(.system(size: 13, weight: .medium))
                    .foregroundColor(.gray)
            }
            Spacer()
        }
        .padding(16)
        .background(.white)
        .cornerRadius(16)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct EmailLoginView: View {
    @AppStorage("isLoggedIn") private var isLoggedIn = false
    @State private var email = ""
    @State private var password = ""
    @State private var keepLoggedIn = false
    @State private var isLoading = false
    @State private var errorMessage: String?

    var body: some View {
        ZStack {
            AppColor.background.ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 0) {
                    VStack(spacing: 8) {
                        Image("WeartherLogo")
                            .resizable()
                            .scaledToFit()
                            .frame(height: 70)
                        Text("다시 만나서 반가워요 👋")
                            .font(.system(size: 15, weight: .medium))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 40)
                    .padding(.bottom, 40)

                    VStack(spacing: 16) {
                        inputField(placeholder: "이메일", text: $email, isSecure: false)
                        inputField(placeholder: "비밀번호", text: $password, isSecure: true)

                        Toggle(isOn: $keepLoggedIn) {
                            Text("로그인 유지")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                        .toggleStyle(SwitchToggleStyle(tint: AppColor.primary))
                        .padding(.horizontal, 4)
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

                    VStack(spacing: 12) {
                        Button {
                            Task { await login() }
                        } label: {
                            ZStack {
                                Text("로그인")
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

                        Button {
                        } label: {
                            Text("비밀번호 찾기")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.gray)
                        }
                    }
                    .padding(.horizontal, 24)
                }
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func login() async {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "이메일과 비밀번호를 입력해주세요."
            return
        }
        isLoading = true
        errorMessage = nil
        do {
            try await APIClient.shared.login(email: email, password: password)
            isLoggedIn = true
        } catch {
            errorMessage = "로그인에 실패했어요. 이메일과 비밀번호를 확인해주세요."
        }
        isLoading = false
    }

    private func inputField(placeholder: String, text: Binding<String>, isSecure: Bool) -> some View {
        Group {
            if isSecure {
                SecureField(placeholder, text: text)
                    .font(.system(size: 15))
            } else {
                TextField(placeholder, text: text)
                    .font(.system(size: 15))
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 16)
        .background(.white)
        .cornerRadius(12)
        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.gray.opacity(0.15)))
    }
}
