import SwiftUI
import Network


enum LineType {
    case header(String)
    case link(String)
    case text(String)
    case codeBlock(String)
}

struct TextBlock {
    let type: LineType
}

struct GeminiTextParser: View {
    let text: String
    let parentUrl: String
    
    var urlClickedCallback: ((String?) -> Void)? = nil

    var textBlocks: [TextBlock] {
        var blocks: [TextBlock] = []
        var currentCodeBlock: String = ""
        var isCodeBlock: Bool = false

        text.replacingOccurrences(of: "\r", with: "\n")
            .split(separator: "\n", omittingEmptySubsequences: false)
            .forEach { line in
                if line.starts(with: "```") {
                    if isCodeBlock {
                        // End of code block
                        blocks.append(TextBlock(type: .codeBlock(currentCodeBlock)))
                        currentCodeBlock = ""
                        isCodeBlock = false
                    } else {
                        // Start of code block
                        isCodeBlock = true
                    }
                } else if isCodeBlock {
                    currentCodeBlock += (currentCodeBlock.isEmpty ? "" : "\n") + line
                } else {
                    if line.starts(with: "#") {
                        blocks.append(TextBlock(type: .header(String(line))))
                    } else if line.starts(with: "=>") {
                        blocks.append(TextBlock(type: .link(String(line))))
                    } else {
                        blocks.append(TextBlock(type: .text(String(line))))
                    }
                }
            }

        // Add any remaining code block
        if isCodeBlock {
            blocks.append(TextBlock(type: .codeBlock(currentCodeBlock)))
        }

        return blocks
    }

    var body: some View {
        VStack(alignment: .leading) {
            ForEach(Array(textBlocks.enumerated()), id: \.0) { index, block in
                Group {
                    switch block.type {
                    case .header(let line):
                        renderHeader(line: line).padding(.bottom, 12)
                    case .link(let line):
                        renderLink(line: line).padding(.bottom, 12)
                    case .text(let line):
                        renderText(line: line).padding(.bottom, 12)
                    case .codeBlock(let code):
                        renderCodeBlock(code: code).padding(.bottom, 12)
                    }
                }
            }
        }
    }

    func addPrefixIfNeeded(url: String) -> String {
        // Check if the URL is already a full URL with a scheme
        if url.hasPrefix("gemini://") || url.hasPrefix("http://") || url.hasPrefix("https://") {
            return url
        } else {
            // Extract the root URL from the parent URL
            var rootURL = self.parentUrl
            if let schemeEndIndex = rootURL.range(of: "://")?.upperBound {
                if let firstSlashIndex = rootURL[schemeEndIndex...].firstIndex(of: "/") {
                    rootURL = String(rootURL[..<firstSlashIndex])
                }
            }

            // Determine if the URL is root-relative or directory-relative
            if url.hasPrefix("/") {
                // Append the relative URL to the root URL
                return "\(rootURL)\(url)"
            } else {
                // Get the directory part of the parent URL
                var directoryURL = self.parentUrl
                if let lastSlashIndex = directoryURL.lastIndex(of: "/") {
                    directoryURL = String(directoryURL[..<lastSlashIndex])
                }

                // Append the relative URL to the directory URL
                return "\(directoryURL)/\(url)"
            }
        }
    }

    func callback(url: String){
        if url.hasPrefix("http://") || url.hasPrefix("https://") {
            UIApplication.shared.open(URL(string: url)!);
        } else {
            self.urlClickedCallback!(url);
        }
    }
    
    func parseGeminiLink(_ link: String) -> (url: String, description: String) {
        let pattern = "^=>\\s*(\\S+)(?:\\s+(.*))?$"
        
        do {
            let regex = try NSRegularExpression(pattern: pattern)
            let nsrange = NSRange(link.startIndex..<link.endIndex, in: link)
            
            if let match = regex.firstMatch(in: link, range: nsrange) {
                let urlRange = match.range(at: 1)
                let descriptionRange = match.range(at: 2)
                
                if let urlSubstring = Range(urlRange, in: link) {
                    let url = String(link[urlSubstring])
                    let description: String? = {
                        if let descriptionSubstring = Range(descriptionRange, in: link) {
                            return String(link[descriptionSubstring])
                        }
                        return nil
                    }()
                    return (url, description ?? url)
                }
            }
        } catch {
            print("Invalid regular expression: \(error.localizedDescription)")
        }
        
        return (link, link)
    }
    
    @ViewBuilder
    func renderText(line: String) -> some View {
        Text(line.trimmingCharacters(in: .whitespacesAndNewlines))
    }
    
    @ViewBuilder
    func renderHeader(line: String) -> some View {
        if line.starts(with: "###") {
            Text(line.dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines)).font(.title3)
        } else if line.starts(with: "##") {
            Text(line.dropFirst(2).trimmingCharacters(in: .whitespacesAndNewlines)).font(.title2)
        } else if line.starts(with: "#") {
            Text(line.dropFirst(1).trimmingCharacters(in: .whitespacesAndNewlines)).font(.title)
        }
    }
    
    @ViewBuilder
    func renderLink(line: String) -> some View {
        let (url, description) = parseGeminiLink(line)
        let fullUrl = self.addPrefixIfNeeded(url: url)
        
        Button(action: {
            self.callback(url: fullUrl);
        }) {
            HStack {
                Text(description.trimmingCharacters(in: .whitespacesAndNewlines))
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .multilineTextAlignment(.leading)
            }
            
        }
    }

    @ViewBuilder
    func renderCodeBlock(code: String) -> some View {
        Text(code)
            .font(.system(.body, design: .monospaced))
            .padding()
            .background(Color.gray.opacity(0.1))
            .cornerRadius(8)
    }

}
