# iOS 開発環境セットアップ（Xcode 26 / iOS 26 以降）

## 必要条件
- macOS 最新版推奨（Apple Silicon 対応）。
- Xcode 26 以上（App Store 版または Apple Developer からダウンロード）。
- iOS 26.0 以上で動作する実機（開発用プロビジョニングを設定）。
- Apple Developer アカウントを Xcode にサインイン済み。
- （任意）Homebrew で `git`, `swiftlint` などを管理。

## 手順
1. **Xcode インストール**
   - App Store から Xcode 26+ をインストール。
   - `xcode-select --switch /Applications/Xcode.app` でアクティブ化。
   - 初回起動で追加コンポーネントをインストール。

2. **コマンドラインツール確認**
   ```bash
   xcodebuild -version
   xcode-select -p
   ```
   - 問題があれば `sudo xcode-select --switch /Applications/Xcode.app` で修正。

3. **リポジトリ取得**
   ```bash
   git clone git@github.com:hiroakissh/My-Daily-Soundtrack.git
   cd My-Daily-Soundtrack
   ```

4. **プロジェクト作成（未作成の場合）**
   - Xcode: File → New → Project → App。
   - Interface: SwiftUI、Language: Swift。
   - Product Name: `My Daily Soundtrack`。
   - Team: 自分の Apple ID チームを選択。
   - Targets: iOS Deployment Target を 26.0 に設定。
   - 生成した `.xcodeproj` または `.xcworkspace` をこのリポジトリ直下に保存。

5. **パッケージ追加（StateObservationKit）**
   - Xcode メニュー: File → Add Package Dependencies...
   - URL: `https://github.com/hiroakissh/StateObservationKit`
   - バージョン: Up to Next Major 0.1.0（または最新タグ）。
   - 追加先: アプリ本体ターゲット（必要ならテストターゲットも）。

6. **Capabilities 設定（PH1 基本構成）**
   - Background Modes: Audio, Location updates。
   - Location: When In Use（必要なら Always を追加）。`Privacy - Location When In Use Usage Description` を Info.plist に記載。
   - Motion & Fitness: `Privacy - Motion Usage Description` を Info.plist に記載。

7. **ビルド設定**
   - iOS Deployment Target: 26.0。
   - Swift 言語バージョン: Swift 5.10 以上（Xcode 26 標準）。
   - Debug で `OTHER_SWIFT_FLAGS` に `-warnings-as-errors` を入れる場合はチーム方針に合わせる。

8. **ラン構成**
   - シミュレータ: iOS 26 以上のデバイスを選択。
   - 実機テスト: 開発者証明書とプロビジョニングを設定。Run で位置/モーション権限を許可。

9. **動作確認（初回）**
   - Build & Run でアプリ起動。
   - オンボーディング → 権限ガイド → メイン再生 UI が表示されることを確認（センサーは後でモック可）。

## ライブラリ管理のメモ
- 依存は Swift Package Manager に統一（Carthage/CocoaPods は使用しない）。
- ライブラリ追加時は README とこのドキュメントを更新し、ターゲット紐付けを明記。

## よくあるトラブル
- **Command line tools が旧バージョンを指している**: `sudo xcode-select --switch /Applications/Xcode.app`
- **Package resolve 失敗**: Xcode → File → Packages → Reset Package Caches。
- **権限ダイアログが出ない**: 実機でテストし、位置/モーションの Usage Description を Info.plist に入れる。
