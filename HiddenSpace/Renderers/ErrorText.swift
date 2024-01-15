import SwiftUI
import Network


struct ErrorTextParser: View {
    let data: Data;
    var text: String {
        String(data: data, encoding: .utf8) ?? ""
    }

    @State private var scale: CGFloat = 1.0

    var body: some View {
        VStack(alignment: .leading) {
            Spacer()
            HStack{
                Spacer()
                Text("❌")
                Spacer()
            }
            HStack{
                Spacer()
                Text(text)
                Spacer()
            }
            Spacer()
        }
        .textSelection(.enabled)
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    self.scale = value
                }
        )

    }
}
