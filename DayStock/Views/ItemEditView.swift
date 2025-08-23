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
                Section(header: Text("edit.section.basic".localized)) {
                    TextField("edit.field.name".localized, text: $name)
                        .textInputAutocapitalization(.never)
                }
                
                Section(header: Text("edit.section.stock".localized)) {
                    HStack {
                        Text("edit.field.currentStock".localized)
                        Spacer()
                        TextField("0", text: $stockText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("edit.field.dailyConsumption".localized)
                        Spacer()
                        TextField("0", text: $dailyText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    
                    HStack {
                        Text("edit.field.defaultRefill".localized)
                        Spacer()
                        TextField("0", text: $defaultRefillText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if let days = calculateDaysPreview() {
                    Section(header: Text("edit.section.preview".localized)) {
                        HStack {
                            Text("edit.field.remainingDays".localized)
                            Spacer()
                            if let daysValue = days {
                                Text("\(store.formatDays(daysValue))" + "main.days.suffix".localized)
                                    .foregroundColor(.secondary)
                            } else {
                                Text("main.noConsumption".localized)
                                    .foregroundColor(.secondary)
                            }
                        }
                    }
                }
            }
            .navigationTitle(item == nil ? "edit.title.new".localized : "edit.title.edit".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("edit.cancel".localized) {
                        dismiss()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("edit.save".localized) {
                        saveItem()
                    }
                    .fontWeight(.semibold)
                    .disabled(name.isEmpty)
                }
            }
            .onAppear {
                setupInitialValues()
            }
            .alert("edit.error.title".localized, isPresented: $showingAlert) {
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
            alertMessage = "edit.error.nameRequired".localized
            showingAlert = true
            return
        }
        
        guard let stock = parseDecimal(stockText),
              let daily = parseDecimal(dailyText),
              let defaultRefill = parseDecimal(defaultRefillText) else {
            alertMessage = "edit.error.invalidNumber".localized
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