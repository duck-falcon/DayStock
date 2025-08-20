import SwiftUI

struct ItemEditView: View {
    @ObservedObject var store: DataStore
    let item: Item?
    @Environment(\.dismiss) private var dismiss
    
    @State private var name: String = ""
    @State private var stockText: String = ""
    @State private var dailyText: String = ""
    @State private var defaultRefillText: String = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    init(store: DataStore, item: Item?) {
        self.store = store
        self.item = item
    }
    
    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("基本情報")) {
                    TextField("名前", text: $name)
                        .textInputAutocapitalization(.never)
                }
                
                Section(header: Text("在庫管理")) {
                    HStack {
                        Text("現在の在庫")
                        Spacer()
                        TextField("0", text: $stockText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("1日あたりの消費量")
                        Spacer()
                        TextField("0", text: $dailyText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("既定補充量")
                        Spacer()
                        TextField("0", text: $defaultRefillText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if let days = calculateDaysPreview() {
                    Section(header: Text("プレビュー")) {
                        HStack {
                            Text("残り日数")
                            Spacer()
                            if let daysValue = days {
                                Text("\(store.formatDays(daysValue))日分")
                                    .foregroundColor(.secondary)
                            } else {
                                Text("消費なし")
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "新規アイテム" : "アイテム編集")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("キャンセル") {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("保存") {
                        saveItem()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                setupInitialValues()
            }
            .alert("エラー", isPresented: $showingAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(alertMessage)
            }
        }
    }
    
    private func setupInitialValues() {
        if let item = item {
            name = item.name
            stockText = formatDecimalForEditing(item.stock)
            dailyText = formatDecimalForEditing(item.daily)
            defaultRefillText = formatDecimalForEditing(item.defaultRefill)
        }
    }
    
    private func formatDecimalForEditing(_ value: Decimal) -> String {
        let number = NSDecimalNumber(decimal: value)
        if value.isInteger {
            return "\(Int(number.doubleValue))"
        } else {
            return String(format: "%.1f", number.doubleValue)
        }
    }
    
    private func parseDecimal(_ text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return 0
        }
        return Decimal(string: trimmed, locale: Locale.current)
    }
    
    private func calculateDaysPreview() -> Decimal?? {
        guard let stock = parseDecimal(stockText),
              let daily = parseDecimal(dailyText) else {
            return nil
        }
        
        if daily > 0 {
            return stock / daily
        } else {
            return .some(nil)
        }
    }
    
    private func saveItem() {
        guard !name.isEmpty else {
            alertMessage = "名前を入力してください"
            showingAlert = true
            return
        }
        
        guard let stock = parseDecimal(stockText),
              let daily = parseDecimal(dailyText),
              let defaultRefill = parseDecimal(defaultRefillText) else {
            alertMessage = "数値が正しくありません"
            showingAlert = true
            return
        }
        
        if let existingItem = item {
            var updatedItem = existingItem
            updatedItem.name = name
            updatedItem.stock = stock
            updatedItem.daily = daily
            updatedItem.defaultRefill = defaultRefill
            store.updateItem(updatedItem)
        } else {
            let newItem = Item(
                name: name,
                stock: stock,
                daily: daily,
                defaultRefill: defaultRefill
            )
            store.addItem(newItem)
        }
        
        dismiss()
    }
}