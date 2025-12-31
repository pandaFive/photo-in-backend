# ログレベル使用ガイドライン

**作成日**: 2025年12月31日
**対象**: photo-in-backend（Rails 7.1.3 API）

---

## 概要

本ドキュメントは、アプリケーション全体で一貫したログ出力を行うためのガイドラインを定める。
ログレベルの適切な使い分けにより、運用時の問題特定とデバッグ効率を向上させる。

---

## ログレベル一覧

| レベル | 用途 | 本番環境での出力 |
|--------|------|------------------|
| `debug` | 開発・デバッグ用の詳細情報 | OFF |
| `info` | 正常な業務イベント | ON |
| `warn` | 想定内の異常（リカバリ可能） | ON |
| `error` | システムエラー（即時対応が必要な可能性） | ON |
| `fatal` | 致命的エラー（システム停止レベル） | ON |

---

## 各レベルの詳細

### debug

**用途**: 開発時のトレース・デバッグ情報

**使用場面**:
- Repository層のクエリ実行トレース
- 中間状態の確認（処理件数など）
- 開発時のみ必要な詳細情報

**例**:
```ruby
# Repository操作のトレース
Rails.logger.debug "Repository: find_by_id id=#{id}"
Rails.logger.debug "Repository: save result=#{result}"

# 処理件数の確認
Rails.logger.debug "Deactivated #{deactivated_count} cycles for task_id=#{task.id}"
```

**注意**: 本番環境では出力されないが、開発環境でも機密情報（パスワード、APIキー、トークン等）は含めないこと。ログファイルが意図せず共有される可能性があるため。

---

### info

**用途**: 正常な業務イベントの記録

**使用場面**:
- リソースの作成・更新・削除の成功
- 重要な業務処理の完了（タスク完了、割り当て成功など）
- 監査ログとして必要な操作

**例**:
```ruby
# リソース作成
Rails.logger.info "Account created: id=#{account.id}, name=#{account.name}, role=#{account.role}, by_account=#{current_account.id}"

# リソース更新
Rails.logger.info "Area updated: id=#{area.id}, by_account=#{current_account.id}"

# リソース削除
Rails.logger.info "Task destroyed: id=#{task.id}, title=#{task.task_title}, by_account=#{current_account.id}"

# 業務処理完了
Rails.logger.info "Task completed: assign_history_id=#{assign_history.id}, task_id=#{task.id}, by_account=#{current_account.id}"

# 割り当て成功
Rails.logger.info "Cycle created: task_id=#{task.id}, cycle_id=#{cycle.id}, by_account=#{current_account.id}, assignee_id=#{assign_result.account_id}"
```

**必須項目**:
- 対象リソースのID
- 操作を実行したアカウントID（`by_account=`）
- リソース識別に必要な情報（name, titleなど）

---

### warn

**用途**: 想定内の異常・リカバリ可能なエラー

**使用場面**:
- バリデーションエラー（不正な入力）
- 認可エラー（権限不足）
- リソース未検出（存在しないIDへのアクセス）
- ビジネスルール違反（既存タグの重複追加など）
- 割り当て失敗（対象アカウントなし）
- レースコンディションのグレースフルハンドリング

**例**:
```ruby
# バリデーションエラー
Rails.logger.warn "Account create validation failed: #{validation.errors.join(', ')}"

# 認可エラー
Rails.logger.warn "Area destroy unauthorized: account_id=#{current_account.id}, role=#{current_account.role}"

# リソース未検出
Rails.logger.warn "Task not found for cycle create: task_id=#{task_id}, by_account=#{current_account.id}"

# ビジネスルール違反
Rails.logger.warn "Tag already exists for account: account_id=#{account_id}, tag_id=#{tag_id}"

# 割り当て失敗
Rails.logger.warn "Cycle created but assignment failed: task_id=#{task.id}, cycle_id=#{cycle.id}, no_eligible_accounts=true"

# レースコンディション（ハンドル済み）
Rails.logger.warn "TagAccount add_tag race condition: account_id=#{account.id}, tag_id=#{tag.id}, error=#{e.message}"

# nilチェック（想定外だが致命的ではない）
Rails.logger.warn "CommentPresenter: comment id=#{comment.id} has nil account (orphaned)"
```

**判断基準**:
- ユーザーの誤操作や不正リクエストが原因
- システム側の対応は不要（ログ監視のみ）
- 同じエラーが大量発生した場合のみ調査対象

---

### error

**用途**: システムエラー・即時対応が必要な可能性のある問題

**使用場面**:
- データベース接続エラー
- デッドロック・ロックタイムアウト
- 外部キー制約違反
- 予期しない状態（作成直後のレコード消失など）
- 保存失敗（コールバックエラー等）

