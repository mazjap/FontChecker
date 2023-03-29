import AppKit

class FontManager: ObservableObject {
    @Published var font: NSFont?
    
    private(set) var url: URL?
    private(set) var supportedLanguages: [String]?
    
    @MainActor
    func updateFont(using fontURL: URL) throws {
        guard let fontDataProvider = CGDataProvider(url: fontURL as CFURL),
              let data = fontDataProvider.data,
              let fontDescriptor = CTFontManagerCreateFontDescriptorFromData(data)
        else {
            throw AppError.noData
        }
        
        self.updateFont(using: CTFontCreateWithFontDescriptor(fontDescriptor, 12, nil))
    }
    
    @MainActor
    func updateToSystemFont() {
        updateFont(using: NSFont.systemFont(ofSize: NSFont.systemFontSize))
    }
    
    private func updateFont(using font: NSFont) {
        let characterSet = CTFontCopyCharacterSet(font) as CharacterSet
        let locales = Locale.availableIdentifiers.map { Locale(identifier: $0) }
        
        let languages = locales.reduce(into: Set<String>()) { result, locale in
            guard let exemplarCharacterSet = locale.exemplarCharacterSet,
                  exemplarCharacterSet.isSubset(of: characterSet) else {
                return
            }
            
            result.insert(Locale.current.localizedString(forLanguageCode: locale.identifier) ?? locale.identifier)
        }
        .sorted()
        
        self.supportedLanguages = languages
        
        self.font = font
    }
}
