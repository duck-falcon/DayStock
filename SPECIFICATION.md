# DayStock 仕様書 v1.0

## 概要
在庫管理を「残り日数」ベースで管理するiPhoneアプリ。日用品の在庫を1日あたりの消費量で割った「あと何日分」という視点で管理し、自動的に在庫を減算する。

## 技術要件
- プラットフォーム: iOS（最新版対応）
- フレームワーク: SwiftUI
- データ永続化: UserDefaults
- 通知: ローカル通知（アプリ起動時のみ）

## データモデル

### Item（アイテム）
```swift
struct Item: Codable, Identifiable {
    let id: UUID
    var name: String                // アイテム名
    var stock: Decimal              // 現在の在庫数
    var daily: Decimal              // 1日あたりの消費量
    var defaultRefill: Decimal      // 既定補充量
    var sortOrder: Int              // 並び順（ユーザー定義）
}
```

### AppState（アプリ全体の状態）
```swift
struct AppState: Codable {
    var items: [Item]               // アイテムリスト
    var updatedAt: Date?            // 最終起動補正実行時刻
}
```

### AppSettings（設定）
```swift
struct AppSettings: Codable {
    var roundingMode: RoundingMode   // 丸め方法
    var showMode: ShowMode           // 表示モード
    var warnYellowDays: Decimal     // 黄色警告しきい値（デフォルト: 3）
    var warnRedDays: Decimal         // 赤警告しきい値（デフォルト: 1）
    var notificationsOn: Bool        // 通知オン/オフ
}

enum RoundingMode: String, Codable {
    case floor      // 切り捨て（デフォルト）
    case ceil       // 切り上げ
    case round      // 四捨五入
    case raw        // そのまま（小数1桁表示）
}

enum ShowMode: String, Codable {
    case days       // 「あと◯日分」モード（デフォルト）
    case stock      // 「在庫◯」モード
}
```

## 画面構成

### 1. メインリスト画面

#### ヘッダー
- 「全補充」ボタン（常時表示）
- 「＋」ボタン（新規アイテム追加）

#### リスト表示
各アイテムカードの表示内容：
- アイテム名（大きく）
- メイン表示（モードに応じて切り替え）
  - 日数モード: 「あと◯日分」
  - 在庫モード: 「在庫◯」
- サブ情報（小さく）: 「消費/日: ◯」「補充量: ◯」
- 色分け表示（背景色またはサイドバー）

#### 操作
- **画面タップ**: 表示モード切り替え（日数⇔在庫）
- **アイテムタップ**: 編集モーダル表示
- **アイテム長押し**: 並び替えモード（ドラッグで順序変更）
- **スワイプ**: 削除ボタン表示

#### モード別の追加UI
- **日数モード**: 各行右端に「補充」ボタンのみ
- **在庫モード**: 
  - 「−」「＋」ボタン（在庫の微調整）
  - 「補充」ボタン

#### 空状態
アイテムが0件の場合:
- 中央に「アイテムを追加してください」メッセージ
- 「＋」ボタンまたはタップ領域

### 2. アイテム追加/編集モーダル

入力フィールド:
- 名前（必須、テキスト）
- 在庫（Decimal、キーパッド）
- 1日あたりの消費量（Decimal、キーパッド）
- 既定補充量（Decimal、キーパッド）

ボタン:
- 「保存」（入力検証あり）
- 「キャンセル」

### 3. 設定画面

設定項目:
- **丸め方法**: セグメントコントロール（切り捨て/切り上げ/四捨五入/そのまま）
- **警告しきい値**:
  - 黄色警告: ◯日以下（数値入力）
  - 赤警告: ◯日以下（数値入力）
- **通知**: オン/オフトグル

## 機能仕様

### 起動時補正ロジック

```swift
func performStartupAdjustment() {
    let now = Date()
    
    // 初回起動の場合
    guard let lastUpdated = appState.updatedAt else {
        appState.updatedAt = now
        return
    }
    
    // 経過日数を計算（真夜中通過回数）
    let elapsedDays = calculateMidnightsPassed(from: lastUpdated, to: now)
    
    // 各アイテムの在庫を補正
    for index in appState.items.indices {
        let consumed = appState.items[index].daily * Decimal(elapsedDays)
        appState.items[index].stock = max(0, appState.items[index].stock - consumed)
    }
    
    appState.updatedAt = now
}
```

### 残り日数計算

