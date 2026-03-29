import SwiftUI

struct ContentView: View {
    @EnvironmentObject var viewModel: MainViewModel

    var body: some View {
        MainView()
    }
}

#Preview {
    ContentView()
        .environmentObject(MainViewModel())
        .preferredColorScheme(.dark)
}
