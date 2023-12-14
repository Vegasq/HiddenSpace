//
//  HistoryView.swift
//  HiddenSpace
//
//  Created by Nick Yakovliev on 12/14/23.
//

import Foundation
import SwiftUI


class History: ObservableObject {
    var history: [String] = [];
    
    func add(url: String) {
        self.history.append(url);
    }
}


struct HistoryView: View {
    let browser: HiddenSpaceView

    var body: some View {
        NavigationView {
            List {
                ForEach(self.browser.history.history, id: \.self) { bookmark in
                    Button(bookmark) {
                        self.browser.loadPage(url: bookmark)
                        self.browser.showingBookmarkList = false
                    }
                }
            }
            .navigationBarTitle("History", displayMode: .inline)
        }
    }
}

