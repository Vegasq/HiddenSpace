import SwiftUI
import Network
import GeminiProtocol

struct GeminiTextParser: View {
    let text: String
    let parentUrl: String

    var urlClickedCallback: ((String?) -> Void)? = nil

    mutating func setCallback(url: String) {
        if let urlClickedCallback = self.urlClickedCallback {
            urlClickedCallback(url);
        }
    }

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(text.replacingOccurrences(of: "\r", with: "\n").split(separator: "\n"), id: \.self) { line in
                Group {
                    if line.starts(with: "#"){
                        self.renderHeader(line: String(line)).padding(.bottom, 12)
                    } else if line.starts(with: "=>") {
                        self.renderLink(line: String(line)).padding(.bottom, 12)
                    } else {
                        self.renderText(line: String(line)).padding(.bottom, 12)
                    }
                }
            }
        }
    }
    
    func addPrefixIfNeeded(url: String) -> String {
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return String(url);
        }
        if !url.hasPrefix("gemini://") {
            return String(self.parentUrl + String(url));
        }
        return String(url)
    }

    func callback(url: String){
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            UIApplication.shared.open(URL(string: url)!);
        } else {
            self.urlClickedCallback!(url);
//            self.browser.loadPage(url: url);
        }
    }

    func parseGeminiLink(_ link: String) -> (url: String, description: String) {
        // Regular expression pattern to match the Gemini link format
        let pattern = "^=>\\s*(\\S+)(?:\\s+(.*))?$"

        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsrange = NSRange(link.startIndex..<link.endIndex, in: link)

            if let match = regex.firstMatch(in: link, range: nsrange) {
                let urlRange = match.range(at: 1)
                let descriptionRange = match.range(at: 2)

                if let urlSubstring = Range(urlRange, in: link) {
                    let url = String(link[urlSubstring])
                    let description: String? = {
                        if let descriptionSubstring = Range(descriptionRange, in: link) {
                            return String(link[descriptionSubstring])
                        }
                        return nil
                    }()
                    return (url, description ?? url)
                }
            }
        } catch {
            print("Invalid regular expression: \(error.localizedDescription)")
        }

        return (link, link)
    }

    @ViewBuilder
    func renderText(line: String) -> some View {
        Text(line.trimmingCharacters(in: .whitespacesAndNewlines))
    }

    @ViewBuilder
    func renderHeader(line: String) -> some View {
        if line.starts(with: "###") {
            Text(line.dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines)).font(.title3)
        } else if line.starts(with: "##") {
            Text(line.dropFirst(2).trimmingCharacters(in: .whitespacesAndNewlines)).font(.title2)
        } else if line.starts(with: "##") {
            Text(line.dropFirst(1).trimmingCharacters(in: .whitespacesAndNewlines)).font(.title)
        }
    }

    @ViewBuilder
    func renderLink(line: String) -> some View {
        let (url, description) = parseGeminiLink(line)
        let fullUrl = self.addPrefixIfNeeded(url: url)

        Button(action: {
            self.callback(url: fullUrl);
        }) {
            HStack {
                Text(description.trimmingCharacters(in: .whitespacesAndNewlines))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }

        }
    }
}
