import SwiftUI

struct WornLogCalendarView: View {
    @State private var currentMonth: Date = {
        let cal = Calendar.current
        let comps = cal.dateComponents([.year, .month], from: Date())
        return cal.date(from: comps) ?? Date()
    }()
    @State private var wornLogs: [WornLog] = []
    @State private var isLoading = false
    @State private var selectedLog: WornLog?
    @State private var showLogSheet = false

    private let calendar = Calendar.current
    private let dayFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "d"; return f
    }()
    private let isoFormatter: DateFormatter = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"; return f
    }()

    private var yearMonth: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "ko_KR")
        f.dateFormat = "yyyy년 M월"
        return f.string(from: currentMonth)
    }

    private var logsByDate: [String: WornLog] {
        Dictionary(uniqueKeysWithValues: wornLogs.map { ($0.date, $0) })
    }

    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    monthHeader
                    calendarGrid
                    if let log = selectedLog {
                        selectedDayDetail(log: log)
                    }
                }
                .padding(.horizontal, 20)
                .padding(.vertical, 16)
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("착용 캘린더")
            .navigationBarTitleDisplayMode(.inline)
            .task { await loadLogs() }
            .sheet(isPresented: $showLogSheet) {
                WornLogSheet(onSave: { await loadLogs() })
            }
        }
    }

    private var monthHeader: some View {
        HStack {
            Button {
                currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth
                Task { await loadLogs() }
            } label: {
                Image(systemName: "chevron.left")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.darkText)
                    .frame(width: 40, height: 40)
                    .background(.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
            }

            Spacer()

            Text(yearMonth)
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(AppColor.darkText)

            Spacer()

            Button {
                currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth
                Task { await loadLogs() }
            } label: {
                Image(systemName: "chevron.right")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(AppColor.darkText)
                    .frame(width: 40, height: 40)
                    .background(.white)
                    .clipShape(Circle())
                    .shadow(color: .black.opacity(0.07), radius: 4, x: 0, y: 2)
            }
        }
    }

    private var calendarGrid: some View {
        VStack(spacing: 0) {
            HStack {
                ForEach(["일", "월", "화", "수", "목", "금", "토"], id: \.self) { d in
                    Text(d)
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(.gray)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.vertical, 12)

            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(daysInMonth(), id: \.self) { date in
                    if let date {
                        dayCell(date: date)
                    } else {
                        Color.clear.frame(height: 56)
                    }
                }
            }
        }
        .padding(16)
        .background(.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func dayCell(date: Date) -> some View {
        let dateStr = isoFormatter.string(from: date)
        let log = logsByDate[dateStr]
        let isToday = calendar.isDateInToday(date)
        let isSelected = selectedLog?.date == dateStr

        return Button {
            if let log {
                selectedLog = (selectedLog?.date == dateStr) ? nil : log
            } else if calendar.isDateInToday(date) {
                showLogSheet = true
            }
        } label: {
            VStack(spacing: 2) {
                ZStack {
                    Circle()
                        .fill(isToday ? AppColor.primary : (isSelected ? AppColor.primary.opacity(0.15) : Color.clear))
                        .frame(width: 32, height: 32)

                    Text(dayFormatter.string(from: date))
                        .font(.system(size: 13, weight: isToday ? .bold : .medium))
                        .foregroundColor(isToday ? .white : AppColor.darkText)
                }

                if let log, !log.items.isEmpty {
                    HStack(spacing: 2) {
                        ForEach(log.items.prefix(3), id: \.id) { item in
                            itemDot(item: item)
                        }
                    }
                } else {
                    Spacer().frame(height: 14)
                }
            }
            .frame(height: 56)
        }
        .buttonStyle(.plain)
    }

    private func itemDot(item: WornLogItem) -> some View {
        Group {
            if let path = item.imageUrl, !path.isEmpty,
               let url = URL(string: APIClient.shared.baseURL + path) {
                CachedAsyncImage(url: url) {
                    Circle().fill(AppColor.primary.opacity(0.4))
                }
            } else {
                Circle().fill(AppColor.primary.opacity(0.4))
            }
        }
        .frame(width: 14, height: 14)
        .clipShape(Circle())
    }

    @ViewBuilder
    private func selectedDayDetail(log: WornLog) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(formattedDate(log.date))
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColor.darkText)
                Spacer()
                Text("\(log.items.count)개 아이템")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.gray)
            }

            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(log.items, id: \.id) { item in
                        itemCard(item: item)
                    }
                }
            }
        }
        .padding(16)
        .background(.white)
        .cornerRadius(20)
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }

    private func itemCard(item: WornLogItem) -> some View {
        VStack(spacing: 6) {
            Group {
                if let path = item.imageUrl, !path.isEmpty,
                   let url = URL(string: APIClient.shared.baseURL + path) {
                    CachedAsyncImage(url: url) {
                        categoryPlaceholder(item.category)
                    }
                } else {
                    categoryPlaceholder(item.category)
                }
            }
            .frame(width: 72, height: 84)
            .clipShape(RoundedRectangle(cornerRadius: 12))

            Text(item.name)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(AppColor.darkText)
                .lineLimit(1)
                .frame(width: 72)
        }
    }

    private func categoryPlaceholder(_ category: String) -> some View {
        ZStack {
            LinearGradient(
                colors: [AppColor.primary.opacity(0.4), AppColor.lightBlue.opacity(0.5)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            Image(systemName: "tshirt.fill")
                .font(.system(size: 20))
                .foregroundColor(.white.opacity(0.7))
        }
    }

    private func daysInMonth() -> [Date?] {
        let range = calendar.range(of: .day, in: .month, for: currentMonth)!
        let firstWeekday = calendar.component(.weekday, from: currentMonth) - 1
        var days: [Date?] = Array(repeating: nil, count: firstWeekday)
        for day in range {
            var comps = calendar.dateComponents([.year, .month], from: currentMonth)
            comps.day = day
            days.append(calendar.date(from: comps))
        }
        return days
    }

    private func formattedDate(_ dateStr: String) -> String {
        let parts = dateStr.split(separator: "-")
        guard parts.count == 3,
              let month = Int(parts[1]),
              let day = Int(parts[2]) else { return dateStr }
        return "\(month)월 \(day)일"
    }

    private func loadLogs() async {
        isLoading = true
        let comps = calendar.dateComponents([.year, .month], from: currentMonth)
        if let year = comps.year, let month = comps.month {
            wornLogs = (try? await APIClient.shared.getWornLogs(year: year, month: month)) ?? []
        }
        isLoading = false
    }
}

// MARK: - WornLogSheet

struct WornLogSheet: View {
    @Environment(\.dismiss) private var dismiss
    let onSave: () async -> Void

    @State private var items: [ClosetItem] = []
    @State private var selectedIds: Set<Int> = []
    @State private var isSaving = false
    @State private var isLoading = true

    private let today: String = {
        let f = DateFormatter(); f.dateFormat = "yyyy-MM-dd"
        return f.string(from: Date())
    }()

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView().tint(AppColor.primary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(
                            columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)],
                            spacing: 12
                        ) {
                            ForEach(items) { item in
                                selectionCell(item: item)
                            }
                        }
                        .padding(20)
                    }
                }
            }
            .background(AppColor.background.ignoresSafeArea())
            .navigationTitle("오늘 입은 옷 선택")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("취소") { dismiss() }
                        .foregroundColor(.gray)
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        Task { await save() }
                    } label: {
                        if isSaving {
                            ProgressView().tint(AppColor.primary)
                        } else {
                            Text("저장 (\(selectedIds.count))")
                                .font(.system(size: 15, weight: .bold))
                                .foregroundColor(selectedIds.isEmpty ? .gray : AppColor.primary)
                        }
                    }
                    .disabled(selectedIds.isEmpty || isSaving)
                }
            }
            .task { items = (try? await APIClient.shared.getClosetItems()) ?? []; isLoading = false }
        }
    }

    private func selectionCell(item: ClosetItem) -> some View {
        let isSelected = selectedIds.contains(item.id)
        return Button {
            if isSelected { selectedIds.remove(item.id) }
            else { selectedIds.insert(item.id) }
        } label: {
            ZStack(alignment: .topTrailing) {
                VStack(alignment: .leading, spacing: 0) {
                    ZStack {
                        LinearGradient(
                            colors: [AppColor.lightBlue.opacity(0.2), AppColor.primary.opacity(0.15)],
                            startPoint: .topLeading, endPoint: .bottomTrailing
                        )
                        if let path = item.imageUrl, !path.isEmpty,
                           let url = URL(string: APIClient.shared.baseURL + path) {
                            CachedAsyncImage(url: url) {
                                Image(systemName: "tshirt.fill")
                                    .font(.system(size: 36))
                                    .foregroundColor(AppColor.primary.opacity(0.4))
                            }
                        } else {
                            Image(systemName: "tshirt.fill")
                                .font(.system(size: 36))
                                .foregroundColor(AppColor.primary.opacity(0.4))
                        }
                    }
                    .frame(height: 120)
                    .clipped()

                    VStack(alignment: .leading, spacing: 2) {
                        Text(item.name)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(AppColor.darkText)
                            .lineLimit(1)
                        Text(item.brand ?? "")
                            .font(.system(size: 11))
                            .foregroundColor(.gray)
                    }
                    .padding(10)
                }
                .background(.white)
                .cornerRadius(16)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(isSelected ? AppColor.primary : Color.clear, lineWidth: 2.5)
                )
                .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)

                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 22))
                        .foregroundColor(AppColor.primary)
                        .background(Circle().fill(.white).padding(2))
                        .padding(8)
                }
            }
        }
        .buttonStyle(.plain)
    }

    private func save() async {
        isSaving = true
        do {
            _ = try await APIClient.shared.logWorn(date: today, closetItemIds: Array(selectedIds))
            await onSave()
            dismiss()
        } catch {
            print("착용 기록 저장 오류: \(error)")
        }
        isSaving = false
    }
}
