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
            .navigationTitle("DayStock")
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showingSettings = true }) {
                        Image(systemName: "gearshape")
                    }
                }
                
                ToolbarItem(placement: .principal) {
                    if !store.appState.items.isEmpty {
                        Picker("表示モード", selection: $store.settings.showMode) {
                            Text("日数").tag(ShowMode.days)
                            Text("在庫").tag(ShowMode.stock)
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
                            Button("全補充") {
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
        .alert("在庫切れ", isPresented: $showStockoutAlert) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(stockoutMessage)
        }
        .confirmationDialog("全アイテムを補充", isPresented: $showingRefillConfirm, titleVisibility: .visible) {
            Button("補充する", role: .destructive) {
                store.refillAll()
            }
            Button("キャンセル", role: .cancel) { }
        } message: {
            Text("全てのアイテムに既定補充量を追加します。この操作は取り消せません。")
        }
    }
    
    private var emptyStateView: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("アイテムを追加してください")
                .font(.title2)
                .foregroundColor(.secondary)
            
            Button(action: { showingAddItem = true }) {
                Label("アイテムを追加", systemImage: "plus.circle.fill")
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
                            Label("削除", systemImage: "trash")
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
                stockoutMessage = "『\(stockoutItems[0].name)』の在庫が切れています"
            } else {
                let names = stockoutItems.prefix(2).map { $0.name }.joined(separator: "、")
                let remaining = stockoutItems.count - 2
                if remaining > 0 {
                    stockoutMessage = "在庫切れ: \(names)、他\(remaining)件"
                } else {
                    stockoutMessage = "在庫切れ: \(names)"
                }
            }
            showStockoutAlert = true
        }
    }
}