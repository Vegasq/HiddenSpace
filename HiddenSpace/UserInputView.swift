//
//  UserInputView.swift
//  HiddenSpace
//
//  Created by Nick Yakovliev on 12/13/23.
//

import Foundation
import SwiftUI


struct UserInputView: View {
    let browser: HiddenSpaceView
    @State var userInput = ""
    @FocusState private var isInputActive: Bool

    func encodeURI(string: String) -> String {
        var allowedCharacterSet = CharacterSet.alphanumerics
        allowedCharacterSet.insert(charactersIn: "-._~")

        return string.addingPercentEncoding(withAllowedCharacters: allowedCharacterSet) ?? "Invalid input"
    }

    var body: some View {
        VStack {
            Text(titleText)
                .font(.title)
                .padding(.bottom, 8)

            TextField("", text: self.$userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .focused($isInputActive)
                .onSubmit {
                    self.browser.showingUserInput = false
                    self.browser.geminiURL = self.browser.userInputUrl + "?" + self.encodeURI(string: self.userInput)
                    self.browser.fetchGeminiContent()
                }
            Spacer()

        }
        .padding()
        .background(Color.white)
        .cornerRadius(12)
        .shadow(radius: 10)
        .onAppear {
            self.isInputActive = true
        }
    }

    private var titleText: String {
        self.browser.userInputTitle.isEmpty ? "User Input expected" : self.browser.userInputTitle
    }
}
