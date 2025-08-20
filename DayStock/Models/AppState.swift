import Foundation

struct AppState: Codable {
    var items: [Item]
    var updatedAt: Date?
    
    init(items: [Item] = [], updatedAt: Date? = nil) {
        self.items = items
        self.updatedAt = updatedAt
    }
}