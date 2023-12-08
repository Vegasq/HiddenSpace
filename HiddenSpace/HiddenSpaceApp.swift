import SwiftUI
import SwiftData
import GeminiProtocol

@main
struct HiddenSpaceApp: App {
    init(){
        URLProtocol.registerClass(GeminiProtocol.self)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
