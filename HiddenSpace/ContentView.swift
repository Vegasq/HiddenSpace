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
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            return String(url);
        }
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
    
    func callback(url: String){
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            UIApplication.shared.open(URL(string: url)!);
        } else {
            self.browser.loadPage(url: url);
        }
    }
    
    @ViewBuilder
    func renderLink(line: Substring) -> some View {
        let parts = String(line).replacingOccurrences(of: "\t", with: " ").split(separator: " ", maxSplits: 2, omittingEmptySubsequences: true)
        let url = self.addPrefixIfNeeded(url: parts[1])

        if parts.count == 1 {
            Text(String(line))
        } else if parts.count == 2 {
            Button(action: {
                self.callback(url: url);
                
//                print("GOTO", url, parts)
            }) {
                HStack {
                    Text(parts[1]).frame(maxWidth: .infinity, alignment: .leading).multilineTextAlignment(.leading)
                    Spacer()
                }
            }
        } else if parts.count >= 3 {
            Button(action: {
                self.callback(url: url);
//                self.browser.loadPage(url: url);
//                UIApplication.shared.open(URL(string: url)!);
                print("GOTO", url, parts)
            }) {
                HStack {
                    Text(parts[2]).frame(maxWidth: .infinity, alignment: .leading).multilineTextAlignment(.leading)
                    Spacer()
                }
            }
        }
    }
}


struct ContentView: View {
    @State var geminiURL = "gemini://geminiprotocol.net/"
    @State private var responseText = ""
    
    @State private var history: [String] = []
    @State private var historyIndex = 0

    @State private var bookmarks: [String] = []
    @State var showingBookmarkList = false
    private let bookmarksKey = "bookmarksKey"

    var body: some View {
        let dragToRight = DragGesture()
            .onEnded {
                if $0.translation.width > 100 {
                    goBack()
                }
            }

        let dragToLeft = DragGesture()
            .onEnded {
                if $0.translation.width < -100 {
                    goForward()
                }
            }


        return VStack {


            ScrollView {
                GeminiTextParser(text: responseText, browser: self)
            }

            HStack {
                Button("+") {
                    saveBookmark()
                }
                
                Button("List") {
                    listBookmarks()
                }
                
                // Existing UI
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
        }
        .sheet(isPresented: $showingBookmarkList) {
            BookmarkListView(bookmarks: $bookmarks, browser: self)
        }
        .gesture(dragToRight)
        .gesture(dragToLeft)
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: {
            self.loadBookmarks()
            self.loadPage(url: self.geminiURL)
        })


    }

    func saveBookmark() {
        if !bookmarks.contains(geminiURL) {
            bookmarks.append(geminiURL)
            UserDefaults.standard.set(bookmarks, forKey: bookmarksKey)
        }
    }


    func listBookmarks() {
        showingBookmarkList = true
    }

    // In your ContentView
    func fetchGeminiContent() {
        if geminiURL != history.last {
            history.append(geminiURL);
            historyIndex = history.count - 1;
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
    
    func loadPage(url: String){
        self.geminiURL = url;
        self.fetchGeminiContent();
    }

    func loadBookmarks() {
        if let loadedBookmarks = UserDefaults.standard.object(forKey: bookmarksKey) as? [String] {
            bookmarks = loadedBookmarks
        }
    }

}

struct BookmarkListView: View {
    @Binding var bookmarks: [String]
    let browser: ContentView

    var body: some View {
        NavigationView {
            List(bookmarks, id: \.self) { bookmark in
                Button(bookmark) {
                    self.browser.loadPage(url: bookmark)
                    self.browser.showingBookmarkList = false;
                }
            }
            .navigationBarTitle("Bookmarks", displayMode: .inline)
        }
    }
}
