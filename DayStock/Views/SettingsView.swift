import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("settings.section.display".localized), footer: Text(store.settings.displayStyle == .simple ? "settings.displayStyle.simple.footer".localized : "settings.displayStyle.detailed.footer".localized)) {
                    Picker("settings.displayStyle".localized, selection: $store.settings.displayStyle) {
                        ForEach(DisplayStyle.allCases, id: \.self) { style in
                            Text(style.displayName).tag(style)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("settings.roundingMode".localized, selection: $store.settings.roundingMode) {
                        ForEach(RoundingMode.allCases, id: \.self) { mode in
                            Text(mode.displayName).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("settings.section.warning".localized), footer: Text("settings.warning.footer".localized)) {
                    HStack {
                        Label("settings.warning.yellow".localized, systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.orange)
                        Spacer()
                        Stepper(value: $store.settings.warnYellowDays, in: 1...30, step: 1) {
                            Text("\(formatDecimalForSettings(store.settings.warnYellowDays))" + "settings.warning.days".localized)
                                .foregroundColor(.secondary)
                        }
                        .onChange(of: store.settings.warnYellowDays) { _ in
                            store.save()
                        }
                    }
                    
                    HStack {
                        Label("settings.warning.red".localized, systemImage: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Spacer()
                        Stepper(value: $store.settings.warnRedDays, in: 0...10, step: 1) {
                            Text("\(formatDecimalForSettings(store.settings.warnRedDays))" + "settings.warning.days".localized)
                                .foregroundColor(.secondary)
                        }
                        .onChange(of: store.settings.warnRedDays) { _ in
                            store.save()
                        }
                    }
                }
                
                Section(header: Text("settings.section.notification".localized)) {
                    Toggle(isOn: $store.settings.notificationsOn) {
                        Label("settings.notification.stockout".localized, systemImage: "bell")
                    }
                    
                    if store.settings.notificationsOn {
                        Text("settings.notification.description".localized)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("settings.section.about".localized)) {
                    HStack {
                        Text("settings.about.version".localized)
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("settings.about.itemCount".localized)
                        Spacer()
                        Text("\(store.appState.items.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let updatedAt = store.appState.updatedAt {
                        HStack {
                            Text("settings.about.lastUpdate".localized)
                            Spacer()
                            Text(formatDate(updatedAt))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("settings.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("settings.done".localized) {
                        dismiss()
                    }
                }
            }
        }
    }
    
    private func formatDecimalForSettings(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        return "\(Int(number.doubleValue))"
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}