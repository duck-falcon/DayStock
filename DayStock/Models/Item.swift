import Foundation

struct Item: Codable, Identifiable {
    let id: UUID
    var name: String
    var stock: Decimal
    var daily: Decimal
    var defaultRefill: Decimal
    var sortOrder: Int
    
    init(name: String, stock: Decimal, daily: Decimal, defaultRefill: Decimal, sortOrder: Int = 0) {
        self.id = UUID()
        self.name = name
        self.stock = stock
        self.daily = daily
        self.defaultRefill = defaultRefill
        self.sortOrder = sortOrder
    }
    
    var daysRemaining: Decimal? {
        guard daily > 0 else { return nil }
        return stock / daily
    }
}