import SwiftUI

struct AppNavigationView: View {
    var body: some View {
        NavigationStack {
            HomeView()
        }
        .preferredColorScheme(.dark)
    }
}

#Preview {
    AppNavigationView()
}
