import Foundation
import Combine

// Singleton to manage app-wide localization
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: Language = .english
    @Published var strings: [String: String] = [:]
    
    private var cancellables = Set<AnyCancellable>()
    
    private init() {
        loadStrings(for: currentLanguage)
    }
    
    func setLanguage(_ language: Language) {
        guard language != currentLanguage else { return }
        
        currentLanguage = language
        loadStrings(for: language)
        
        // Set API language as well
        APIService.shared.setLanguage(language.rawValue)
    }
    
    private func loadStrings(for language: Language) {
        guard let url = Bundle.main.url(forResource: "Localizations", withExtension: "json") else {
            print("Error: Localizations.json file not found")
            return
        }
        
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data) as? [String: [String: String]]
            
            if let languageDict = json?[language.rawValue] {
                strings = languageDict
            } else {
                print("Warning: No strings found for language: \(language.rawValue)")
            }
        } catch {
            print("Error loading localizations: \(error.localizedDescription)")
        }
    }
    
    func localized(_ key: String) -> String {
        return strings[key] ?? key
    }
}

// Extension to String for easy localization
extension String {
    var localized: String {
        return LocalizationManager.shared.localized(self)
    }
} 