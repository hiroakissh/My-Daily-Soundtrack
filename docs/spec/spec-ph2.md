# My Daily Soundtrack — PH2 実装仕様

## 目的
**位置・時間・天気・モーション**から自動生成・適応するサウンドトラックを、フルスクリーンの SwiftUI 体験として提供する。Scene 判定はルールベースを維持しつつ、将来的に ML 差し替え可能。状態管理は [`StateObservationKit`](https://github.com/hiroakissh/StateObservationKit) を使用。

## アーキテクチャ
- **Presentation (SwiftUI)**: View、ミニ HUD（シーン名・再生インジケータ）、再生/停止ボタン。
- **ViewModel Layer**: DI で組み上げるサービス群。
  - `ContextAggregator`: 10 秒周期で Provider をポーリングし、ノイズ除去後に `ContextSnapshot` を発行。
    - `GeoTagProvider` / `TimeProvider` / `WeatherProvider` / `MotionProvider`（すべて Protocol 化）
  - `SceneClassifier`: ルールベース判定（ダブルヒット確定、60 秒最低維持）。
  - `ScorePlanner`: シーン + モーション変化から `ScorePlan` を生成。
  - `AudioRenderer`: プランを適用（曲切替なし、編曲のみ）。
  - `OpeningDirector`: デイリーのオープニング演出を実行し、`ThemeSeed` を設定・保持。
- **Domain**: モデルとポリシー（Scene ルール、遷移、スコアルール）。
- **Infrastructure**: Provider 実装（CoreLocation / WeatherKit あるいは外部 API / CoreMotion / オーディオエンジン）。
- **DI**: シンプルなコンテナ（ファクトリ構造体など）で本番用とプレビュー/テスト用を切り替え。

## データモデル
```swift
enum GeoTag { case station, park, cafe, river, forest, urban }
enum TimeBand { case morning, afternoon, evening, night }

struct WeatherState {
  enum Condition { case sunny, cloudy, rainy }
  let condition: Condition
  let temperature: Double
  let precipitation: Double // 0.0–1.0
}

struct MotionState {
  enum Activity { case stopped, walking, running }
  let activity: Activity
  let speed: Double      // m/s
  let cadence: Double    // steps/min
}

enum SceneID {
  case morning_intro, commute_hurry, sunny_walk, rainy_walk, cafe_stay, night_walk, nature_ambient
}

struct ContextSnapshot {
  let geoTag: GeoTag
  let timeBand: TimeBand
  let weather: WeatherState
  let motion: MotionState
  let timestamp: Date
}

struct ScorePlan {
  enum Layer { case pad, arp, beat, fx, fieldNoise }
  let baseBPM: Double
  let tempoFollowRate: Double // ケイデンス追従率
  let layerLevels: [Layer: Double] // 0.0–1.0
  let filterCutoff: Double
  let reverbMix: Double
}
```

## ステート管理（StateObservationKit）
- サービスを `@StateObservation` でラップし、SwiftUI からコンテキスト/シーン/スコア/再生状態を直接バインド。
- ドメインオブジェクトはイミュータブルで、更新は値差し替え。
- UI/ルール検証用に決定的シーケンスを出すプレビュー・テストストアを用意。

## Scene 判定
- **ポーリング**: `ContextAggregator` が 10 秒周期。
- **確定**: 同一 `SceneID` が連続 2 回で確定。
- **維持**: 確定後 60 秒はロック（センサー欠損時は `sunny_walk` / `nature_ambient` にフォールバック）。
- **評価順**（上から最初にマッチしたものを採用）:

| SceneID | 主要ルール |
|---------|-----------|
| `morning_intro` | `timeBand == .morning` かつ アプリ/当日開始後 30–60 秒以内、ロックなし |
| `commute_hurry` | `timeBand == .morning` かつ (`geoTag == .station` または `motion.cadence > 110`) |
| `rainy_walk` | `weather.condition == .rainy` かつ `motion.activity == .walking` |
| `cafe_stay` | `geoTag == .cafe` かつ `motion.activity == .stopped` かつ 停止継続 ≥ 90 秒 |
| `night_walk` | `timeBand == .night` かつ (`geoTag == .park` または `.urban`) かつ `motion.activity == .walking` かつ `motion.cadence < 100` |
| `sunny_walk` | (`weather.condition == .sunny` または `.cloudy`) かつ `motion.activity == .walking` |
| `nature_ambient` | フォールバック: `geoTag == .forest || .river || .park` またはアイドル時デフォルト |

- **ノイズ対策**: ケイデンスは移動平均で平滑化、単発スパイクは無視。データ欠損時はタイムアウトまで前シーンを保持。

## ScorePlanner（オーディオ挙動）
- **原則**: トラック切替なし。常駐レイヤーの編曲だけで変化。
- **レイヤーデフォルト**（シーン別、値 0–1）:
  - `commute_hurry`: BPM 120–132、tempoFollowRate 0.6、beat 0.9、arp 0.7、pad 0.4、fx 0.5、field 0.3、フィルタ明るめ、リバーブ控えめ。
  - `sunny_walk`: BPM 110–122、tempoFollowRate 0.5、pad 0.6、arp 0.5、beat 0.6、明るいフィルタ、中リバーブ。
  - `rainy_walk`: BPM 96–108、tempoFollowRate 0.4、beat 0.4、arp 0.3、pad 0.7、fx 0.6、リバーブ深め、フィルタ暗め。
  - `cafe_stay`: BPM 80–92、tempoFollowRate 0.2、beat 0.1、arp 0.2、pad 0.8、fx 0.3、リバーブ豊か、フィルタ暖かめ。
  - `night_walk`: BPM 100–112、tempoFollowRate 0.4、beat 0.5、arp 0.4、pad 0.7、fx 0.6、中程度のリバーブ。
  - `nature_ambient`: BPM 70–86、tempoFollowRate 0.2、beat 0.0–0.2、pad 0.8、fx 0.6、field 0.8、柔らかいフィルタ。
  - `morning_intro`: BPM 88–100、30–60 秒でスロービルド。pad のみ開始 → arp/beat を控えめに足す。
- **インタラクション**:
  - ケイデンス増加 → `baseBPM + (cadence * tempoFollowRate)` へ補間（シーン BPM 範囲内でクリップ）。
  - `motion.activity == .stopped` → `beat` を約 3 秒でフェードアウトし、pad/reverb を上げる。
  - `motion.activity == .running` → `beat` と `arp` を強調（+0.2 を上限付きで加算）。
  - シーン切替 → レベル/フィルタを 1–2 小節でスムーズクロスフェード。

## オープニングタイトル
- **トリガー**: アプリ初回起動、または当日初回起動。
- **長さ**: 30–60 秒。
- **ThemeSeed**: (timeBand, weather.condition, temperature のバケット) から算出し、当日中保持。
- **ビジュアル**: 抽象的な形・パーティクル。天気/時間帯でパレットと動きを変化。具象禁止。
- **フロー**: 完了またはスキップまでメイン UI をブロック。完了後、現在シーンのプランへ遷移。

## UI（最小要件）
- フルスクリーン、情報は最小限。
- 小さなシーンラベル、再生インジケータ、単一の再生/停止トグル。
- 開発用にコンテキスト値と判定を出すデバッグオーバーレイ（任意）。

## テストメモ
- SceneClassifier: コンテキストシーケンスでユニットテスト（ダブルヒット + 60 秒維持）。
- ScorePlanner: 補間とフェード挙動をユニットテスト。
- UI プレビュー: モック Provider とモックオーディオレンダラで決定的状態を再現。
- 統合テスト: モーション/天気/位置の時間変化をシミュレートするシナリオを検討。
