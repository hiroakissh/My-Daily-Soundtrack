# My Daily Soundtrack

日常の瞬間を「映画のワンシーン」として再解釈し、位置・時間・天気・モーションから最適化されたサウンドトラックを自動生成・再生する iOS アプリ。

## 現在の実装

- macOS / Xcode 26 以上 / Swift 6.0 以上
- Deployment Target: iOS 17.0
- デバイス検証時は Xcode にサインインした Apple Developer アカウント
- SwiftUI + Combine（StateObservationKit は依存として管理）

```bash
git clone <repo-url>
cd My-Daily-Soundtrack
xcodegen generate
```

プロジェクトファイルは `project.yml` から生成できます。通常は同梱済みの `MyDailySoundtrack.xcodeproj` を開けば動作します。

## 初回セットアップ

1. **依存関係の解決**
- `xcodegen generate` または Xcode の Swift Package 解決で StateObservationKit を取得
- 依存先は `project.yml` に定義済み

2. **Capabilities**
- Location Updates（When In Use + Background Modes → Location updates）
- Motion & Fitness（Core Motion）
- Background Audio
- WeatherKit entitlement（WeatherKit を使う場合。外部 API を使う場合は API Key 管理を別途）

3. **推奨ビルド設定**
- Deployment Target: iOS 17.0 以上
- Debug ビルドで `-warnings-as-errors`（任意）
- ロケーション検証が必要なら Scheme の “Launch due to location changes” を有効

4. **推奨フォルダ構成**
- `App/Presentation`: SwiftUI View と ViewModel
- `App/Domain`: コンテキストモデル、Scene 判定、Score 設計
- `App/Infrastructure`: 位置/天気/モーション/オーディオの Provider、DI コンテナ
- `App/Opening`: オープニング演出とロジック
- `Resources`: オーディオ（ステム/FX）、カラーパレット、アニメーションアセット

## クイックスタート

```bash
xcodebuild -project MyDailySoundtrack.xcodeproj \
  -scheme MyDailySoundtrack \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=17.2' \
  build
```

アプリの初回起動は、オンボーディング → 位置情報ガイド → メイン再生画面の順です。位置情報を「あとで」にした場合でも、手動再生は確認できます。

## ステート管理メモ

現在の実装は `ObservableObject`、`@Published`、Combine Publisher でコンテキスト・シーン・スコアを配信しています。StateObservationKit は `project.yml` に依存として固定してあり、状態管理の置き換え候補として残しています。

## 実装済み・残課題

- オンボーディングと完了状態の保存
- Core Location 権限、設定アプリ遷移、バックグラウンド位置更新
- Core Motion の歩行／走行／停止判定とケイデンス取得
- 位置・時間・天気・モーションのContext集約、Scene判定、Score計画
- 位置タグごとの手続き型オーディオ再生、停止、一時停止、エラーリトライ
- 日次オープニング演出と開発ビルド用デバッグオーバーレイ
- 残課題: 実際のジオフェンス設定、WeatherKit接続、音源ステムを使った本番向け音色、実機でのバックグラウンド検証

### 現在の音楽生成ロジック

再生時はScorePlanをもとに、位置タグごとのキーで8小節のループを生成します。ループ内ではI–vi–IV–V系のコード進行に、パッド、ベース、8分音符のアルペジオ、キック、スネア、ハイハットを重ねます。シーン判定から渡されるBPM、各レイヤー音量、フィルター、残響が実際のAVAudioEngineへ反映され、歩行・走行時はリズムとテンポが強くなり、停止時はビートが薄くなります。

## 追加ドキュメント

- iOS 環境セットアップ: `docs/setup/ios-environment.md`
