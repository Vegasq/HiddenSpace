//
//  UserInputView.swift
//  HiddenSpace
//
//  Created by Nick Yakovliev on 12/13/23.
//

import Foundation;
import SwiftUI;


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
