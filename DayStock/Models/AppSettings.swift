import Foundation

enum RoundingMode: String, Codable, CaseIterable {
    case floor = "切り捨て"
    case ceil = "切り上げ"
    case round = "四捨五入"
    case raw = "そのまま"
}

enum ShowMode: String, Codable {
    case days = "日数"
    case stock = "在庫"
}

enum DisplayStyle: String, Codable, CaseIterable {
    case simple = "シンプル"
    case detailed = "詳細"
}

enum WarningLevel {
    case normal
    case warning
    case critical
}

struct AppSettings: Codable {
    var roundingMode: RoundingMode
    var showMode: ShowMode
    var displayStyle: DisplayStyle
    var warnYellowDays: Decimal
    var warnRedDays: Decimal
    var notificationsOn: Bool
    
    static let `default` = AppSettings(
        roundingMode: .floor,
        showMode: .days,
        displayStyle: .simple,
        warnYellowDays: 3,
        warnRedDays: 1,
        notificationsOn: true
    )
}