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

    func clear() {
        history.removeAll()
    }

}


struct HistoryView: View {
    let browser: HiddenSpaceView

    var body: some View {
        NavigationView {
            List {
                ForEach(self.browser.history.history.reversed(), id: \.self) { bookmark in
                    Button(bookmark) {
                        self.browser.loadPage(url: bookmark)
                        self.browser.showingHistory = false
                    }
                }
            }
            .navigationBarTitle("History", displayMode: .inline)
            .navigationBarItems(trailing: Button("Clear") {
                self.browser.history.clear()
                self.browser.showingHistory = false;
            })
        }
    }
}
