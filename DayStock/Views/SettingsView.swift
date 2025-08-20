import SwiftUI

struct SettingsView: View {
    @ObservedObject var store: DataStore
    @Environment(\.dismiss) private var dismiss
    
    @State private var yellowDaysText: String = ""
    @State private var redDaysText: String = ""
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("表示設定"), footer: Text(store.settings.displayStyle == .simple ? "シンプル: 1行表示でスッキリ" : "詳細: 詳しい情報を表示")) {
                    Picker("表示スタイル", selection: $store.settings.displayStyle) {
                        ForEach(DisplayStyle.allCases, id: \.self) { style in
                            Text(style.rawValue).tag(style)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                    
                    Picker("丸め方法", selection: $store.settings.roundingMode) {
                        ForEach(RoundingMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section(header: Text("警告設定"), footer: Text("残り日数がこの値以下になると色が変わります")) {
                    HStack {
                        Label("黄色警告", systemImage: "exclamationmark.triangle.fill")
                            .foregroundColor(.yellow)
                        Spacer()
                        TextField("3", text: $yellowDaysText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                        Text("日以下")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Label("赤色警告", systemImage: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Spacer()
                        TextField("1", text: $redDaysText)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                            .frame(width: 50)
                        Text("日以下")
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("通知設定")) {
                    Toggle(isOn: $store.settings.notificationsOn) {
                        Label("在庫切れ通知", systemImage: "bell")
                    }
                    
                    if store.settings.notificationsOn {
                        Text("アプリ起動時に在庫切れアイテムを通知します")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                }
                
                Section(header: Text("アプリ情報")) {
                    HStack {
                        Text("バージョン")
                        Spacer()
                        Text("1.0.0")
                            .foregroundColor(.secondary)
                    }
                    
                    HStack {
                        Text("アイテム数")
                        Spacer()
                        Text("\(store.appState.items.count)")
                            .foregroundColor(.secondary)
                    }
                    
                    if let updatedAt = store.appState.updatedAt {
                        HStack {
                            Text("最終更新")
                            Spacer()
                            Text(formatDate(updatedAt))
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("設定")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("完了") {
                        saveSettings()
                        dismiss()
                    }
                }
            }
            .onAppear {
                setupInitialValues()
            }
        }
    }
    
    private func setupInitialValues() {
        yellowDaysText = formatDecimalForSettings(store.settings.warnYellowDays)
        redDaysText = formatDecimalForSettings(store.settings.warnRedDays)
    }
    
    private func formatDecimalForSettings(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        return "\(Int(number.doubleValue))"
    }
    
    private func saveSettings() {
        if let yellowDays = Decimal(string: yellowDaysText),
           yellowDays > 0 {
            store.settings.warnYellowDays = yellowDays
        }
        
        if let redDays = Decimal(string: redDaysText),
           redDays > 0 {
            store.settings.warnRedDays = redDays
        }
        
        store.save()
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .short
        formatter.timeStyle = .short
        formatter.locale = Locale(identifier: "ja_JP")
        return formatter.string(from: date)
    }
}