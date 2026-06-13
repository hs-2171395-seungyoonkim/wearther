import SwiftUI
import PhotosUI

struct EditClothingView: View {
    @Environment(\.dismiss) private var dismiss
    let item: ClosetItem
    let onUpdate: (ClosetItem) -> Void

    @State private var name: String
    @State private var brand: String
    @State private var selectedCategory: Int
    @State private var selectedTags: Set<String> = []
    @State private var tempMin: Double
    @State private var tempMax: Double
    @State private var isLoading = false
    @State private var errorMessage: String?

    @State private var photoItem: PhotosPickerItem?
    @State private var selectedImageData: Data?
    @State private var selectedUIImage: UIImage?

    private let categories = ["상의", "하의", "아우터", "신발"]
    private let categoryValues = ["TOP", "BOTTOM", "OUTERWEAR", "SHOES"]
    private let suggestedTags = ["#봄", "#여름", "#가을", "#겨울", "#사계절", "#여행", "#레이어드", "#캐주얼", "#포멀"]

    init(item: ClosetItem, onUpdate: @escaping (ClosetItem) -> Void) {
        self.item = item
        self.onUpdate = onUpdate
        _name = State(initialValue: item.name)
        _brand = State(initialValue: item.brand ?? "")
        let catIndex = ["TOP": 0, "BOTTOM": 1, "OUTERWEAR": 2, "SHOES": 3][item.category] ?? 0
        _selectedCategory = State(initialValue: catIndex)
        _selectedTags = State(initialValue: Set(item.tags.map { $0.hasPrefix("#") ? $0 : "#\($0)" }))
        _tempMin = State(initialValue: Double(item.suitableTempMin ?? 10))
        _tempMax = State(initialValue: Double(item.suitableTempMax ?? 25))
    }

    var body: some View {
        NavigationStack {
            ZStack {
                AppColor.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        photoSection

                        VStack(spacing: 16) {
                            formField(label: "아이템 이름", placeholder: "화이트 티셔츠", text: $name)
                            formField(label: "브랜드", placeholder: "Uniqlo", text: $brand)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("카테고리")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)

                            HStack(spacing: 8) {
                                ForEach(categories.indices, id: \.self) { index in
                                    Button {
                                        selectedCategory = index
                                    } label: {
                                        Text(categories[index])
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(selectedCategory == index ? .white : AppColor.darkText)
                                            .padding(.horizontal, 16)
                                            .padding(.vertical, 10)
                                            .background(selectedCategory == index ? AppColor.primary : .white)
                                            .cornerRadius(12)
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 12)
                                                    .stroke(selectedCategory == index ? AppColor.primary : Color.gray.opacity(0.2))
                                            )
                                    }
                                }
                            }
                        }

                        tempRangeSection

                        VStack(alignment: .leading, spacing: 10) {
                            Text("태그")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(.gray)

                            LazyVGrid(columns: [GridItem(.adaptive(minimum: 72))], spacing: 8) {
                                ForEach(suggestedTags, id: \.self) { tag in
                                    Button {
                                        if selectedTags.contains(tag) {
                                            selectedTags.remove(tag)
                                        } else {
                                            selectedTags.insert(tag)
                                        }
                                    } label: {
                                        Text(tag)
                                            .font(.system(size: 13, weight: .semibold))
                                            .foregroundColor(selectedTags.contains(tag) ? .white : AppColor.darkBlue)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 8)
                                            .frame(maxWidth: .infinity)
                                            .background(selectedTags.contains(tag) ? AppColor.primary : AppColor.background)
                                            .cornerRadius(12)
                                    }
                                }
                            }
                        }

                        if let error = errorMessage {
                            Text(error)
                                .font(.system(size: 13, weight: .medium))
                                .foregroundColor(.red)
                        }

                        Button {
                            Task { await save() }
                        } label: {
                            ZStack {
                                Text("저장하기")
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
            .navigationTitle("옷 수정하기")
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
            .onChange(of: photoItem) { _, newItem in
                Task {
                    guard let item = newItem,
                          let data = try? await item.loadTransferable(type: Data.self) else { return }
                    selectedImageData = data
                    selectedUIImage = UIImage(data: data)
                }
            }
        }
    }

    private var photoSection: some View {
        PhotosPicker(selection: $photoItem, matching: .images) {
            ZStack {
                if let image = selectedUIImage {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(maxWidth: .infinity)
                        .frame(height: 200)
                        .clipped()
                        .cornerRadius(20)
                } else if let path = item.imageUrl, !path.isEmpty,
                          let url = URL(string: APIClient.shared.baseURL + path) {
                    CachedAsyncImage(url: url) {
                        placeholderPhotoView
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 200)
                    .clipped()
                    .cornerRadius(20)
                } else {
                    placeholderPhotoView
                }

                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("사진 변경")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(.black.opacity(0.45))
                            .cornerRadius(12)
                            .padding(12)
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 200)
            .cornerRadius(20)
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
        }
    }

    private var placeholderPhotoView: some View {
        ZStack {
            LinearGradient(
                colors: [AppColor.lightBlue.opacity(0.2), AppColor.primary.opacity(0.15)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            VStack(spacing: 10) {
                Image(systemName: "camera.fill")
                    .font(.system(size: 32))
                    .foregroundColor(AppColor.primary.opacity(0.6))
                Text("사진 선택")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(AppColor.primary.opacity(0.8))
            }
        }
    }

    private var tempRangeSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("적정 기온")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.gray)
                Spacer()
                Text("\(Int(tempMin))° – \(Int(tempMax))°")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(AppColor.primary)
            }

            VStack(spacing: 12) {
                HStack {
                    Text("최저 \(Int(tempMin))°")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 60, alignment: .leading)
                    Slider(value: $tempMin, in: -20...40, step: 1)
                        .tint(AppColor.primary)
                        .onChange(of: tempMin) { _, val in
                            if val > tempMax - 1 { tempMax = val + 1 }
                        }
                }
                HStack {
                    Text("최고 \(Int(tempMax))°")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.gray)
                        .frame(width: 60, alignment: .leading)
                    Slider(value: $tempMax, in: -20...45, step: 1)
                        .tint(AppColor.lightBlue)
                        .onChange(of: tempMax) { _, val in
                            if val < tempMin + 1 { tempMin = val - 1 }
                        }
                }
            }
        }
        .padding(16)
        .background(.white)
        .cornerRadius(14)
        .overlay(RoundedRectangle(cornerRadius: 14).stroke(Color.gray.opacity(0.15)))
    }

    private func save() async {
        guard !name.isEmpty else {
            errorMessage = "아이템 이름을 입력해주세요."
            return
        }
        isLoading = true
        errorMessage = nil
        let tagsString = selectedTags.map { $0.replacingOccurrences(of: "#", with: "") }.joined(separator: ",")
        do {
            var updated = try await APIClient.shared.updateClosetItem(
                id: item.id,
                name: name,
                brand: brand,
                category: categoryValues[selectedCategory],
                tags: tagsString,
                tempMin: Int(tempMin),
                tempMax: Int(tempMax)
            )
            if let imageData = selectedImageData {
                updated = try await APIClient.shared.updateClosetItemImage(id: item.id, imageData: imageData)
            }
            onUpdate(updated)
            dismiss()
        } catch {
            print("옷 수정 오류: \(error)")
            errorMessage = "수정에 실패했어요. 다시 시도해주세요."
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
