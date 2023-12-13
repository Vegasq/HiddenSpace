import SwiftUI
import Network
import GeminiProtocol


struct HiddenSpaceView: View {
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
                GeminiTextParser(text: self.responseText, parentUrl: self.geminiURL) { clickedUrl in
                    // Implement your URL click handling logic here
                    if let url = clickedUrl {
                        print("URL Clicked: \(url)")
                        self.loadPage(url: url);
                    }
                }
            }
            
            VStack {
                HStack {
                    TextField("Enter Gemini URL", text: $geminiURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .padding()
                    Button("Go") {
                        fetchGeminiContent()
                    }.padding(.trailing, 20)
                }

                HStack {
                    Button(action: goBack) {
                        Image(systemName: "arrow.left")
                            .padding()
                    }.disabled(historyIndex <= 0)

                    Button(action: goForward) {
                        Image(systemName: "arrow.right")
                            .padding()
                    }.disabled(historyIndex >= history.count - 1)

                    Spacer()

                    Button(action: saveBookmark) {
                        Image(systemName: "bookmark")
                            .padding()
                    }

                    Button(action: listBookmarks) {
                        Image(systemName: "list.bullet")
                            .padding()
                    }
                }
                .padding(.horizontal)
                .buttonStyle(BorderlessButtonStyle())

            }
        }
        .padding(24)
        .sheet(isPresented: $showingBookmarkList) {
            BookmarkListView(bookmarks: $bookmarks, browser: self)
        }
        .gesture(dragToRight)
        .gesture(dragToLeft)
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: {
            self.loadBookmarks()
//            self.loadPage(url: self.geminiURL)
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

    func fetchGeminiContent() {
        if geminiURL != history.last {
            history.append(geminiURL);
            historyIndex = history.count - 1;
        }

        let url = URL(string: self.geminiURL)!
        
        let cl = Client(host: url.host()!, port: UInt16(url.port ?? 1965), validateCert: false);
        cl.start();
        cl.dataReceivedCallback = self.displayGeminiContent(self.geminiURL);
        cl.send(data: (self.geminiURL + "\r\n").data(using: .utf8)!);
    }

    func displayGeminiContent(_ host: String) -> (Error?, Data?) -> Void {
        return  { error, data in
            if error != nil {
                DispatchQueue.main.async {
                    self.responseText = error?.localizedDescription ?? "Unknown error";
                }
            } else if let data = data, let dataString = String(data: data, encoding: .utf8) {
                DispatchQueue.main.async {
                    self.responseText = dataString;
                }
            }
        }
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
    let browser: HiddenSpaceView

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
