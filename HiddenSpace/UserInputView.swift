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

            // Replace TextField with TextEditor for multiline input
            TextEditor(text: self.$userInput)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .padding()
                .frame(minHeight: 100)  // Set a minimum height
                .focused($isInputActive)

            // Add a Submit Button
            Button(action: {
                self.browser.showingUserInput = false
                self.browser.geminiURL = self.browser.userInputUrl + "?" + self.encodeURI(string: self.userInput);
                self.browser.fetchGeminiContent();
            }) {
                Text("Submit")
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding()

            Spacer()
        }
        .padding()
        .cornerRadius(12)
        .onAppear {
            self.isInputActive = true
        }
    }

    private var titleText: String {
        self.browser.userInputTitle.isEmpty ? "User Input expected" : self.browser.userInputTitle
    }
}
