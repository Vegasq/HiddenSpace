import SwiftUI
import Network
import GeminiProtocol

struct GeminiTextParser: View {
    let text: String
    let browser: ContentView

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(text.split(separator: "\n"), id: \.self) { line in
                Group {
                    if line.starts(with: "# ") || line.starts(with: "## ") || line.starts(with: "### ") {
                        renderHeader(line: line)
                    } else if line.starts(with: "=> ") {
                        renderLink(line: line)
                    } else {
                        Text(String(line))
                    }
                }
            }
        }
    }
    
    func addPrefixIfNeeded(url: Substring) -> String {
        if !url.hasPrefix("gemini://") {
            return self.browser.geminiURL + String(url)
        }
        return String(url)
    }
    
    @ViewBuilder
    func renderHeader(line: Substring) -> some View {
        if line.starts(with: "# ") {
            Text(String(line.dropFirst(2))).font(.title)
        } else if line.starts(with: "## ") {
            Text(String(line.dropFirst(3))).font(.title2)
        } else if line.starts(with: "### ") {
            Text(String(line.dropFirst(4))).font(.title3)
        }
    }
    
    @ViewBuilder
    func renderLink(line: Substring) -> some View {
        let parts = String(line).replacingOccurrences(of: "\t", with: " ").split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)

        if parts.count == 1 {
            Text(String(line))
        } else if parts.count == 2 {
            let url = self.addPrefixIfNeeded(url: parts[1])
            Button(action: {
                self.browser.geminiURL = url;
                self.browser.fetchGeminiContent();
                print("GOTO", url, parts)
            }) {
                Text(url)
            }
        } else if parts.count >= 3 {
            let url = self.addPrefixIfNeeded(url: parts[1])
            Button(action: {
                self.browser.geminiURL = url;
                self.browser.fetchGeminiContent();
                print("GOTO", url, parts)
            }) {
                Text(parts[2])
            }
        }
    }
}

public class GeminiURLResponse2: URLResponse {
    var statusCode: GeminiStatusCode
    var meta: String
    
    public override var mimeType: String? {
        statusCode.isSuccess ? meta : nil
    }
    
    public var metaData: String? {
        return self.meta
    }
    
    init(url: URL, expectedContentLength: Int, statusCode: GeminiStatusCode, meta: String) {
        self.statusCode = statusCode
        self.meta = meta
        
        let mimeType = statusCode.isSuccess ? meta : nil
        super.init(url: url, mimeType: mimeType, expectedContentLength: expectedContentLength, textEncodingName: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}


struct ContentView: View {
//    @State var geminiURL = "gemini://geminiprotocol.net/docs/faq.gmifaq-section-1.gmi"
    @State var geminiURL = "gemini://geminiprotocol.net/"
    @State private var responseText = ""
    
    @State private var history: [String] = []
    @State private var historyIndex = 0

    var body: some View {
        VStack {
            HStack {
                TextField("Enter Gemini URL", text: $geminiURL)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .padding()

                Button("Go") {
                    fetchGeminiContent()
                }.padding(.trailing, 20)

                Button("<") {
                    goBack()
                }.disabled(historyIndex <= 0)

                Button(">") {
                    goForward()
                }.disabled(historyIndex >= history.count - 1)

            }

            ScrollView {
                GeminiTextParser(text: responseText, browser: self)
            }
        }
    }

    // In your ContentView
    func fetchGeminiContent() {
        if geminiURL != history.last {
            history.append(geminiURL)
            historyIndex = history.count - 1
        }

        let url = URL(string: self.geminiURL)!
        let session = URLSession.shared

        let task = session.dataTask(with: url) { data, response, error in
            if let error = error {
                print("Error took place \(error)")
                return
            }

            if let data = data, let dataString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.responseText = dataString
                }
            }
        }
        task.resume()
    }

    func goBack() {
        if historyIndex > 0 {
            historyIndex -= 1
            geminiURL = history[historyIndex]
            fetchGeminiContent()
        }
    }

    func goForward() {
        if historyIndex < history.count - 1 {
            historyIndex += 1
            geminiURL = history[historyIndex]
            fetchGeminiContent()
        }
    }

}
