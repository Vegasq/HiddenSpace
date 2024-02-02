//
//  SettingsView.swift
//  HiddenSpace
//
//  Created by Nick Yakovliev on 12/14/23.
//

import Foundation
import SwiftUI


struct SettingsView: View {
    @ObservedObject var settings: Settings;

    var body: some View {

        NavigationView {
            Form {
                Picker("Homepage", selection: $settings.homepage) {
                    ForEach(self.settings.bookmarks, id: \.self) {
                        Text($0)
                    }
                }
                .pickerStyle(.navigationLink)

                Section(header: Text(String(localized: "Help"))) {

                    Link("Privacy Policy",
                         destination: URL(string: "https://github.com/Vegasq/HiddenSpace/blob/main/README.md")!)

                    Button(action: {
                        withAnimation {
                            let email = "mail@mkla.dev"
                            let subject = "HiddenSpace"
                            let body = ""
                            let urlString = "mailto:\(email)?subject=\(subject)&body=\(body)".addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)
                            
                            if let url = URL(string: urlString ?? "") {
                                UIApplication.shared.open(url)
                            }
                        }

                    }) {
                        Text("Help and Feedback")
                    }
                    
                    Link("Contribute",
                         destination: URL(string: "https://github.com/Vegasq/HiddenSpace/")!)
                }

                Section(header: Text("Acknowledgements")) {
                    HStack {

                        Text("Gemini client for macOS")
                        Spacer()
                        Link("Jimmy",
                             destination: URL(
                                string: "https://github.com/jfoucher/Jimmy")!)
                    }
                }

            }
            .navigationBarTitle("Settings")
        }
    }
}

    

class Settings: ObservableObject {
    
    @Published var homepage: String {
        didSet {
            NSUbiquitousKeyValueStore.default.set(homepage, forKey: "homepage")
        }
    }
    
    @Published var bookmarks: [String] {
        didSet {
            NSUbiquitousKeyValueStore.default.set(bookmarks, forKey: "bookmarks")
        }
    }
    
    init() {
        NSUbiquitousKeyValueStore.default.synchronize()
        self.homepage = NSUbiquitousKeyValueStore.default.object(forKey: "homepage") as? String ?? "gemini://geminispace.info/";
        self.bookmarks = NSUbiquitousKeyValueStore.default.object(forKey: "bookmarks") as? [String] ?? [
            "gemini://geminispace.info/",
            "gemini://geminiprotocol.net/",
            "gemini://gemini.circumlunar.space/capcom/",
            "gemini://mozz.us/",
            "gemini://cdg.thegonz.net/",
            "gemini://warmedal.se/~antenna/",
        ];
    }
    
    func saveBookmark(url: String) {
        if !self.bookmarks.contains(url) {
            self.bookmarks.append(url)
        }
    }
    
    func removeBookmark(at indices: IndexSet) {
        bookmarks.remove(atOffsets: indices)
    }

    func moveBookmark(from source: IndexSet, to destination: Int) {
        bookmarks.move(fromOffsets: source, toOffset: destination)
    }
    
}
