import SwiftUI

@main
struct SyncaApp: App {
    @StateObject private var mainViewModel = MainViewModel()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(mainViewModel)
                .preferredColorScheme(.dark)
        }
    }
}
