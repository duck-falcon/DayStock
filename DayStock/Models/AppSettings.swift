import Foundation

enum RoundingMode: String, Codable, CaseIterable {
    case floor
    case ceil
    case round
    case raw
    
    var displayName: String {
        switch self {
        case .floor: return "settings.roundingMode.floor".localized
        case .ceil: return "settings.roundingMode.ceil".localized
        case .round: return "settings.roundingMode.round".localized
        case .raw: return "settings.roundingMode.raw".localized
        }
    }
}

enum ShowMode: String, Codable {
    case days
    case stock
}

enum DisplayStyle: String, Codable, CaseIterable {
    case simple
    case detailed
    
    var displayName: String {
        switch self {
        case .simple: return "settings.displayStyle.simple".localized
        case .detailed: return "settings.displayStyle.detailed".localized
        }
    }
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