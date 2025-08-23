import SwiftUI

struct ContentView: View {
    @StateObject private var store = DataStore()
    @State private var showingAddItem = false
    @State private var showingSettings = false
    @State private var editingItem: Item?
    @State private var isEditMode = false
    @State private var showStockoutAlert = false
    @State private var stockoutMessage = ""
    @State private var showingRefillConfirm = false
    
    var sortedItems: [Item] {
        return store.sortedItems
    }
    
    var body: some View {
        NavigationView {
            ZStack {
                if store.appState.items.isEmpty {
                    emptyStateView
                } else {
                    itemListView
                }
            }
            .navigationTitle("main.title".localized)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    if !store.appState.items.isEmpty {
                        Picker("表示モード", selection: $store.settings.showMode) {
                            Text("mode.days".localized).tag(ShowMode.days)
                            Text("mode.stock".localized).tag(ShowMode.stock)
                        }
                        .pickerStyle(SegmentedPickerStyle())
                        .frame(width: 120)
                        .onChange(of: store.settings.showMode) { _ in
                            store.save()
                        }
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        // 全補充ボタンは日数モード時のみ表示
                        if !store.appState.items.isEmpty && store.settings.showMode == .days {
                            Button("main.refillAll".localized) {
                                showingRefillConfirm = true
                            }
                            .font(.callout)
                            .fontWeight(.medium)
                        }
                        
                        Button(action: { showingAddItem = true }) {
                            Image(systemName: "plus")
                        }
                    }
                }
            }
            .sheet(isPresented: $showingAddItem) {
                ItemEditView(store: store, item: nil)
            }
            .sheet(item: $editingItem) { item in
                ItemEditView(store: store, item: item)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(store: store)
            }
        }
        .onAppear {
            checkStockout()
        }
        .alert("stockout.alert.title".localized, isPresented: $showStockoutAlert) {
            Button("stockout.alert.ok".localized, role: .cancel) { }
        } message: {
            Text(stockoutMessage)
        }
        .confirmationDialog("main.confirmRefillAll.title".localized, isPresented: $showingRefillConfirm, titleVisibility: .visible) {
            Button("main.confirmRefillAll.confirm".localized, role: .destructive) {
                store.refillAll()
            }
            Button("main.confirmRefillAll.cancel".localized, role: .cancel) { }
        } message: {
            Text("main.confirmRefillAll.message".localized)
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("main.empty.message".localized)
                .font(.title2)
                .foregroundColor(.secondary)
            
            Button(action: { showingAddItem = true }) {
                Label("main.empty.addButton".localized, systemImage: "plus.circle.fill")
                    .font(.headline)
            }
            .buttonStyle(.borderedProminent)
        }
    }
    
    private var itemListView: some View {
        List {
            ForEach(sortedItems, id: \.id) { item in
                if store.settings.displayStyle == .simple {
                    ItemSimpleRowView(
                        item: item,
                        showMode: store.settings.showMode,
                        warningLevel: store.getWarningLevel(for: item),
                        formattedDays: item.daysRemaining.map { store.formatDays($0) },
                        onRefill: { store.refillItem(item) },
                        onIncrement: { store.incrementStock(item) },
                        onDecrement: { store.decrementStock(item) }
                    )
                    .listRowInsets(EdgeInsets())
                    .listRowSeparator(.hidden)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        editingItem = item
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            store.deleteItem(item)
                        } label: {
                            Label("action.delete".localized, systemImage: "trash")
                        }
                    }
                } else {
                    ItemRowView(
                        item: item,
                        showMode: store.settings.showMode,
                        warningLevel: store.getWarningLevel(for: item),
                        formattedDays: item.daysRemaining.map { store.formatDays($0) },
                        onRefill: { store.refillItem(item) },
                        onIncrement: { store.incrementStock(item) },
                        onDecrement: { store.decrementStock(item) }
                    )
                    .contentShape(Rectangle())
                    .onTapGesture {
                        if !isEditMode {
                            editingItem = item
                        }
                    }
                }
            }
            .onDelete { indexSet in
                for index in indexSet {
                    let itemToDelete = sortedItems[index]
                    store.deleteItem(itemToDelete)
                }
            }
        }
        .listStyle(PlainListStyle())
    }
    
    private func checkStockout() {
        guard store.settings.notificationsOn else { return }
        
        let stockoutItems = store.checkStockoutItems()
        if !stockoutItems.isEmpty {
            if stockoutItems.count == 1 {
                stockoutMessage = "stockout.alert.single".localized(with: stockoutItems[0].name)
            } else {
                let names = stockoutItems.prefix(2).map { $0.name }.joined(separator: "、")
                let remaining = stockoutItems.count - 2
                if remaining > 0 {
                    stockoutMessage = "stockout.alert.multiple".localized(with: names) + "stockout.alert.more".localized(with: remaining)
                } else {
                    stockoutMessage = "stockout.alert.multiple".localized(with: names)
                }
            }
            showStockoutAlert = true
        }
    }
}