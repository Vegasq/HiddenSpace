import SwiftUI
import Network


enum LineType {
    case header(String)
    case link(String)
    case text(String)
    case codeBlock(String)
    case quote(String)
    case list(String)
}

struct TextBlock {
    let type: LineType
}

struct GeminiTextParser: View {
    let data: Data;
    var text: String {
        String(data: data, encoding: .utf8) ?? ""
    }

    let parentUrl: String
    var urlClickedCallback: ((String?) -> Void)? = nil
    @State private var scale: CGFloat = 1.0

    var textBlocks: [TextBlock] {
        var blocks: [TextBlock] = []
        var currentCodeBlock: String = ""
        var isCodeBlock: Bool = false

        text.replacingOccurrences(of: "\r\n", with: "\n")
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
                    } else if line.starts(with: ">") {
                        blocks.append(TextBlock(type: .quote(String(line))))
                    } else if line.starts(with: "*") {
                        blocks.append(TextBlock(type: .list(String(line))))
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
                    case .quote(let line):
                        renderQuote(line: line).padding(.bottom, 12)
                    case .list(let line):
                        renderList(line: line).padding(.bottom, 12)
                    }
                }
            }
        }
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    self.scale = value
                }
        )

    }

    func addPrefixIfNeeded(url: String) -> String {
        if url.contains("://") || url.starts(with: "mailto:") {
            return url
        } else {
            var rootURL = self.parentUrl
            if let schemeEndIndex = rootURL.range(of: "://")?.upperBound {
                if let firstSlashIndex = rootURL[schemeEndIndex...].firstIndex(of: "/") {
                    rootURL = String(rootURL[..<firstSlashIndex])
                }
            }

            if url.hasPrefix("/") {
                return "\(rootURL)\(url)"
            } else {
                var directoryURL = self.parentUrl
                if let lastSlashIndex = directoryURL.lastIndex(of: "/") {
                    directoryURL = String(directoryURL[..<lastSlashIndex])
                }

                return "\(directoryURL)/\(url)"
            }
        }
    }

    func callback(url: String){
        if url.hasPrefix("gemini://") {
            self.urlClickedCallback!(url);
        } else {
            UIApplication.shared.open(URL(string: url)!);
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
            .textSelection(.enabled)
            .font(.system(size: 14 * scale))

    }

    @ViewBuilder
    func renderList(line: String) -> some View {
        let subList = line.replacingOccurrences(of: "*", with: "•")
        Text(subList.trimmingCharacters(in: .whitespacesAndNewlines))
            .textSelection(.enabled)
            .font(.system(size: 14 * scale))

    }

    @ViewBuilder
    func renderQuote(line: String) -> some View {
        Text(line.trimmingCharacters(in: .whitespacesAndNewlines)).italic()
            .textSelection(.enabled)
            .font(.system(size: 14 * scale))

    }
    
    @ViewBuilder
    func renderHeader(line: String) -> some View {
        if line.starts(with: "###") {
            Text(line.dropFirst(3).trimmingCharacters(in: .whitespacesAndNewlines))
                .textSelection(.enabled)
                .font(.system(size: 16 * scale))

        } else if line.starts(with: "##") {
            Text(line.dropFirst(2).trimmingCharacters(in: .whitespacesAndNewlines))
                .textSelection(.enabled)
                .font(.system(size: 18 * scale))

        } else if line.starts(with: "#") {
            Text(line.dropFirst(1).trimmingCharacters(in: .whitespacesAndNewlines))
                .textSelection(.enabled)
                .font(.system(size: 20 * scale))

        }
    }
    
    @ViewBuilder
    func renderLink(line: String) -> some View {
        let (url, description) = parseGeminiLink(line)
        let fullUrl = self.addPrefixIfNeeded(url: url)
        
        Text(description.trimmingCharacters(in: .whitespacesAndNewlines))
            .frame(maxWidth: .infinity, alignment: .leading)
            .multilineTextAlignment(.leading)
            .textSelection(.enabled)
            .font(.system(size: 14 * scale))
            .foregroundColor(Color.blue)
            .onTapGesture(count: 1, perform: {
                self.callback(url: fullUrl);
            })
    }

    @ViewBuilder
    func renderCodeBlock(code: String) -> some View {
        ScrollView(.horizontal, showsIndicators: true) {
            Text(code)
                .lineLimit(nil) // Allow unlimited lines
                .fixedSize(horizontal: true, vertical: false) // Fit content horizontally
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(8)
                .textSelection(.enabled)
                .font(.system(size: 14 * scale, design: .monospaced))
        }
    }
}
