import Foundation
import SwiftUI

class DataStore: ObservableObject {
    @Published var appState: AppState
    @Published var settings: AppSettings
    @Published var sortedItems: [Item] = []
    
    private let appStateKey = "DayStock.AppState"
    private let settingsKey = "DayStock.Settings"
    private let userDefaults = UserDefaults.standard
    private var sortTimer: Timer?
    
    init() {
        self.appState = DataStore.loadAppState()
        self.settings = DataStore.loadSettings()
        performStartupAdjustment()
        updateSortedItems()
    }
    
    private static func loadAppState() -> AppState {
        guard let data = UserDefaults.standard.data(forKey: "DayStock.AppState"),
              let state = try? JSONDecoder().decode(AppState.self, from: data) else {
            return AppState()
        }
        return state
    }
    
    private static func loadSettings() -> AppSettings {
        guard let data = UserDefaults.standard.data(forKey: "DayStock.Settings"),
              let settings = try? JSONDecoder().decode(AppSettings.self, from: data) else {
            return AppSettings.default
        }
        return settings
    }
    
    func save() {
        if let encoded = try? JSONEncoder().encode(appState) {
            userDefaults.set(encoded, forKey: appStateKey)
        }
        if let encoded = try? JSONEncoder().encode(settings) {
            userDefaults.set(encoded, forKey: settingsKey)
        }
    }
    
    private func updateSortedItems() {
        let newSortedItems = appState.items.sorted { item1, item2 in
            let days1 = item1.daysRemaining ?? Decimal(999999)
            let days2 = item2.daysRemaining ?? Decimal(999999)
            return days1 < days2
        }
        
        // アニメーション付きでソート更新
        withAnimation(.easeInOut(duration: 0.3)) {
            sortedItems = newSortedItems
        }
    }
    
    private func updateSortedItemsImmediately() {
        // 数値更新時: ソートは変えずに既存の配列の中身だけ更新
        for i in 0..<sortedItems.count {
            if let updatedItem = appState.items.first(where: { $0.id == sortedItems[i].id }) {
                sortedItems[i] = updatedItem
            }
        }
    }
    
    private func scheduleSortUpdate() {
        // 数値は即座に更新
        updateSortedItemsImmediately()
        
        // ソートは遅延実行
        sortTimer?.invalidate()
        sortTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: false) { _ in
            DispatchQueue.main.async {
                self.updateSortedItems()
            }
        }
    }
    
    func performStartupAdjustment() {
        let now = Date()
        
        guard let lastUpdated = appState.updatedAt else {
            appState.updatedAt = now
            save()
            return
        }
        
        let elapsedDays = calculateMidnightsPassed(from: lastUpdated, to: now)
        
        if elapsedDays > 0 {
            for index in appState.items.indices {
                let consumed = appState.items[index].daily * Decimal(elapsedDays)
                appState.items[index].stock = max(0, appState.items[index].stock - consumed)
            }
            appState.updatedAt = now
            save()
            updateSortedItems()
        }
    }
    
    private func calculateMidnightsPassed(from: Date, to: Date) -> Int {
        let calendar = Calendar.current
        let fromStart = calendar.startOfDay(for: from)
        let toStart = calendar.startOfDay(for: to)
        let days = calendar.dateComponents([.day], from: fromStart, to: toStart).day ?? 0
        return max(0, days)
    }
    
    func addItem(_ item: Item) {
        var newItem = item
        newItem.sortOrder = (appState.items.map { $0.sortOrder }.max() ?? -1) + 1
        appState.items.append(newItem)
        save()
        updateSortedItems()
    }
    
    func updateItem(_ item: Item) {
        if let index = appState.items.firstIndex(where: { $0.id == item.id }) {
            appState.items[index] = item
            save()
            updateSortedItems()
        }
    }
    
    func deleteItem(_ item: Item) {
        appState.items.removeAll { $0.id == item.id }
        save()
        updateSortedItems()
    }
    
    func refillItem(_ item: Item) {
        if let index = appState.items.firstIndex(where: { $0.id == item.id }) {
            appState.items[index].stock += appState.items[index].defaultRefill
            appState.updatedAt = Date()
            save()
            scheduleSortUpdate()
        }
    }
    
    func refillAll() {
        for index in appState.items.indices {
            appState.items[index].stock += appState.items[index].defaultRefill
        }
        appState.updatedAt = Date()
        save()
        scheduleSortUpdate()
    }
    
    func incrementStock(_ item: Item) {
        if let index = appState.items.firstIndex(where: { $0.id == item.id }) {
            appState.items[index].stock += 1
            appState.updatedAt = Date()
            save()
            scheduleSortUpdate()
        }
    }
    
    func decrementStock(_ item: Item) {
        if let index = appState.items.firstIndex(where: { $0.id == item.id }) {
            appState.items[index].stock = max(0, appState.items[index].stock - 1)
            appState.updatedAt = Date()
            save()
            scheduleSortUpdate()
        }
    }
    
    func updateSortOrder(items: [Item]) {
        for (index, item) in items.enumerated() {
            if let itemIndex = appState.items.firstIndex(where: { $0.id == item.id }) {
                appState.items[itemIndex].sortOrder = index
            }
        }
        save()
    }
    
    func getWarningLevel(for item: Item) -> WarningLevel {
        guard let days = item.daysRemaining else { return .normal }
        
        if days <= settings.warnRedDays {
            return .critical
        } else if days <= settings.warnYellowDays {
            return .warning
        } else {
            return .normal
        }
    }
    
    func formatDays(_ days: Decimal) -> String {
        switch settings.roundingMode {
        case .floor:
            return "\(Int(NSDecimalNumber(decimal: days).floatValue.rounded(.down)))"
        case .ceil:
            return "\(Int(NSDecimalNumber(decimal: days).floatValue.rounded(.up)))"
        case .round:
            return "\(Int(NSDecimalNumber(decimal: days).floatValue.rounded()))"
        case .raw:
            return String(format: "%.1f", NSDecimalNumber(decimal: days).doubleValue)
        }
    }
    
    func checkStockoutItems() -> [Item] {
        return appState.items.filter { item in
            guard let days = item.daysRemaining else { return false }
            return days <= 0
        }
    }
}