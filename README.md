# My Daily Soundtrack

日常の瞬間を「映画のワンシーン」として再解釈し、位置・時間・天気・モーションから最適化されたサウンドトラックを自動生成・再生する iOS アプリ。

## 環境構築

- macOS / Xcode 26 以上 / Swift 5.10 以上
- デバイス検証のため Xcode にサインインした Apple Developer アカウント
- Homebrew（任意。`swiftlint` などツール管理用）
- リポジトリをクローン後、SwiftUI + Swift Package Manager で Xcode プロジェクトを作成

```bash
git clone <repo-url>
cd My-Daily-Soundtrack
```

1) **プロジェクト作成**
- Xcode: File → New Project → App → Interface: SwiftUI, Language: Swift
- Product Name: `My Daily Soundtrack`、Organization Identifier は逆 DNS
- “Include Tests” を有効、Package Manager を選択

2) **StateObservationKit の追加**
- File → Add Package Dependencies → `https://github.com/hiroakissh/StateObservationKit`
- バージョン: Up to Next Major 0.1.0（または最新）
- メインターゲット（必要ならテストも）に追加

3) **Capabilities**
- Location Updates（When In Use + Background Modes → Location updates）
- Motion & Fitness（Core Motion）
- Background Audio
- WeatherKit entitlement（WeatherKit を使う場合。外部 API を使う場合は API Key 管理を別途）

4) **推奨ビルド設定**
- Deployment Target: iOS 26.0 以上（SwiftUI + Observation を活用）
- Debug ビルドで `-warnings-as-errors`（任意）
- ロケーション検証が必要なら Scheme の “Launch due to location changes” を有効

5) **推奨フォルダ構成**
- `App/Presentation`: SwiftUI View と ViewModel
- `App/Domain`: コンテキストモデル、Scene 判定、Score 設計
- `App/Infrastructure`: 位置/天気/モーション/オーディオの Provider、DI コンテナ
- `App/Opening`: オープニング演出とロジック
- `Resources`: オーディオ（ステム/FX）、カラーパレット、アニメーションアセット

## クイックスタート（プロジェクト作成後）

- ターゲット作成: App + Unit Tests
- DI 経由で依存を解決するシンプルな SwiftUI エントリを用意
- GeoTag/Time/Weather/Motion Provider を protocol ベースでスタブ
- モックコンテキストを流し、現在の `SceneID` を表示する軽量プレビューを追加

## ステート管理メモ

[`StateObservationKit`](https://github.com/hiroakissh/StateObservationKit) を使い、コンテキスト/シーン/スコア計画をコンポーザブルに監視・配信。センサー Provider は `@StateObservation` あるいは Publisher 風のバインディングでラップし、ViewModel から疎結合で購読。

## Next steps

- ドメインモデルとプロトコルを実装（`docs/spec-ph2.md` 参照）
- モックデータソースとプレビューで反復を高速化
- 実センサーを段階的に統合（位置 → モーション → 天気）
- オーディオレンダリングとオープニング演出を追加

## 追加ドキュメント

- iOS 環境セットアップ: `docs/setup/ios-environment.md`
