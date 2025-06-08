import SwiftUI
import SystemSettingsNavigator

struct MainView: View {
    @Environment(\.openSystemSettings)
    var openSystemSettings
    
    var body: some View {
        VStack {
            Image(nsImage: NSApplication.shared.applicationIconImage)
                .resizable()
                .frame(width: 100, height: 100)

            VStack {
                Button {
                    openSystemSettings(.privacySecurity(.extensions(.xcodeSourceEditor)))
                } label: {
                    Text("Open Extension Settings")
                }
            }
        }
        .frame(minWidth: 300)
        .padding()
    }
}

#Preview {
    MainView()
}
