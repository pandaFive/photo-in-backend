# Photo-in Backend API仕様書

**作成日**: 2025年12月31日
**バージョン**: 1.0.0
**ベースURL**: `/api`

---

## 目次

1. [認証](#認証)
2. [共通仕様](#共通仕様)
3. [エンドポイント一覧](#エンドポイント一覧)
4. [Authentications API](#authentications-api)
5. [Accounts API](#accounts-api)
6. [Areas API](#areas-api)
7. [Tags API](#tags-api)
8. [Tasks API](#tasks-api)
9. [Comments API](#comments-api)
10. [Assigns API](#assigns-api)
11. [AccountAreas API](#accountareas-api)
12. [TagAccounts API](#tagaccounts-api)
13. [エラーレスポンス](#エラーレスポンス)
14. [レート制限](#レート制限)

---

## 認証

### JWT認証

本APIはJWT（JSON Web Token）による認証を使用します。

#### トークン取得

`POST /api/account/login` でトークンを取得します。

#### リクエストヘッダー

認証が必要なエンドポイントには以下のヘッダーを付与してください：

```
Authorization: Bearer <TOKEN>
```

#### トークン仕様

| 項目 | 値 |
|------|-----|
| アルゴリズム | HS256 |
| 有効期限 | 24時間 |

#### 認証エラー

| ステータス | 条件 |
|------------|------|
| 401 Unauthorized | トークンなし、無効、または期限切れ |

---

## 共通仕様

### リクエスト形式

- Content-Type: `application/json`
- 文字エンコーディング: UTF-8

### レスポンス形式

#### 成功時

```json
{
  "id": 1,
  "name": "example",
  ...
}
```

または配列：

```json
[
  { "id": 1, "name": "example1" },
  { "id": 2, "name": "example2" }
]
```

#### エラー時

```json
{
  "errors": ["エラーメッセージ"],
  "status": 400
}
```

### 日時形式

- ISO 8601形式（例: `2025-12-31T12:00:00.000+09:00`）

---

## エンドポイント一覧

### 認証不要

| メソッド | パス | 説明 |
|----------|------|------|
| POST | /api/account/login | ログイン |

### 認証必須（全ロール）

| メソッド | パス | 説明 |
|----------|------|------|
| GET | /api/account | 現在のアカウント取得 |
| GET | /api/account/tasks | 自分の担当タスク取得 |
| PUT | /api/tasks/:id/completed | タスク完了 |
| PUT | /api/tasks/:id/ng | タスクNG |
| GET | /api/comments | コメント一覧 |
| POST | /api/comments | コメント作成 |
| PUT | /api/comments/:id | コメント更新 |
| DELETE | /api/comments/:id | コメント削除 |

### 認証必須（全ロール）- 参照系

| メソッド | パス | 説明 |
|----------|------|------|
| GET | /api/areas | エリア一覧 |
| GET | /api/areas/:id | エリア詳細 |
| GET | /api/tags | タグ一覧 |
| GET | /api/tags/:id | タグ詳細 |
| GET | /api/tasks | タスク一覧 |
| GET | /api/tasks/:id | タスク詳細 |
| GET | /api/unfulfilled-count | 未完了タスク数 |
| GET | /api/completed-data | 完了データ取得 |

### 認証必須（管理者のみ）

| メソッド | パス | 説明 |
|----------|------|------|
| GET | /api/accounts | アカウント一覧 |
| POST | /api/accounts | アカウント作成 |
| GET | /api/accounts/:id | アカウント詳細 |
| PUT | /api/accounts/:id | アカウント更新 |
| DELETE | /api/accounts/:id | アカウント削除 |
| POST | /api/areas | エリア作成 |
| PUT | /api/areas/:id | エリア更新 |
| DELETE | /api/areas/:id | エリア削除 |
| POST | /api/tags | タグ作成 |
| PUT | /api/tags/:id | タグ更新 |
| DELETE | /api/tags/:id | タグ削除 |
| POST | /api/tasks | タスク作成 |
| PUT | /api/tasks/:id | タスク更新 |
| DELETE | /api/tasks/:id | タスク削除 |
| POST | /api/tasks/:id/tag | タスクにタグ追加 |
| DELETE | /api/tasks/:id/tag | タスクからタグ削除 |
| POST | /api/tasks/:id/newCycle | 新規サイクル作成 |
| POST | /api/tasks/assign/cycle | サイクル一括割り当て |
| POST | /api/account_areas | アカウント-エリア紐付け |
| DELETE | /api/account_areas/:id | アカウント-エリア紐付け解除 |
| POST | /api/tag_accounts | タグ-アカウント紐付け |
| DELETE | /api/tag_accounts/:id | タグ-アカウント紐付け解除 |

---

## Authentications API

### POST /api/account/login

ログイン認証を行い、JWTトークンを取得します。

#### リクエスト

```json
{
  "account": {
    "name": "string",
    "password": "string"
  }
}
```

| パラメータ | 型 | 必須 | 説明 |
|------------|-----|------|------|
| name | string | Yes | アカウント名 |
| password | string | Yes | パスワード |

#### レスポンス（200 OK）

```json
{
  "account": {
    "id": 1,
    "role": "admin",
    "token": "eyJhbGciOiJIUzI1NiJ9...",
    "name": "管理者"
  }
}
```

#### エラー

| ステータス | 条件 |
|------------|------|
| 401 Unauthorized | 認証失敗 |

---

## Accounts API

### GET /api/accounts

アカウント一覧を取得します。

**認可**: 管理者のみ

#### レスポンス（200 OK）

```json
[
  {
    "id": 1,
    "capacity": 10,
    "createdAt": "2025-12-31T12:00:00.000+09:00",
    "updatedAt": "2025-12-31T12:00:00.000+09:00",
    "name": "山田太郎",
    "area": ["東京", "大阪"],
    "total": 50,
    "week": 5,
    "ng_rate": 0.1,
    "assign": 3
  }
]
```

| フィールド | 型 | 説明 |
|------------|-----|------|
| id | integer | アカウントID |
| capacity | integer | 処理可能件数 |
| name | string | アカウント名 |
| area | array | 担当エリア名リスト |
| total | integer | 累計完了件数 |
| week | integer | 今週完了件数 |
| ng_rate | float | NG率（0.0〜1.0） |
| assign | integer | 現在の担当件数 |

---

### GET /api/account

現在ログイン中のアカウント情報を取得します。

**認可**: 全ロール

#### レスポンス（200 OK）

```json
{
  "id": 1,
  "createdAt": "2025-12-31T12:00:00.000+09:00",
  "capacity": 10,
  "updatedAt": "2025-12-31T12:00:00.000+09:00",
  "name": "山田太郎",
  "role": "member"
}
```

---

### GET /api/accounts/:id

指定IDのアカウント詳細を取得します。

**認可**: 管理者のみ

#### パスパラメータ

| パラメータ | 型 | 説明 |
|------------|-----|------|
| id | integer | アカウントID |

#### レスポンス（200 OK）

```json
{
  "id": 1,
  "createdAt": "2025-12-31T12:00:00.000+09:00",
  "capacity": 10,
  "updatedAt": "2025-12-31T12:00:00.000+09:00",
  "name": "山田太郎",
  "role": "member"
}
```

---

### POST /api/accounts

新規アカウントを作成します。

**認可**: 管理者のみ

#### リクエスト

```json
{
  "name": "新規ユーザー",
  "password": "password123",
  "role": "member",
  "capacity": 10,
  "area": [1, 2]
}
```

| パラメータ | 型 | 必須 | 説明 | 制約 |
|------------|-----|------|------|------|
| name | string | Yes | アカウント名 | 最大32文字 |
| password | string | Yes | パスワード | 最小8文字 |
| role | string | Yes | ロール | `admin` または `member` |
| capacity | integer | No | 処理可能件数 | 0以上 |
| area | array | No | 担当エリアIDリスト | - |

#### レスポンス（201 Created）

```json
{
  "id": 2,
  "createdAt": "2025-12-31T12:00:00.000+09:00",
  "capacity": 10,
  "updatedAt": "2025-12-31T12:00:00.000+09:00",
  "name": "新規ユーザー",
  "role": "member"
}
```

---

### PUT /api/accounts/:id

アカウント情報を更新します。

**認可**: 管理者のみ

#### リクエスト

```json
{
  "name": "更新後の名前",
  "capacity": 15
}
```

| パラメータ | 型 | 必須 | 説明 |
|------------|-----|------|------|
| name | string | No | アカウント名 |
| password | string | No | パスワード |
| role | string | No | ロール |
| capacity | integer | No | 処理可能件数 |

#### レスポンス（200 OK）

更新後のアカウント情報

---

### DELETE /api/accounts/:id

アカウントを削除します。

**認可**: 管理者のみ

#### レスポンス（204 No Content）

レスポンスボディなし

---

## Areas API

### GET /api/areas

エリア一覧を取得します。

**認可**: 全ロール

#### レスポンス（200 OK）

```json
[
  { "id": 1, "name": "東京" },
  { "id": 2, "name": "大阪" }
]
```

---

### GET /api/areas/:id

エリア詳細を取得します。

**認可**: 全ロール

#### レスポンス（200 OK）

```json
{ "id": 1, "name": "東京" }
```

---

### POST /api/areas

エリアを作成します。

**認可**: 管理者のみ

#### リクエスト

```json
{
  "area": {
    "name": "名古屋"
  }
}
```

| パラメータ | 型 | 必須 | 説明 | 制約 |
|------------|-----|------|------|------|
| area.name | string | Yes | エリア名 | 最大32文字 |

#### レスポンス（201 Created）

```json
{ "id": 3, "name": "名古屋" }
```

---

### PUT /api/areas/:id

エリアを更新します。

**認可**: 管理者のみ

#### リクエスト

```json
{
  "area": {
    "name": "愛知"
  }
}
```

#### レスポンス（200 OK）

更新後のエリア情報

---

### DELETE /api/areas/:id

エリアを削除します。

**認可**: 管理者のみ

#### レスポンス（204 No Content）

レスポンスボディなし

---

## Tags API

### GET /api/tags

タグ一覧を取得します。

**認可**: 全ロール

#### レスポンス（200 OK）

```json
[
  { "id": 1, "name": "緊急" },
  { "id": 2, "name": "優先" }
]
```

---

### GET /api/tags/:id

タグ詳細を取得します。

**認可**: 全ロール

#### レスポンス（200 OK）

```json
{ "id": 1, "name": "緊急" }
```

---

### POST /api/tags

タグを作成します。

**認可**: 管理者のみ

#### リクエスト

```json
{
  "tag": {
    "name": "重要"
  }
}
```

| パラメータ | 型 | 必須 | 説明 | 制約 |
|------------|-----|------|------|------|
| tag.name | string | Yes | タグ名 | 最大32文字 |

#### レスポンス（201 Created）

```json
{ "id": 3, "name": "重要" }
```

---

### PUT /api/tags/:id

タグを更新します。

**認可**: 管理者のみ

#### リクエスト

```json
{
  "tag": {
    "name": "最重要"
  }
}
```

#### レスポンス（200 OK）

更新後のタグ情報

---

### DELETE /api/tags/:id

タグを削除します。

**認可**: 管理者のみ

#### レスポンス（204 No Content）

レスポンスボディなし

---

## Tasks API

### GET /api/tasks

タスク一覧を取得します。

**認可**: 全ロール

#### レスポンス（200 OK）

```json
[
  {
    "id": 1,
    "task_title": "撮影タスク001",
    "area_id": 1,
    "area_name": "東京",
    "created_at": "2025-12-31T12:00:00.000+09:00",
    "updated_at": "2025-12-31T12:00:00.000+09:00"
  }
]
```

---

### GET /api/tasks/:id

タスク詳細を取得します。

**認可**: 全ロール

#### レスポンス（200 OK）

```json
{
  "id": 1,
  "task_title": "撮影タスク001",
  "area_id": 1,
  "area_name": "東京",
  "created_at": "2025-12-31T12:00:00.000+09:00",
  "updated_at": "2025-12-31T12:00:00.000+09:00"
}
```

---

### GET /api/account/tasks

現在のアカウントに割り当てられたタスクを取得します。

**認可**: 全ロール

#### クエリパラメータ

| パラメータ | 型 | 説明 |
|------------|-----|------|
| status | string | `active`（担当中）または `ng`（NG履歴） |

#### レスポンス（200 OK）

```json
[
  {
    "id": 1,
    "task_title": "撮影タスク001",
    "area_name": "東京",
    "assign_cycle_id": 5,
    "history_id": 10,
    "created_at": "2025-12-31T12:00:00.000+09:00"
  }
]
```

| フィールド | 型 | 説明 |
|------------|-----|------|
| id | integer | タスクID |
| task_title | string | タスクタイトル |
| area_name | string | エリア名 |
| assign_cycle_id | integer | 割り当てサイクルID |
| history_id | integer | 割り当て履歴ID（完了/NG操作に使用） |
| created_at | string | 作成日時 |

---

### POST /api/tasks

タスクを作成します。

**認可**: 管理者のみ

#### リクエスト

```json
{
  "task": {
    "task_title": "新規撮影タスク",
    "area_id": 1
  }
}
```

| パラメータ | 型 | 必須 | 説明 | 制約 |
|------------|-----|------|------|------|
| task.task_title | string | Yes | タスクタイトル | 最大256文字 |
| task.area_id | integer | No | エリアID | - |

#### レスポンス（201 Created）

作成されたタスク情報

---

### PUT /api/tasks/:id

タスクを更新します。

**認可**: 管理者のみ

#### リクエスト

```json
{
  "task": {
    "task_title": "更新後タイトル",
    "area_id": 2
  }
}
```

#### レスポンス（200 OK）

更新後のタスク情報

---

### DELETE /api/tasks/:id

タスクを削除します。

**認可**: 管理者のみ

#### レスポンス（204 No Content）

レスポンスボディなし

---

### PUT /api/tasks/:id/completed

タスクを完了としてマークします。

**認可**: 担当者本人または管理者

#### リクエスト

```json
{
  "history_id": 10
}
```

| パラメータ | 型 | 必須 | 説明 |
|------------|-----|------|------|
| history_id | integer | Yes | 割り当て履歴ID |

#### レスポンス（200 OK）

```json
{
  "message": "change completed",
  "result": true
}
```

---

### PUT /api/tasks/:id/ng

タスクをNGとしてマークします。

**認可**: 担当者本人または管理者

#### リクエスト

```json
{
  "history_id": 10
}
```

| パラメータ | 型 | 必須 | 説明 |
|------------|-----|------|------|
| history_id | integer | Yes | 割り当て履歴ID |

#### レスポンス（200 OK）

```json
{
  "message": "complete",
  "result": true
}
```

**備考**: `message` は再割り当て成功時 `"complete"`、再割り当て失敗時 `"failed"` となる

---

### POST /api/tasks/:id/tag

タスクにタグを追加します。

**認可**: 管理者のみ

#### リクエスト

```json
{ "tag_id": 1 }
```

#### レスポンス（200 OK）

タスクに紐付くタグ一覧

```json
[
  { "id": 1, "name": "緊急" }
]
```

---

### DELETE /api/tasks/:id/tag

タスクからタグを削除します。

**認可**: 管理者のみ

#### リクエスト

```json
{ "tag_id": 1 }
```

#### レスポンス（200 OK）

更新後のタグ一覧

---

### POST /api/tasks/:id/newCycle

新規割り当てサイクルを作成します。

**認可**: 管理者のみ

#### レスポンス（201 Created）

```json
{
  "id": 10,
  "task_id": 1,
  "is_active": true,
  "created_at": "2025-12-31T12:00:00.000+09:00",
  "updated_at": "2025-12-31T12:00:00.000+09:00"
}
```

---

### GET /api/unfulfilled-count

未完了（アクティブ）タスク数を取得します。

**認可**: 全ロール

#### レスポンス（200 OK）

```
15
```

**備考**: レスポンスは整数値のみ（JSONオブジェクトではない）

---

### GET /api/completed-data

完了データ統計を取得します。

**認可**: 全ロール

#### レスポンス（200 OK）

```json
{
  "total": 100,
  "week": 25,
  "today": 5
}
```

---

## Comments API

### GET /api/comments

コメント一覧を取得します。

**認可**: 全ロール

#### クエリパラメータ

| パラメータ | 型 | 説明 |
|------------|-----|------|
| taskId | integer | タスクIDでフィルタ |

#### レスポンス（200 OK）

```json
[
  {
    "id": 1,
    "content": "コメント内容",
    "task_id": 1,
    "account_id": 1,
    "account_name": "山田太郎",
    "account_role": "member",
    "updated_at": "2025-12-31T12:00:00Z"
  }
]
```

---

### GET /api/comments/:id

コメント詳細を取得します。

**認可**: 全ロール

#### レスポンス（200 OK）

単一コメント情報

---

### POST /api/comments

コメントを作成します。

**認可**: 全ロール

#### リクエスト

```json
{
  "content": "コメント内容",
  "task_id": 1
}
```

| パラメータ | 型 | 必須 | 説明 |
|------------|-----|------|------|
| content | string | Yes | コメント内容 |
| task_id | integer | Yes | 対象タスクID |

#### レスポンス（201 Created）

作成されたコメント情報

---

### PUT /api/comments/:id

コメントを更新します。

**認可**: コメント作成者本人または管理者

#### リクエスト

```json
{ "content": "更新後のコメント" }
```

#### レスポンス（200 OK）

更新後のコメント情報

---

### DELETE /api/comments/:id

コメントを削除します。

**認可**: コメント作成者本人または管理者

#### レスポンス（204 No Content）

レスポンスボディなし

---

## Assigns API

タスクの割り当て（アサイン）を管理するAPIです。

**備考**: 個別のアサインCRUD（GET/POST/PUT/DELETE /api/assigns）は現在未実装です。
割り当て操作は `POST /api/tasks/assign/cycle` および各タスクの `completed`/`ng` エンドポイントを使用してください。

---

### POST /api/tasks/assign/cycle

全アクティブタスクに対してサイクル割り当てを実行します。

**認可**: 管理者のみ

#### 割り当てアルゴリズム

1. 担当エリアが一致するアカウントのみ対象
2. 現在のサイクルでNG履歴があるアカウントは除外
3. 担当件数が `capacity * 4` 未満のアカウントのみ対象
4. 条件を満たすアカウントからランダムに選択

#### レスポンス（200 OK）

```json
{
  "id": 25,
  "task_id": 1,
  "is_active": true,
  "created_at": "2025-12-31T12:00:00.000+09:00",
  "updated_at": "2025-12-31T12:00:00.000+09:00"
}
```

| フィールド | 型 | 説明 |
|------------|-----|------|
| id | integer | サイクルID |
| task_id | integer | タスクID |
| is_active | boolean | アクティブ状態 |
| created_at | string | 作成日時 |
| updated_at | string | 更新日時 |

**備考**: サイクル割り当て実行後、作成/更新されたサイクル情報を返す

---

## AccountAreas API

### POST /api/account_areas

アカウントとエリアを紐付けます。

**認可**: 管理者のみ

#### リクエスト

```json
{
  "account_id": 1,
  "area_id": 2
}
```

#### レスポンス（201 Created）

紐付け情報

---

### DELETE /api/account_areas/:id

アカウントとエリアの紐付けを解除します。

**認可**: 管理者のみ

#### レスポンス（204 No Content）

レスポンスボディなし

---

## TagAccounts API

### POST /api/tag_accounts

タグとアカウントを紐付けます。

**認可**: 管理者のみ

#### リクエスト

```json
{
  "tag_id": 1,
  "account_id": 2
}
```

#### レスポンス（201 Created）

紐付け情報

---

### DELETE /api/tag_accounts/:id

タグとアカウントの紐付けを解除します。

**認可**: 管理者のみ

#### レスポンス（204 No Content）

レスポンスボディなし

---

## エラーレスポンス

### 共通エラー形式

```json
{
  "errors": ["エラーメッセージ1", "エラーメッセージ2"],
  "status": 400
}
```

### HTTPステータスコード

| コード | 意味 | 発生条件 |
|--------|------|----------|
| 400 Bad Request | 不正なリクエスト | パラメータ不足、バリデーションエラー |
| 401 Unauthorized | 認証エラー | トークンなし、無効、期限切れ |
| 403 Forbidden | 認可エラー | 権限不足 |
| 404 Not Found | リソースなし | 指定IDのリソースが存在しない |
| 409 Conflict | 競合 | 関連データが存在するため削除不可 |
| 422 Unprocessable Entity | 処理不可 | ビジネスルール違反 |
| 429 Too Many Requests | レート制限超過 | リクエスト頻度が高すぎる |
| 500 Internal Server Error | サーバーエラー | 予期しないエラー |
| 503 Service Unavailable | サービス利用不可 | DB接続エラー等 |

### バリデーションエラー例

```json
{
  "errors": [
    "Name can't be blank",
    "Password is too short (minimum is 8 characters)"
  ],
  "status": 422
}
```

---

## レート制限

DoS攻撃・ブルートフォース攻撃対策として、レート制限を実装しています。

### 制限ルール

| エンドポイント | 制限 | 期間 |
|---------------|------|------|
| 全リクエスト | 300回 | 1分 |
| POST /api/account/login | 5回 | 1分 |
| POST /api/accounts | 10回 | 1時間 |

### 制限超過時

```json
{
  "errors": ["リクエストが多すぎます。60秒後に再試行してください。"],
  "status": 429
}
```

レスポンスヘッダー：
```
Retry-After: 60
```

### 除外対象

- ヘルスチェック（`/health`）
- 開発環境のlocalhost

---

## 変更履歴

| 日付 | バージョン | 変更内容 |
|------|-----------|----------|
| 2025-12-31 | 1.0.0 | 初版作成 |
