import SwiftUI

struct ItemSimpleRowView: View {
    let item: Item
    let showMode: ShowMode
    let warningLevel: WarningLevel
    let formattedDays: String?
    let onRefill: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            // 警告アイコン（左側）
            if warningLevel != .normal {
                Image(systemName: warningIcon)
                    .font(.system(size: 16))
                    .foregroundColor(warningIconColor)
                    .frame(width: 20)
            } else {
                Spacer()
                    .frame(width: 20)
            }
            
            // アイテム名
            Text(item.name)
                .font(.system(size: 17))
                .lineLimit(1)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            Spacer(minLength: 20)
            
            // 表示値（日数または在庫）
            if showMode == .days {
                if let days = formattedDays {
                    HStack(spacing: 4) {
                        Text("あと")
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                        Text("\(days)日")
                            .font(.system(size: 17, weight: .medium))
                            .foregroundColor(warningTextColor)
                    }
                } else {
                    Text("−")
                        .font(.system(size: 17))
                        .foregroundColor(.secondary)
                }
                
                // 日数モード時のみ補充ボタン
                Button(action: onRefill) {
                    Image(systemName: "plus.circle")
                        .font(.system(size: 20))
                        .foregroundColor(item.defaultRefill > 0 ? .blue : .gray)
                }
                .disabled(item.defaultRefill <= 0)
                .buttonStyle(PlainButtonStyle())
                
            } else {
                // 在庫モード：数値と+/-ボタンをまとめて表示
                HStack(spacing: 8) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Text(formatDecimal(item.stock))
                        .font(.system(size: 17, weight: .medium))
                        .foregroundColor(warningTextColor)
                        .frame(minWidth: 30)
                    
                    Button(action: onIncrement) {
                        Image(systemName: "plus.circle")
                            .font(.system(size: 18))
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 16)
        .background(
            Rectangle()
                .fill(warningBackgroundColor)
        )
    }
    
    private var warningTextColor: Color {
        switch warningLevel {
        case .critical:
            return .red
        case .warning:
            return .orange
        case .normal:
            return .primary
        }
    }
    
    private var warningIconColor: Color {
        switch warningLevel {
        case .critical:
            return .red
        case .warning:
            return .orange
        case .normal:
            return .clear
        }
    }
    
    private var warningIcon: String {
        switch warningLevel {
        case .critical:
            return "exclamationmark.circle.fill"
        case .warning:
            return "exclamationmark.triangle.fill"
        case .normal:
            return ""
        }
    }
    
    private var warningBackgroundColor: Color {
        switch warningLevel {
        case .critical:
            return Color.red.opacity(0.05)
        case .warning:
            return Color.yellow.opacity(0.05)
        case .normal:
            return Color.clear
        }
    }
    
    private func formatDecimal(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        if value.isInteger {
            return "\(Int(number.doubleValue))"
        } else {
            return String(format: "%.1f", number.doubleValue)
        }
    }
}