import SwiftUI
import Network


struct HiddenSpaceView: View {
    @State var geminiURL = "gemini://geminiprotocol.net/"
    @State private var responseText = ""
    @State private var responseContentType = ""
    @State private var responseStatusCode = 0
    
    @State private var history: [String] = []
    @State private var historyIndex = 0
    @State private var scrollToTop = false

    @State var showingBookmarkList = false
        
    @ObservedObject var bookmarks = Bookmarks();

    @State var showingUserInput = false
    @State var userInputTitle = "";
    @State var userInputUrl = "";

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

        return ScrollViewReader { proxy in
            VStack {
                ScrollView {
                    GeminiTextParser(text: self.responseText, parentUrl: self.geminiURL) { clickedUrl in
                        if let url = clickedUrl {
                            self.loadPage(url: url);
                        }
                    }
                    .padding(.horizontal)
                }
                .id("top")
                .refreshable {
                    self.fetchGeminiContent();
                }            
                .onChange(of: scrollToTop) { _ in
                    withAnimation {
                        proxy.scrollTo(0)
                    }
                }


            VStack {
                HStack {
                    TextField("Enter Gemini URL", text: $geminiURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            self.fetchGeminiContent();
                        }
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

                    Button(action: fetchGeminiContent) {
                        Image(systemName: "arrow.clockwise")
                            .padding()
                    }

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
            BookmarkListView(bookmarks: $bookmarks.bookmarks, browser: self)
        }
        .sheet(isPresented: $showingUserInput){
            UserInputView(browser: self);
        }
        .gesture(dragToRight)
        .gesture(dragToLeft)
        .navigationViewStyle(StackNavigationViewStyle())
        .onAppear(perform: {
            self.loadPage(url: self.geminiURL)
        })
    }
    }

    func saveBookmark() {
        self.bookmarks.saveBookmark(url: self.geminiURL);
    }

    func listBookmarks() {
        showingBookmarkList = true
    }

    func fetchGeminiContent() {
        if history.contains(geminiURL) == false {
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
                    self.showingUserInput = true;
                    self.userInputTitle = contentType;
                    self.userInputUrl = host;
                    print("self.userInputUrl", self.userInputUrl);
                case 20...29:
                    self.responseText = data
                case 30...39:
                    self.responseText = "Redirecting to " + contentType
                    self.geminiURL = contentType;
                    self.fetchGeminiContent();
                case 40...49:
                    self.responseText = "Temporary failure " + data
                case 50...59:
                    self.responseText = "Permanent failure " + data
                case 60...69:
                    self.responseText = "Client certificate required. " + data
                default:
                    self.responseText = "Unknown status code \(statusCode)"
            }
            self.scrollToTop.toggle();
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
}


struct UserInputView: View {
    let browser: HiddenSpaceView;
    @State var userInput = "";

    func encodeURI(string: String) -> String {
        // Define a character set as per RFC 3986
        var allowedCharacterSet = CharacterSet.alphanumerics
        allowedCharacterSet.insert(charactersIn: "-._~")

        // Perform encoding
        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? "Invalid input"
    }

    var body: some View {
        VStack{
            Text(self.browser.userInputTitle).font(.title)
            TextField("User Input:", text: self.$userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .onSubmit {
                    print(self.userInput);
                    self.browser.showingUserInput = false;
                    self.browser.geminiURL = self.browser.userInputUrl + "?" + self.encodeURI(string: self.userInput);
                    self.browser.fetchGeminiContent()
                }
                .frame(height: 100)
            Spacer()
        }
    }
}
