---
name: my-daily-soundtrack
description: iOS アプリ「My Daily Soundtrack」用のスキル。位置/時間/天気/モーションに反応するサウンドトラックを作る SwiftUI/StateObservationKit コード、ドメインロジック、プロバイダ、テスト、設計ドキュメントを実装・更新するときに使う。
---

# My Daily Soundtrack

## 概要

位置・時間・天気・モーションに応じて音を変える iOS アプリ My Daily Soundtrack を構築・拡張するための手引き。PH1（GeoTag ベースの環境音再生）から PH2（コンテキスト集約、シーン判定、スコア計画、オープニング演出）まで対応。実装・リファクタ・テスト・ドキュメント更新時に利用。

## クイックリンクとセットアップ
- リポジトリ概要: README.md, project.yml（ターゲット/SPM 依存, iOS 26.0, Swift 6.0, StateObservationKit 0.1.0）。
- 仕様: docs/spec/spec-ph1.md（GeoTag MVP）, docs/spec/spec-ph2.md（フルパイプライン）。ロードマップ/ブランチ案: docs/plan/roadmap.md。
- デザイン（PH1 画面）: docs/design/ph1-screen-main.md, ph1-screen-onboarding.md, ph1-screen-permission.md, ph1-screen-error-modal.md, ph1-screen-debug-overlay.md。新規画面は docs/design/screen-spec-template.md を複製して作成。
- 環境: docs/setup/ios-environment.md。Capabilities: 位置情報（When In Use + 背景）, Motion & Fitness, Background Audio, WeatherKit を使うなら entitlement。
- 現在のコード: App/Sources/MyDailySoundtrackApp.swift（エントリ）, ContentView.swift（スターター UI）。推奨構成: Presentation / Domain / Infrastructure / Opening / Resources（README 参照）。

## 実装ガイド

### PH1 スナップショット（GeoTag MVP）
- 目的: 位置トリガーの環境音レイヤー。シーンモデルなし。`GeoTag` enum（station/park/cafe/river/forest/urban）を使用。
- プロバイダ/インフラ: `GeoTagProvider`（CoreLocation ラップ + 簡易ジオフェンス + ヒステリシス）、`AudioRenderer`（タグ→プリセット、pad/fx/fieldNoise、1–2 秒クロスフェード）。
- プレゼンテーション: フルスクリーン UI（GeoTag ラベル、再生/停止ボタン、パルスインジケータ）。開発用オーバーレイは任意。docs/design/ph1-screen-main.md ほか PH1 画面仕様を参照。
- テスト: GeoTag フィクスチャ → タグ判定、タグ変更時フェード、モックプロバイダでの UI プレビュー。

### PH2 スナップショット（フルパイプライン）
- コアサービス: `ContextAggregator`（Geo/Time/Weather/Motion を 10s ポーリング→デバウンスして `ContextSnapshot`）、`SceneClassifier`（ルールベース: ダブルヒット確定・60s ロック・フォールバック）、`ScorePlanner`（シーンデフォルト＋モーション連動のテンポ/レベル。トラック切替なし）、`AudioRenderer`（プランをスムーズ適用）、`OpeningDirector`（デイリーオープニング、時間/天気バケットから ThemeSeed 算出。完了までメイン UI をブロック）。
- モデル: `GeoTag`, `TimeBand`, `WeatherState`, `MotionState`, `SceneID`, `ContextSnapshot`, `ScorePlan`（pad/arp/beat/fx/fieldNoise, baseBPM, tempoFollowRate, filter/reverb）。
- シーン判定（優先順）: morning_intro（朝開始 30–60s）、commute_hurry（朝かつ station または cadence>110）、rainy_walk（rainy + walking）、cafe_stay（cafe + stopped ≥90s）、night_walk（night + park/urban + walking + cadence<100）、sunny_walk（sunny/cloudy + walking）、nature_ambient（forest/river/park またはアイドル時フォールバック）。センサー欠損時は直前シーンを保持。
- スコア挙動: cadence 上昇でシーン範囲内の BPM を持ち上げ、停止で beat をフェードダウンし pad/reverb を上げる、running で beat/arp を上限付きブースト、シーン切替は 1–2 小節クロスフェード、トラック差し替えなし。
- UI: ミニ HUD（シーンラベル、再生インジケータ、単一トグル）。デバッグオーバーレイは任意。

### 進め方
- 作業前に該当仕様/デザインを確認し、docs/plan/roadmap.md のブランチ名に合わせる。Domain/Infrastructure にプロトコルを置き、DI/モックを前提にする。
- SwiftPM 依存（`StateObservationKit`）は維持し、サービスを `@StateObservation` ストアで SwiftUI にバインド。
- センサー利用を足すときは Info.plist の Usage Description を更新し、iOS 26.0 / Swift 6.0 を守る。
- 新規画面は docs/design/screen-spec-template.md を複製し、メタ情報/フローを埋める。
- サービスはプロトコルファースト + App/Tests にモック実装。UI プレビューは決定的なモックシーケンスで。

### テストの目安
- PH1: GeoTagProvider のマッピング、タグ変更時のフェード、（あれば）再生ステートマシン。
- PH2: SceneClassifier のダブルヒット＋60s ロック、ScorePlanner の補間、モーション/天気/時間シナリオの統合テスト、OpeningDirector の ThemeSeed 持続。
- iOS ユニットテストは App/Tests 配下で決定的フィクスチャを使う。
