# バックエンド改善TODO

**作成日**: 2025年12月31日
**前回完了**: `/docs/done/DONE-2025-12-31.md`
**最終レビュー**: 2025年12月31日（総合レビュー実施）

---

## 進捗サマリー

| 優先度 | 総数 | 完了 | 残り |
|--------|------|------|------|
| Critical | 0 | 0 | 0 |
| High | 1 | 1 | 0 |
| Medium | 3 | 3 | 0 |
| Low | 4 | 0 | 4 |
| **合計** | **8** | **4** | **4** |

---

## Critical（即時対応必須）

なし

---

## High（今スプリント対応）

### セキュリティ

- [x] **SEC-H01**: レート制限の導入 ✅ PR #81
  - ファイル: `Gemfile`, `config/initializers/rack_attack.rb`（新規）, `spec/initializers/rack_attack_spec.rb`（新規）
  - 対応内容:
    - `rack-attack` gem導入
    - 全リクエスト: 300回/分（IPごと）
    - ログイン: 5回/分（ブルートフォース対策）
    - アカウント作成: 10回/時
    - ブロックIPリスト（環境変数設定可）
    - ヘルスチェック・開発環境は制限対象外
  - テスト: 13件追加（全1723件Pass）
  - 完了日: 2025-12-31

---

## Medium（次スプリント対応）

### セキュリティ

- [x] **SEC-M01**: 本番環境CORS設定の確認 ✅ 確認完了（コード変更不要）
  - ファイル: `config/initializers/cors.rb`
  - 確認結果:
    - ✅ `ALLOWED_ORIGINS`環境変数で許可オリジン制御
    - ✅ 本番環境で未設定/localhost時は起動失敗（フェイルセーフ）
    - ✅ ワイルドカード`*`未使用
    - ✅ 開発環境デフォルト: `http://localhost:3333`
  - 本番デプロイ時: `ALLOWED_ORIGINS=https://your-domain.com` を設定
  - 完了日: 2025-12-31

### コード品質

- [x] **LINT-M01**: db/schema.rb の RuboCop 警告修正 ✅ PR #82
  - ファイル: `.rubocop.yml`
  - 問題: `db/schema.rb` に `frozen_string_literal` コメントがない（自動生成ファイル）
  - 対応: `.rubocop.yml` で `db/schema.rb` を除外設定に追加
  - 完了日: 2025-12-31

### ドキュメント

- [x] **DOC-M01**: API仕様書の作成 ✅ PR #83
  - ファイル: `docs/api/README.md`（新規）
  - 対応: 全40エンドポイントのリクエスト/レスポンス形式、認証・認可要件、エラーコードを文書化
  - 内容:
    - エンドポイント一覧（Accounts, Tasks, Areas, Comments, Tags, Assigns, AccountAreas, TagAccounts, Authentications）
    - リクエスト/レスポンスJSON形式
    - 認証（JWT）・認可（admin_only, 担当者）要件
    - HTTPステータスコードとエラーレスポンス形式
    - レート制限仕様
  - 完了日: 2025-12-31

---

## Low（バックログ）

### パフォーマンス

- [ ] **PERF-L01**: N+1クエリ監視ツールの導入
  - ファイル: `Gemfile`, `config/environments/development.rb`
  - 問題: N+1クエリの検出が手動確認のみ
  - 対応: `bullet` gem導入、開発環境でN+1を自動検出
  - 備考: `Task.current_assignee?` は対策済み
  - 工数: 1h

### ログ改善

- [ ] **LOG-L01**: ログレベル統一基準の策定
  - ファイル: `docs/logging-guidelines.md`（新規）
  - 問題: `warn` / `error` の使い分け基準が明確でない
  - 対応: ログレベル使用ガイドラインを作成
  - 工数: 1h

### リファクタリング

- [ ] **REF-L01**: AssignCycle#deactivation の冗長な self 削除
  - ファイル: `app/models/assign_cycle.rb:36`
  - 問題: `self.update` の `self` が冗長
  - 対応: `update(is_active: false)` に変更
  - 工数: 0.5h

- [ ] **REF-L02**: AssignCycle.unfulfilleds のスコープ化
  - ファイル: `app/models/assign_cycle.rb:41-44`
  - 問題: クラスメソッドがシンプルなクエリのみで冗長
  - 対応: `scope :unfulfilleds, -> { where(is_active: true) }` に変更
  - 工数: 0.5h

---

## 備考

- **4層アーキテクチャ移行は100%完了**（40/40エンドポイント）
- **セキュリティ対策完了**: SEC-H01（レート制限）、SEC-M01（CORS設定確認）
- **RuboCop: 287ファイル、違反なし**（LINT-M01でdb/schema.rb除外設定追加）
- **API仕様書作成完了**: DOC-M01（`docs/api/README.md`）
- RSpec: 1723テスト全Pass
- Low優先度タスクは次スプリント以降で対応

---

## 課題の出典

| ID | 出典 | 優先度 | 状態 |
|----|------|--------|------|
| SEC-H01 | 総合レビュー 2025-12-31 | High | ✅ 完了 |
| SEC-M01 | 総合レビュー 2025-12-31 | Medium | ✅ 完了 |
| LINT-M01 | 総合レビュー 2025-12-31（RuboCop実行結果） | Medium | ✅ 完了 |
| DOC-M01 | 総合レビュー 2025-12-31 | Medium | ✅ 完了 |
| PERF-L01 | 総合レビュー 2025-12-31 | Low | 未着手 |
| LOG-L01 | 総合レビュー 2025-12-31 | Low | 未着手 |
| REF-L01, REF-L02 | 総合レビュー 2025-12-31（コードレビュー） | Low | 未着手 |

---

## 完了履歴

| 日付 | ID | タスク | PR |
|------|-----|--------|-----|
| 2025-12-31 | SEC-H01 | レート制限の導入（rack-attack） | #81 |
| 2025-12-31 | SEC-M01 | 本番環境CORS設定の確認 | - (確認のみ) |
| 2025-12-31 | LINT-M01 | db/schema.rb RuboCop除外設定 | #82 |
| 2025-12-31 | DOC-M01 | API仕様書の作成 | #83 |

---

## 過去の完了タスク

2025-12-31以前に完了したタスク（4層アーキテクチャ移行40件）は `/docs/done/DONE-2025-12-31.md` を参照。

---

## 総合評価（2025-12-31レビュー）

| カテゴリ | 評価 | 備考 |
|----------|------|------|
| アーキテクチャ | ⭐⭐⭐⭐⭐ | 4層アーキテクチャ100%完了 |
| セキュリティ | ⭐⭐⭐⭐⭐ | レート制限・CORS設定完了（SEC-H01, SEC-M01） |
| テスト品質 | ⭐⭐⭐⭐⭐ | 1723テスト全Pass |
| コード品質 | ⭐⭐⭐⭐⭐ | RuboCop 286ファイル違反なし（LINT-M01完了） |
| ドキュメント | ⭐⭐⭐⭐⭐ | API仕様書作成完了（DOC-M01） |

**総合**: ⭐⭐⭐⭐⭐ (5.0/5) - プロダクション対応可能な高品質バックエンド
