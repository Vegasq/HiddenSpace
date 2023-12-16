import SwiftUI
import Network


struct HiddenSpaceView: View {
    @ObservedObject var settings: Settings = Settings();

    @State var URL = "";

    // Loaded page content
    @State private var responseContent = Data();
    @State private var responseContentType = ""
    @State private var responseStatusCode = 0

    // Latest visited pods
    @ObservedObject var history: History = History();
    @State var showingHistory = false;

    // Data to have workinf back and forward buttons
    @State private var navigationHistory: [String] = []
    @State private var navigationHistoryIndex = 0
    @State private var scrollToTop = false

    // Bookmarks live in settings, this is just a toggle
    @State var showingBookmarkList = false

    // Settings view
    @State private var showingSettings = false;

    // User Input logic
    @State var showingUserInput = false;
    @State var userInputTitle = "";
    @State var userInputUrl = "";
    
    @State private var isLoading = false;
    @State private var loadingUrl = "";

    @State private var selectedHomepage: String?
    
    var faviconCache: FaviconCache = FaviconCache();

    
    var body: some View {

// Something feels off about this part. In use feels unreliable. Need to think more.
//        let dragToRight = DragGesture()
//            .onEnded {
//                if $0.translation.width > 100 {
//                    goBack()
//                }
//            }
//        
//        let dragToLeft = DragGesture()
//            .onEnded {
//                if $0.translation.width < -100 {
//                    goForward()
//                }
//            }
        
        return ScrollViewReader { proxy in
            VStack {
                ScrollView {
                    if self.responseContentType == "text/gemini" {
                        GeminiTextParser(data: self.responseContent, parentUrl: self.URL) { clickedUrl in
                            if let url = clickedUrl {
                                self.loadPage(url: url);
                            }
                        }
                        .padding(.horizontal)
                    } else if self.responseContentType == "image/jpeg" || self.responseContentType == "image/png" {
                        ImageRenderer(uiimage: self.responseContent)
                            .onAppear(){
                                print("Display image")
                            }
                    } else if self.responseContentType == "text/plain" {
                        PlainTextParser(data: self.responseContent)
                            .padding(.horizontal)
                    } else {
                        Text("Content type not supported");
                    }
                    
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
                
                VStack{
                    HStack {
                        TextField("Enter Gemini URL", text: $URL)
                            .textFieldStyle(RoundedBorderTextFieldStyle())
                            .onSubmit {
                                self.fetchGeminiContent();
                            }
                            .shadow(radius: 2)
                            .frame(height: 40)

                            if isLoading {
                                ProgressView()
                                    .padding(.leading)
                                    .frame(width: 40, height: 40)
                            } else if self.settings.bookmarks.contains(self.URL) == false {
                                Button(action: {self.settings.saveBookmark(url: self.URL)}) {
                                    Image(systemName: "bookmark")
                                }
                                .padding(.leading)
                                .frame(width: 40, height: 40)
                            }

                    }

                    HStack {
                        Button(action: goBack) {
                            Image(systemName: "arrow.left")
                                .padding(.horizontal)
                        }.disabled(navigationHistoryIndex <= 0)
                        
                        Button(action: goForward) {
                            Image(systemName: "arrow.right")
                                .padding(.horizontal)
                        }.disabled(navigationHistoryIndex >= navigationHistory.count - 1)
                        
                        Button(action: {self.showingHistory = true}) {
                            Image(systemName: "clock")
                                .padding()
                        }
                    
                        
                        Spacer()
                        
                        
                        Button(action: {self.showingBookmarkList = true}) {
                            Image(systemName: "list.bullet")
                                .padding()
                        }
                        
                        Button(action: {self.showingSettings = true}) {
                            Image(systemName: "gear")
                                .padding()
                        }
                        
                    }
//                    .padding(.vertical)
                    .buttonStyle(BorderlessButtonStyle())
                    
                }
                .padding()
                .background(Color.gray.opacity(0.1))
                
            }
            .sheet(isPresented: $showingBookmarkList) {
                BookmarkListView(bookmarks: $settings.bookmarks, browser: self)
            }
            .sheet(isPresented: $showingHistory) {
                HistoryView(browser: self)
            }
            .sheet(isPresented: $showingUserInput){
                UserInputView(browser: self);
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(settings: self.settings)
            }
            .onAppear(perform: {
                if let homepage = selectedHomepage {
                    self.loadPage(url: homepage)
                } else {
                    self.loadPage(url: self.URL)
                }
            })
//            .gesture(dragToRight)
//            .gesture(dragToLeft)
            .navigationViewStyle(StackNavigationViewStyle())
            .onAppear(perform: {
                self.URL = self.settings.homepage;
                self.loadPage(url: self.URL)
            })
        }
    }

    func fetchGeminiContent(addToHistory: Bool = true) {
        self.faviconCache.fetch(url: self.URL);
        
        self.isLoading = true;

        let url = Foundation.URL(string: self.URL);
        if url == nil {
            return
        }

        if addToHistory {
            if navigationHistory.contains(self.URL) == false {
                navigationHistory.append(self.URL);
                navigationHistoryIndex = navigationHistory.count - 1;
            }
        }

        let cl = Client(host: url?.host() ?? "", port: UInt16(url?.port ?? 1965), validateCert: false);
        self.loadingUrl = self.URL;

        cl.setupSecConnection();
        cl.start();
        cl.dataReceivedCallback = self.displayGeminiContent(self.URL);
        cl.send(data: (self.URL + "\r\n").data(using: .utf8)!);
    }

    func displayGeminiContent(_ host: String) -> (Error?, Data?, Int, String) -> Void {
        return  { error, data, statusCode, contentType in
            
            // Avoid delayed queries to overwrite latest ones
            if host != self.loadingUrl {
                print("Race condition in loading pages", host, "!=", self.loadingUrl);
                return
            }
            
            self.history.add(url: host);

            self.isLoading = false;
            self.responseContent = data ?? Data();

            self.responseStatusCode = statusCode;
            
            // Ignoring ; lang=en
            if contentType.split(separator: ";", maxSplits: 1).count == 2 {
                self.responseContentType = String(contentType.split(separator: ";")[0]);
            } else {
                self.responseContentType = contentType;
            }

            switch statusCode {
                case 10...19:
                    print("input");
                    print(statusCode);
                    print(self.responseContentType);
                    self.goBack();

                    self.showingUserInput = true;
                    self.userInputTitle = contentType;
                    self.userInputUrl = host;
                case 20...29:
                    print(self.responseContentType);
                case 30...39:
                    let error = "Redirecting to \(contentType)." + (String(data: data ?? Data(), encoding: .utf8) ?? "");
                    self.responseContent = error.data(using: .utf8)!;
                    self.URL = contentType;
                    self.fetchGeminiContent(addToHistory: false);
                case 40...49:
                    let error = "Temporary failure " + (String(data: data ?? Data(), encoding: .utf8) ?? "");
                    self.responseContent = error.data(using: .utf8)!;
                case 50...59:
                    let error = "Permanent failure " + (String(data: data ?? Data(), encoding: .utf8) ?? "");
                    self.responseContent = error.data(using: .utf8)!;
                case 60...69:
                    let error = "Not supported. Client certificate required." + (String(data: data ?? Data(), encoding: .utf8) ?? "");
                    self.responseContent = error.data(using: .utf8)!;
                default:
                    let error = "Unknown status code \(statusCode)." + (String(data: data ?? Data(), encoding: .utf8) ?? "");
                    self.responseContent = error.data(using: .utf8)!;
            }
            self.scrollToTop.toggle();
        }
    }

    func goBack() {
        if navigationHistoryIndex > 0 {
            self.navigationHistoryIndex -= 1;
            self.URL = navigationHistory[navigationHistoryIndex];
            self.fetchGeminiContent(addToHistory: false);
        }
    }

    func goForward() {
        if self.navigationHistoryIndex < self.navigationHistory.count - 1 {
            self.navigationHistoryIndex += 1
            self.URL = navigationHistory[navigationHistoryIndex];
            self.fetchGeminiContent(addToHistory: false);
        }
    }
    
    func loadPage(url: String){
        self.URL = url;
        self.fetchGeminiContent();
    }
}


struct HiddenSpaceView_Previews: PreviewProvider {
    static var previews: some View {
        HiddenSpaceView()
            .previewDevice("iPhone 12")
    }
}
