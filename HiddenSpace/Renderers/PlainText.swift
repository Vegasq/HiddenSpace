import SwiftUI
import Network


struct PlainTextParser: View {
    let data: Data;
    var text: String {
        String(data: data, encoding: .utf8) ?? ""
    }

    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading) {
            Text(text)
        }
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    self.scale = value
                }
        )

    }
    
}
