import SwiftUI
import Network


struct HiddenSpaceView: View {
    @State var geminiURL = "gemini://geminiprotocol.net/"
    @State private var responseText = ""
    @State private var responseContentType = ""
    @State private var responseStatusCode = 0
    
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
                    if let url = clickedUrl {
                        print("URL Clicked: \(url)")
                        self.loadPage(url: url);
                    }
                }
                .padding(.horizontal)
            }
            
            VStack {
                HStack {
                    TextField("Enter Gemini URL", text: $geminiURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                    Button(action: fetchGeminiContent) {
                        Image(systemName: "arrow.right")
                            .padding()
                    }
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

                    Text(self.responseStatusCode, format: .number)

                    Text(self.responseContentType)

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
            .padding(.horizontal)
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

    func displayGeminiContent(_ host: String) -> (Error?, String, Int, String) -> Void {
        return  { error, data, statusCode, contentType in
            self.responseStatusCode = statusCode;
            self.responseContentType = contentType;
            
            switch statusCode {
                case 10...19:
                    self.responseText = "Implement Inputs"
                case 20...29:
                    self.responseText = data
                case 30...39:
                    self.responseText = "implement redirect:" + data
                case 40...49:
                    self.responseText = "Temporary failure " + data
                case 50...59:
                    self.responseText = "Permanent failure " + data
                case 60...69:
                    self.responseText = "Client certificate required. " + data
                default:
                    self.responseText = "Unknown status code \(statusCode)"
            }
            
        }
    }
//            
//            if error != nil {
//                DispatchQueue.main.async {
//                    self.responseText = error?.localizedDescription ?? "Unknown error";
//                    self.responseStatusCode = statusCode;
//                    self.responseContentType = contentType;
//                }
//            } else {
//                DispatchQueue.main.async {
//                    self.responseText = data;
//                    self.responseStatusCode = statusCode;
//                    self.responseContentType = contentType;
//                }
//            }
//        }
//    }

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
