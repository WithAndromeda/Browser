import Foundation

struct SiteRule: Codable, Identifiable {
    let id: UUID
    var pattern: String
    var allowJavaScript: Bool?
    var allowThirdPartyCookies: Bool?
    
    init(pattern: String, allowJavaScript: Bool? = nil, allowThirdPartyCookies: Bool? = nil) {
        self.id = UUID()
        self.pattern = pattern
        self.allowJavaScript = allowJavaScript
        self.allowThirdPartyCookies = allowThirdPartyCookies
    }
}

extension SiteRule {
    func matches(url: String) -> Bool {
        let pattern = self.pattern
            .replacingOccurrences(of: ".", with: "\\.")
            .replacingOccurrences(of: "*", with: ".*")
        
        let regex = try? NSRegularExpression(pattern: "^\(pattern)$")
        let range = NSRange(url.startIndex..<url.endIndex, in: url)
        return regex?.firstMatch(in: url, range: range) != nil
    }
}