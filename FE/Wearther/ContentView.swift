import SwiftUI

enum AppColor {
    static let background = Color(red: 240/255, green: 250/255, blue: 255/255)
    static let primary = Color(red: 0, green: 180/255, blue: 216/255)
    static let lightBlue = Color(red: 144/255, green: 224/255, blue: 239/255)
    static let darkBlue = Color(red: 0, green: 119/255, blue: 182/255)
    static let darkText = Color(red: 26/255, green: 26/255, blue: 46/255)
}

struct ContentView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("홈", systemImage: "house.fill")
                }

            TravelView()
                .tabItem {
                    Label("여행", systemImage: "map.fill")
                }

            NavigationStack {
                ClosetView()
            }
            .tabItem {
                Label("옷장", systemImage: "tshirt.fill")
            }

            ProfileView()
                .tabItem {
                    Label("프로필", systemImage: "person.fill")
                }
        }
        .tint(AppColor.primary)
    }
}
