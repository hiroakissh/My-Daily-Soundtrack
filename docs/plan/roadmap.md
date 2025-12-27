# 開発プラン（ブランチ単位で細分化）
各行をそのままコピペしてブランチ名にできます。1 タスク = 1 ブランチを想定。

## PH1 UI/体験
- `feature/ph1-onboarding-ui` … オンボーディング画面実装（静的文言＋ページング、OnboardingStore ステートマシン）
- `feature/ph1-permission-guide` … 権限ガイド画面（位置/モーションの許諾誘導、PermissionStore ステートマシン）
- `feature/ph1-main-playback-ui` … メイン再生 UI（GeoTag 表示、再生/停止、PlaybackStore ステートマシンの UI バインド）
- `feature/ph1-error-modal` … エラー/リトライモーダル（ErrorStore バインド、リトライ動線）
- `feature/ph1-debug-overlay` … デバッグオーバーレイ（開発ビルドのみ、Context/Scene/Playback の表示とモック切替）

## PH1 ドメイン/インフラ
- `feature/ph1-geotag-provider` … GeoTagProvider プロトコル + 仮実装（モックと簡易ジオフェンス）
- `feature/ph1-audio-renderer-stub` … AudioRenderer スタブ（タグごとのプリセット適用、フェード処理のみ）

## PH2 コアロジック
- `feature/ph2-context-aggregator` … ContextAggregator 実装（Geo/Time/Weather/Motion を 10 秒周期で集約）
- `feature/ph2-scene-classifier` … SceneClassifier ルールベース実装（ダブルヒット確定、60 秒保持）
- `feature/ph2-score-planner` … ScorePlanner 実装（シーン別デフォルトとモーション連動補間）
- `feature/ph2-opening-director` … OpeningDirector（起動時テーマ決定と演出フロー）

## センサー・API 実装
- `feature/infra-corelocation` … CoreLocation 実装（権限ハンドリング、簡易タグ算出への接続）
- `feature/infra-coremotion` … CoreMotion 実装（歩行/走行判定、ケイデンス算出）
- `feature/infra-weather` … WeatherKit または外部 API クライアントの実装（最初はモック可）

## オーディオ/ビジュアル
- `feature/audio-engine-setup` … AVAudioEngine ベースのミキサー/レイヤー構成、常駐レイヤーとフェード
- `feature/visual-openingscene` … オープニングタイトルのビジュアル実装（抽象アニメ＋テーマシード連動）

## テスト/CI
- `feature/tests-scene-score` … SceneClassifier/ScorePlanner のユニットテスト追加（フィクスチャ中心）
- `feature/ci-fastlane` … CI ワークフロー/fastlane 設定（ビルド＋テスト、SPM キャッシュ）
