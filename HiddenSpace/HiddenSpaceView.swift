import SwiftUI
import Network




struct HiddenSpaceView: View {
    @ObservedObject var settings: Settings = Settings();

    @ObservedObject var history: History = History();
    @State var showingHistory = false;

    @State var geminiURL = "";
//    @State private var responseText = ""
    @State private var responseContent = Data();
    @State private var responseContentType = ""
    @State private var responseStatusCode = 0
    
    @State private var navigationHistory: [String] = []
    @State private var navigationHistoryIndex = 0
    @State private var scrollToTop = false

    @State var showingBookmarkList = false

    @State var showingUserInput = false;
    @State var userInputTitle = "";
    @State var userInputUrl = "";

    @State private var isLoading = false;
    
    @State private var loadingUrl = "";

    @State private var showingSettings = false;
    @State private var selectedHomepage: String?
    
    @State private var renderer: String = "text/gemini";

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
                    if renderer == "text/gemini" {
                        GeminiTextParser(data: self.responseContent, parentUrl: self.geminiURL) { clickedUrl in
                            if let url = clickedUrl {
                                self.loadPage(url: url);
                            }
                        }
                        .padding(.horizontal)
                    } else if renderer == "image/jpeg" || renderer == "image/png" {
                        ImageRenderer(uiimage: self.responseContent)
                    } else if renderer == "text/plain" {
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
                    TextField("Enter Gemini URL", text: $geminiURL)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .onSubmit {
                            self.fetchGeminiContent();
                        }
                        .shadow(radius: 2)
                        .padding(.top)
                    
                    HStack {
                        Button(action: goBack) {
                            Image(systemName: "arrow.left")
                                .padding(.horizontal)
                        }.disabled(navigationHistoryIndex <= 0)
                        
                        
                        Button(action: fetchGeminiContent) {
                            Image(systemName: "arrow.clockwise")
                                .padding(.horizontal)
                        }
                        
                        if isLoading {
                            ProgressView();
                        }
                        
                        
                        Spacer()
                        
                        if self.settings.bookmarks.contains(self.geminiURL) == false {
                            Button(action: {self.settings.saveBookmark(url: self.geminiURL)}) {
                                Image(systemName: "bookmark")
                                    .padding(.horizontal)
                            }
                        }
                        
                        Button(action: {self.showingBookmarkList = true}) {
                            Image(systemName: "list.bullet")
                                .padding(.horizontal)
                        }
                        Button(action: {self.showingHistory = true}) {
                            Image(systemName: "clock")
                                .padding(.horizontal)
                        }
                        
                        Button(action: {self.showingSettings = true}) {
                            Image(systemName: "gear")
                                .padding(.horizontal)
                        }
                        
                    }
                    .padding()
                    .buttonStyle(BorderlessButtonStyle())
                    
                }
                .padding(.horizontal)
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
                    self.loadPage(url: self.geminiURL)
                }
            })
            .gesture(dragToRight)
            .gesture(dragToLeft)
            .navigationViewStyle(StackNavigationViewStyle())
            .onAppear(perform: {
                self.geminiURL = self.settings.homepage;
                self.loadPage(url: self.geminiURL)
            })
        }
    }

    func fetchGeminiContent() {
        self.isLoading = true;

        let url = URL(string: self.geminiURL);
        if url == nil {
            return
        }
        
        let cl = Client(host: url?.host() ?? "", port: UInt16(url?.port ?? 1965), validateCert: false);
        self.loadingUrl = self.geminiURL;

        cl.setupSecConnection();
        cl.start();
        cl.dataReceivedCallback = self.displayGeminiContent(self.geminiURL);
        cl.send(data: (self.geminiURL + "\r\n").data(using: .utf8)!);
    }

    func displayGeminiContent(_ host: String) -> (Error?, Data?, Int, String) -> Void {
        return  { error, data, statusCode, contentType in
            
            // Avoid delayed queries to overwrite latest ones
            if host != self.loadingUrl {
                print("Race condition in loading pages", host, "!=", self.loadingUrl);
                return
            }
            
            self.history.add(url: host);
            
            if navigationHistory.contains(self.geminiURL) == false {
                navigationHistory.append(self.geminiURL);
                navigationHistoryIndex = navigationHistory.count - 1;
            }

            self.isLoading = false;
            self.responseContent = data ?? Data();

            self.responseStatusCode = statusCode;
            self.responseContentType = contentType;

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
                    print()
                case 30...39:
                    let error = "Redirecting to \(contentType)." + (String(data: data ?? Data(), encoding: .utf8) ?? "");
                    self.responseContent = error.data(using: .utf8)!;
                    self.geminiURL = contentType;
                    self.fetchGeminiContent();
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
            self.geminiURL = navigationHistory[navigationHistoryIndex];
            self.navigationHistory.removeLast();
            self.fetchGeminiContent();
        }
    }

    func goForward() {
        if navigationHistoryIndex < navigationHistory.count - 1 {
            navigationHistoryIndex += 1
            geminiURL = navigationHistory[navigationHistoryIndex]
            fetchGeminiContent()
        }
    }
    
    func loadPage(url: String){
        self.geminiURL = url;
        self.fetchGeminiContent();
    }
}