```swift
func calculateRemainingDays(item: Item) -> Decimal? {
    guard item.daily > 0 else { return nil }  // 無限扱い
    return item.stock / item.daily
}
```

### 表示用丸め処理

```swift
func formatDays(_ days: Decimal, mode: RoundingMode) -> String {
    switch mode {
    case .floor:
        return "\(Int(floor(days)))"
    case .ceil:
        return "\(Int(ceil(days)))"
    case .round:
        return "\(Int(round(days)))"
    case .raw:
        // 小数1桁表示
        return String(format: "%.1f", NSDecimalNumber(decimal: days).doubleValue)
    }
}
```

### 色分けロジック

```swift
func getWarningLevel(days: Decimal?, settings: AppSettings) -> WarningLevel {
    guard let days = days else { return .normal }
    
    if days <= settings.warnRedDays {
        return .critical  // 赤
    } else if days <= settings.warnYellowDays {
        return .warning   // 黄
    } else {
        return .normal    // 通常
    }
}
```

### 並び順

1. ユーザー定義の並び順（sortOrder）を優先
2. 長押しドラッグで並び順変更時、sortOrderを更新
3. 新規アイテムは最後尾に追加（最大sortOrder + 1）

### ボタン動作

#### 補充ボタン（個別）
```swift
func refillItem(_ item: inout Item) {
    item.stock += item.defaultRefill
    appState.updatedAt = Date()
}
```

#### 全補充ボタン
```swift
func refillAll() {
    for index in appState.items.indices {
        appState.items[index].stock += appState.items[index].defaultRefill
    }
    appState.updatedAt = Date()
}
```

#### ＋/−ボタン（在庫モード）
```swift
func incrementStock(_ item: inout Item) {
    item.stock += 1
    appState.updatedAt = Date()
}

func decrementStock(_ item: inout Item) {
    item.stock = max(0, item.stock - 1)
    appState.updatedAt = Date()
}
```

## 通知仕様

### 起動時チェック
```swift
func checkAndNotifyStockout() {
    guard settings.notificationsOn else { return }
    
    let stockoutItems = appState.items.filter { item in
        guard let days = calculateRemainingDays(item: item) else { return false }
        return days <= 0
    }
    
    if !stockoutItems.isEmpty {
        showStockoutNotification(items: stockoutItems)
    }
}
```

### 通知内容
- 1件の場合: 「『卵』の在庫が切れています」
- 複数の場合: 「在庫切れ: 卵、牛乳、他1件」
- タップアクション: アプリを開いて在庫切れアイテムをフィルタ表示

## エッジケース処理

1. **daily = 0の場合**
   - 自動減算なし
   - 残り日数は「∞」または「−」表示
   - 色分けは常に通常色
   - 並び順は最後尾

2. **defaultRefill = 0の場合**
   - 補充ボタンは無効化（グレーアウト）
   - タップ時に「補充量を設定してください」トースト表示

3. **在庫が小数の場合**
   - ＋/−ボタンは±1.0で動作
   - 将来的に設定で刻み幅変更可能に

4. **初回起動**
   - updatedAtがnilの場合、補正処理をスキップ
   - updatedAtに現在時刻をセット

## 将来の拡張案

1. **通知の高度化**
   - アプリ起動時に在庫切れ予測日時を計算
   - その日時にローカル通知を予約
   - バッジ表示（在庫切れ件数）

2. **ソート機能**
   - 残り日数順/名前順/カテゴリ順の切り替え
   - 昇順/降順の切り替え

3. **その他**
   - カテゴリ機能
   - 買い物リスト連携
   - 消費履歴グラフ
   - iCloud同期

## テスト観点

1. **起動時補正**
   - 真夜中をまたいだ場合の在庫減算
   - 複数日経過時の正確な計算
   - タイムゾーン変更時の挙動

2. **表示**
   - 各丸めモードでの表示確認
   - 色分けしきい値の境界値テスト
   - 表示モード切り替えの即時反映

3. **データ操作**
   - 補充時の在庫加算
   - 在庫0以下にならない制約
   - 並び順の保持と更新

4. **通知**
   - 在庫切れ時の通知表示
   - 複数アイテムの通知まとめ
   - 通知オフ時の非表示確認

5. **エッジケース**
   - 空リスト時の表示
   - 極端な数値（大きい/小さい）の処理
   - 不正な入力値のバリデーション