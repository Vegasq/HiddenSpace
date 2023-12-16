import SwiftUI
import Network
#if canImport(UIKit)
import UIKit // Import for iOS
typealias PlatformImage = UIImage
#elseif canImport(AppKit)
import AppKit // Import for macOS
typealias PlatformImage = NSImage
#endif


struct ImageRenderer: View {
    var uiimage: Data;
    @State private var image: PlatformImage? = nil;

    @State private var scale: CGFloat = 1.0


    var body: some View {
        VStack(alignment: .leading) {
            Image(uiImage: PlatformImage(data: uiimage) ?? PlatformImage())
                .resizable()
                .aspectRatio(contentMode: .fit)

        }
        .gesture(
            MagnificationGesture()
                .onChanged { value in
                    self.scale = value
                }
        )

    }
}
