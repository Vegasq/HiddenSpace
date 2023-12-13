//
//  Bookmarks.swift
//  HiddenSpace
//
//  Created by Nick Yakovliev on 12/13/23.
//

import Foundation
import SwiftUI


class Bookmarks: ObservableObject {
    @Published var bookmarks: [String];
    @Published var bookmarksKey: String;

    init(){
        self.bookmarksKey = "bookmarksKey";
        self.bookmarks = [];
        
        if let loadedBookmarks = UserDefaults.standard.object(forKey: self.bookmarksKey) as? [String] {
            self.bookmarks = loadedBookmarks;
        }
    }

    func saveBookmark(url: String) {
        if !self.bookmarks.contains(url) {
            self.bookmarks.append(url)
            UserDefaults.standard.set(self.bookmarks, forKey: self.bookmarksKey)
        }
    }
    
    func removeBookmark(at indices: IndexSet) {
        bookmarks.remove(atOffsets: indices)
        UserDefaults.standard.set(bookmarks, forKey: bookmarksKey)
    }
}


struct BookmarkListView: View {
    @Binding var bookmarks: [String]
    let browser: HiddenSpaceView

    var body: some View {
        NavigationView {
            List {
                ForEach(self.browser.bookmarks.bookmarks, id: \.self) { bookmark in
                    Button(bookmark) {
                        self.browser.loadPage(url: bookmark)
                        self.browser.showingBookmarkList = false
                    }
                }
                .onDelete(perform: removeBookmarks)
            }
            .navigationBarTitle("Bookmarks", displayMode: .inline)
        }
    }

    private func removeBookmarks(at offsets: IndexSet) {
        self.browser.bookmarks.removeBookmark(at: offsets)
    }

}
