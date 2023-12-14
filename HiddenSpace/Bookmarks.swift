//
//  Bookmarks.swift
//  HiddenSpace
//
//  Created by Nick Yakovliev on 12/13/23.
//

import Foundation
import SwiftUI


struct BookmarkListView: View {
    @Binding var bookmarks: [String]
    let browser: HiddenSpaceView

    var body: some View {
        NavigationView {
            List {
                ForEach(self.browser.settings.bookmarks, id: \.self) { bookmark in
                    Button(bookmark) {
                        self.browser.loadPage(url: bookmark)
                        self.browser.showingBookmarkList = false
                    }
                }
                .onDelete(perform: removeBookmarks)
                .onMove(perform: moveBookmarks) // Add this line
            }
            .navigationBarTitle("Bookmarks", displayMode: .inline)
            .navigationBarItems(trailing: EditButton()) // Add an Edit button
        }
    }

    private func removeBookmarks(at offsets: IndexSet) {
        self.browser.settings.removeBookmark(at: offsets)
    }

    private func moveBookmarks(from source: IndexSet, to destination: Int) {
        self.browser.settings.moveBookmark(from: source, to: destination)
    }
}

