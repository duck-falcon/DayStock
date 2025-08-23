import SwiftUI

struct ItemRowView: View {
    let item: Item
    let showMode: ShowMode
    let warningLevel: WarningLevel
    let formattedDays: String?
    let onRefill: () -> Void
    let onIncrement: () -> Void
    let onDecrement: () -> Void
    
    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(item.name)
                    .font(.headline)
                
                HStack {
                    if showMode == .days {
                        if let days = formattedDays {
                            Text("main.days.prefix".localized + "\(days)" + "main.days.suffix".localized)
                                .font(.title2)
                                .fontWeight(.semibold)
                        } else {
                            Text("main.noConsumption".localized)
                                .font(.title2)
                                .foregroundColor(.gray)
                        }
                    } else {
                        Text("main.stock.prefix".localized + formatDecimal(item.stock))
                            .font(.title2)
                            .fontWeight(.semibold)
                    }
                }
                
                HStack(spacing: 12) {
                    Text("main.consumptionPerDay".localized + formatDecimal(item.daily))
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Text("main.refillAmount".localized + formatDecimal(item.defaultRefill))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            if showMode == .stock {
                HStack(spacing: 8) {
                    Button(action: onDecrement) {
                        Image(systemName: "minus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                    
                    Button(action: onIncrement) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(PlainButtonStyle())
                }
            }
            
            Button(action: onRefill) {
                Text("main.refillButton".localized)
                    .font(.callout)
                    .fontWeight(.medium)
                    .foregroundColor(.white)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(item.defaultRefill > 0 ? Color.blue : Color.gray)
                    .cornerRadius(8)
            }
            .disabled(item.defaultRefill <= 0)
            .buttonStyle(PlainButtonStyle())
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(warningBackground)
    }
    
    private var warningBackground: some View {
        RoundedRectangle(cornerRadius: 8)
            .fill(warningColor.opacity(0.1))
            .overlay(
                RoundedRectangle(cornerRadius: 8)
                    .strokeBorder(warningColor.opacity(0.3), lineWidth: 1)
            )
    }
    
    private var warningColor: Color {
        switch warningLevel {
        case .critical:
            return .red
        case .warning:
            return .yellow
        case .normal:
            return .clear
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

extension Decimal {
    var isInteger: Bool {
        return self == self.rounded()
    }
    
    func rounded() -> Decimal {
        var result = Decimal()
        var value = self
        NSDecimalRound(&result, &value, 0, .plain)
        return result
    }
}