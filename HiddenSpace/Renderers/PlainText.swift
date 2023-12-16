import SwiftUI
import Network


struct PlainTextParser: View {
    let data: Data;
    var text: String {
        String(data: data, encoding: .utf8) ?? ""
    }

    @State private var scale: CGFloat = 1.0

    var lines: [String] {
        text.components(separatedBy: .newlines)
    }


    var body: some View {
        VStack(alignment: .leading) {
            ForEach(lines, id: \.self) { line in
                Text(line)
                    .font(.system(size: 14 * scale))
                    .textSelection(.enabled)

            }
        }
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    self.scale = value
                }
        )

    }
    
}
