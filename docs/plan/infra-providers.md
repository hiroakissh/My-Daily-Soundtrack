# Infra Provider 実装計画（PH2）

`docs/plan/roadmap.md` の `feature/infra-corelocation` / `feature/infra-coremotion` / `feature/infra-weather` を分割し、モック → 簡易実装 → 本実装の順で進める。

## feature/infra-corelocation
- [x] GeoTagProvider の CoreLocation 実装（既存）
- [ ] 位置権限の失敗時フォールバック戦略を整理（デフォルト GeoTag / UI 通知）
- [ ] 位置精度/距離フィルタの実測調整（屋外/屋内）
- [ ] 主要ジオフェンスの設定ファイル化（テスト/デバッグで差し替え）

## feature/infra-coremotion
- [x] CoreMotion ベースの MotionProvider（簡易実装）
- [ ] 活動判定のしきい値を調整（歩行/走行/停止の境界）
- [ ] 低頻度サンプリング時のケイデンス補間（欠損時の保持）
- [ ] モーション権限のハンドリング（権限 UI と統合）

## feature/infra-weather
- [x] WeatherKit を利用した WeatherProvider（簡易実装）
- [ ] 天気のフォールバック（API 失敗時のキャッシュ/推定値）
- [ ] 天気更新間隔の最適化（バッテリー vs 鮮度）
- [ ] WeatherKit 代替 API の検討（地域/権限の制約時）
