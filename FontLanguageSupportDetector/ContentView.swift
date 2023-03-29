import SwiftUI

struct ContentView: View {
    @State private var isTargeted = false
    @StateObject private var fontManager = FontManager()
    @State private var error: Error?
    
    var body: some View {
        Group {
            if let font = fontManager.font {
                VStack {
                    HStack {
                        Text(font.displayName ?? font.fontName)
                            .font(Font(font.withSize(24)))
                        
                        if let familyName = font.familyName {
                            Text(familyName)
                                .font(Font(font))
                            
                            Spacer(minLength: 0)
                        }
                    }
                    .frame(height: 60)
                    .onDrag {
                        let provider = fontManager.url.flatMap {
                            NSItemProvider(contentsOf: $0, contentType: .font)
                        } ?? NSItemProvider()
                        
                        return provider
                    }
                    .padding(.bottom)
                    
                    if let supportedLanguages = fontManager.supportedLanguages {
                        HStack {
                            Text("Supported Languages (\(supportedLanguages.count)):")
                                .font(.headline)
                            
                            Spacer()
                        }
                        
                        ScrollView {
                            Text(supportedLanguages.joined(separator: ", "))
                                .textSelection(.enabled)
                        }
                    } else {
                        Text("No supported languages found")
                    }
                    
                    Button(action: openFile) {
                        Text("Select another file")
                    }
                    
                    systemFontButton
                }
            } else {
                VStack {
                    Image(systemName: "arrow.up.doc.fill")
                        .font(.system(size: 50))
                    
                    Text("Drag and drop a file or click anywhere")
                        .multilineTextAlignment(.center)
                    
                    systemFontButton
                }
                .onTapGesture(perform: openFile)
            }
        }
        .foregroundColor(isTargeted ? .accentColor : .primary)
        .padding()
        .onDrop(of: [.font], isTargeted: $isTargeted) { providers in
            _ = providers.first?.loadFileRepresentation(for: .font, completionHandler: { url, _, error in
                Task { @MainActor in
                    guard let url else { return }
                    
                    do {
                        if let error = error { throw error }
                        try fontManager.updateFont(using: url)
                    } catch {
                        self.error = error
                    }
                }
            })
            
            return true
        }
    }
    
    private var systemFontButton: some View {
        Button {
            fontManager.updateToSystemFont()
        } label: {
            Text("Use System Font")
        }
    }
    
    private func openFile() {
        if Self.openPanel.runModal() == .OK,
           let url = Self.openPanel.url {
            do {
                try fontManager.updateFont(using: url)
            } catch {
                self.error = error
            }
        }
    }
    
    private static let openPanel: NSOpenPanel = {
        let panel = NSOpenPanel()
        
        panel.allowsMultipleSelection = false
        panel.canChooseDirectories = false
        panel.allowedContentTypes = [.font]
        
        return panel
    }()
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