**例**:
```ruby
# データベースエラー
Rails.logger.error "Area create DB error: #{e.message}"

# ロックエラー
Rails.logger.error "Task complete lock error: id=#{params[:id]}, error=#{e.message}"

# 外部キー制約違反
Rails.logger.error "Account destroy failed (FK constraint): id=#{account_id}, error=#{e.message}"

# 予期しない状態
Rails.logger.error "Comment vanished after creation: id=#{saved_id}, task_id=#{task_id}, by_account=#{current_account.id}"

# サービス実行エラー（Controller層）
Rails.logger.error "#{error.class}: #{error.message}"
Rails.logger.error error.backtrace.join("\n")
```

**必須項目**:
- エラーメッセージ（`e.message`）
- 対象リソースのID
- 可能であればスタックトレース

**対応**: 本番環境でerrorログが発生した場合は、監視アラートを検討すること。

---

### fatal

**用途**: 致命的エラー（システム停止レベル）

**使用場面**:
- アプリケーション起動失敗
- 必須サービスへの接続不可
- データ整合性の破壊

**例**:
```ruby
Rails.logger.fatal "Database connection failed: #{e.message}"
Rails.logger.fatal "Required environment variable missing: SECRET_KEY_BASE"
```

**対応**: 即時対応必須。PagerDuty等での通知を推奨。

---

## フォーマット規約

### 基本フォーマット

```ruby
Rails.logger.{level} "{操作}: {詳細情報}"
```

### キー=バリュー形式

ログ解析ツール（Datadog, CloudWatch Logs Insightsなど）での検索を容易にするため、構造化フォーマットを推奨:

```ruby
# 推奨
Rails.logger.info "Account created: id=#{account.id}, name=#{account.name}, by_account=#{current_account.id}"

# 非推奨（検索しづらい）
Rails.logger.info "Created account #{account.name} with id #{account.id}"
```

### 構造化ログ（ハッシュ形式）

複雑な情報を記録する場合:

```ruby
Rails.logger.warn(
  message: "UnfulfilledsCount failed",
  errors: result.errors,
  account_id: @current_account&.id
)
```

---

## 禁止事項

### 機密情報の出力禁止

以下は絶対にログに出力しないこと:

- パスワード（平文・ハッシュ含む）
- APIキー・シークレット
- JWTトークン
- 個人情報（メールアドレス、電話番号等）

```ruby
# NG
Rails.logger.info "Login attempt: email=#{email}, password=#{password}"
Rails.logger.debug "JWT token: #{token}"

# OK
Rails.logger.info "Login attempt: account_id=#{account.id}"
Rails.logger.debug "JWT token generated for account_id=#{account.id}"
```

### 過剰なログ出力

ループ内での大量ログ出力は避ける:

```ruby
# NG（N件のログが出力される）
accounts.each do |account|
  Rails.logger.debug "Processing account: #{account.id}"
end

# OK（1件のサマリログ）
Rails.logger.debug "Processing #{accounts.size} accounts"
```

---

## レベル選択フローチャート

```
エラーが発生したか？
├─ No → 正常な業務イベントか？
│        ├─ Yes → info
│        └─ No → debug（開発用トレース）
│
└─ Yes → システムがリカバリ可能か？
          ├─ Yes → ユーザー起因か？
          │        ├─ Yes → warn（バリデーション、認可、not found）
          │        └─ No → warn（レースコンディション等）
          │
          └─ No → システム停止レベルか？
                   ├─ Yes → fatal
                   └─ No → error（DB接続、ロック、予期しない状態）
```

---

## 本番環境設定

`config/environments/production.rb`:

```ruby
# STDOUTへのログ出力（コンテナ環境向け）
config.logger = ActiveSupport::Logger.new(STDOUT)
  .tap  { |logger| logger.formatter = ::Logger::Formatter.new }
  .then { |logger| ActiveSupport::TaggedLogging.new(logger) }

# リクエストIDをログに付与（トレーサビリティ向上）
config.log_tags = [ :request_id ]

# ログレベル（環境変数で上書き可能、デフォルト: info）
config.log_level = ENV.fetch("RAILS_LOG_LEVEL", "info")
```

**ポイント**:
- `TaggedLogging`: 各ログ行に`request_id`が付与され、リクエスト単位でのログ追跡が可能
- `RAILS_LOG_LEVEL`: 環境変数でログレベルを動的に変更可能（デバッグ時に`debug`に設定など）
- `STDOUT`: コンテナ環境（ECS等）ではSTDOUTへの出力が標準

---

## 参考: 現在の使用状況

| レベル | 使用箇所数 | 主な用途 |
|--------|------------|----------|
| debug | 24箇所 | Repository層トレース |
| info | 26箇所 | 成功した業務操作 |
| warn | 83箇所 | バリデーション、認可、not found |
| error | 67箇所 | DB接続、ロック、予期しない状態 |
| fatal | 0箇所 | 未使用（必要に応じて追加） |

※ 2025年12月31日時点の`app/`ディレクトリ内の使用数

---

## 変更履歴

| 日付 | 変更内容 |
|------|----------|
| 2025-12-31 | 初版作成（LOG-L01） |
