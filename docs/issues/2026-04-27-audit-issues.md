# 2026-04-27 バグ/セキュリティ監査: Issue 起票案

このドキュメントは、コードベース調査で見つかった不具合・セキュリティ課題を、GitHub Issue としてそのまま起票できる形で整理したものです。

> 備考: この実行環境には `gh` CLI が存在しないため、リモートのGitHubリポジトリへ直接 Issue 作成は実行できませんでした。以下をコピーして起票してください。

---

## Issue 1: `comments.task_id` に外部キー制約がなく、孤児コメントが混入し得る

- **種別**: Security / Data Integrity
- **優先度**: High

### 背景
アプリケーション層ではコメント作成時に `task_exists?` を確認していますが、DB スキーマ上で `comments.task_id` に外部キー制約がありません。整合性は最終的に DB で担保されるべきで、アプリ層チェックだけではレース条件や運用ミス（直接SQL投入）を防げません。

### 根拠
- `comments` テーブルに `task_id` カラムは存在するが、`tasks` への外部キー定義がない。  
  （`accounts` への外部キーはあるため、片側だけ欠落している状態）

### 再現イメージ
1. 並行処理でコメント作成直前に対象 `task` が削除される。
2. DB 側制約がないため、`task_id` が実在しないコメント行が残る可能性がある。

### 改善案
- migration を追加して `comments.task_id -> tasks.id` の foreign key を付与。
- 既存データに孤児コメントがあればクレンジングしてから制約を有効化。

---

## Issue 2: `accounts.name` の一意制約が無く、同名アカウントを複数作成できる

- **種別**: Security / Authentication
- **優先度**: High

### 背景
ログイン処理は `Account.find_by(name: ...)` を使用しており、同名アカウントが複数あると「最初にヒットした1件」で認証が試行されます。これはアカウント識別の曖昧性につながり、運用上・監査上の重大な問題です。

### 根拠
- `accounts` テーブルに `name` ユニークインデックスがない。
- `Account` モデルに `validates :name, uniqueness: true` がない。
- ログイン処理が `find_by(name: ...)` で単一レコードを前提としている。

### 影響
- 同名ユーザーの作成でログイン挙動が不定。
- 監査ログ上で誰が失敗/成功したか判別しづらくなる。
- 組織運用で権限事故の温床になる。

### 改善案
- `accounts.name` にユニークインデックス追加。
- `Account` モデルに uniqueness バリデーション追加。
- 既存重複データ検出と解消手順を migration 前に用意。

---

## Issue 3: `AssignCycle` の `has_many :comments` がスキーマ不整合で実行時エラーを引き起こす

- **種別**: Bug
- **優先度**: Medium

### 背景
`AssignCycle` モデルに `has_many :comments` が定義されていますが、`comments` テーブルに `assign_cycle_id` は存在しません。関連をたどる処理が今後追加・実行されると SQL エラーの原因になります。

### 根拠
- `AssignCycle` モデルで `has_many :comments` を宣言。
- `comments` テーブル定義には `assign_cycle_id` が存在しない。

### 改善案
- 仕様が不要なら `has_many :comments` を削除。
- 仕様上必要なら migration で `comments.assign_cycle_id` を追加し、外部キー・index・関連定義を整合させる。

