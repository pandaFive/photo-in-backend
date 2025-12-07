# Photo-in Backend

撮影タスク自動割り振りアプリケーションのバックエンドAPI

## 技術スタック

- **Framework**: [Ruby on Rails 7.1.3](https://rubyonrails.org/)
- **Language**: Ruby 3.3.0
- **Database**: PostgreSQL
- **Authentication**: JWT (JSON Web Token) with bcrypt
- **Testing**: RSpec, Factory Bot, SimpleCov
- **Code Quality**: RuboCop, Solargraph
- **Web Server**: Puma
- **Containerization**: Docker, Docker Compose

## プロジェクト構造

```
app/
├── controllers/
│   ├── api/
│   │   ├── accounts_controller.rb      # アカウント管理
│   │   ├── areas_controller.rb         # エリア管理
│   │   ├── assigns_controller.rb       # タスク割り当て
│   │   ├── authentications_controller.rb # 認証（ログイン）
│   │   ├── comments_controller.rb      # コメント管理
│   │   ├── tags_controller.rb          # タグ管理
│   │   ├── tasks_controller.rb         # タスク管理
│   │   ├── account_areas_controller.rb # アカウント-エリア関連
│   │   └── tag_accounts_controller.rb  # タグ-アカウント関連
│   ├── concerns/
│   │   └── json_web_token.rb          # JWT認証モジュール
│   ├── application_controller.rb      # 基底コントローラー
│   └── health_controller.rb           # ヘルスチェック
├── models/
│   ├── account.rb                     # アカウントモデル
│   ├── area.rb                        # エリアモデル
│   ├── assign_cycle.rb                # 割り当てサイクル
│   ├── assign_history.rb              # 割り当て履歴
│   ├── comment.rb                     # コメントモデル
│   ├── tag.rb                         # タグモデル
│   ├── task.rb                        # タスクモデル
│   ├── account_area.rb                # アカウント-エリア中間テーブル
│   ├── tag_account.rb                 # タグ-アカウント中間テーブル
│   └── tag_task.rb                    # タグ-タスク中間テーブル
config/
├── routes.rb                          # ルーティング定義
├── database.yml                       # データベース設定
└── application.rb                     # アプリケーション設定
spec/
├── models/                            # モデルテスト
├── controllers/                       # コントローラーテスト
├── factories/                         # Factory Bot定義
└── rails_helper.rb                    # RSpec設定
```

## データベーススキーマ

### 主要テーブル

- **accounts**: ユーザーアカウント（admin/member）
- **areas**: 撮影エリア
- **tasks**: 撮影タスク
- **tags**: タスク分類用タグ
- **comments**: タスクへのコメント
- **assign_cycles**: タスク割り当てサイクル
- **assign_histories**: タスク割り当て履歴

### 中間テーブル

- **account_areas**: アカウントと撮影可能エリアの関連
- **tag_accounts**: タグとアカウントの関連
- **tag_tasks**: タグとタスクの関連

## セットアップ

### 前提条件

- Ruby 3.3.0
- PostgreSQL 13以上
- Docker & Docker Compose（推奨）

### インストール（Dockerを使用）

```bash
# イメージのビルド
docker-compose build

# データベースの作成とマイグレーション
docker-compose run web rails db:create
docker-compose run web rails db:migrate
docker-compose run web rails db:seed

# サーバー起動
docker-compose up
```

### インストール（ローカル環境）

```bash
# 依存関係のインストール
bundle install

# データベースの設定
# config/database.ymlを環境に合わせて編集

# データベースの作成とマイグレーション
rails db:create
rails db:migrate
rails db:seed

# サーバー起動
rails server
```

### 環境変数

本番環境では以下の環境変数を設定してください：

```env
# データベース設定
DATABASE=your_database_name
DATABASE_HOST=your_database_host
DATABASE_USER=your_database_user
DATABASE_PASSWORD=your_database_password

# JWT設定（application_controller.rbで使用）
SECRET_KEY_BASE=your_secret_key_base

# Rails環境
RAILS_ENV=production
```

## API エンドポイント

### 認証

| メソッド | エンドポイント | 説明 | 認証 |
|---------|--------------|------|-----|
| POST | `/api/account/login` | ログイン（JWT取得） | 不要 |

### アカウント管理

| メソッド | エンドポイント | 説明 | 認証 |
|---------|--------------|------|-----|
| GET | `/api/accounts` | 全アカウント一覧 | 必要 |
| GET | `/api/accounts/:id` | アカウント詳細 | 必要 |
| GET | `/api/account` | 現在のアカウント情報 | 必要 |
| POST | `/api/accounts` | アカウント作成 | 必要（admin） |
| PUT | `/api/accounts/:id` | アカウント更新 | 必要（admin） |
| DELETE | `/api/accounts/:id` | アカウント削除 | 必要（admin） |

### タスク管理

| メソッド | エンドポイント | 説明 | 認証 |
|---------|--------------|------|-----|
| GET | `/api/tasks` | 全タスク一覧 | 必要 |
| GET | `/api/tasks/:id` | タスク詳細 | 必要 |
| GET | `/api/account/tasks` | 自分のタスク一覧 | 必要 |
| POST | `/api/tasks` | タスク作成 | 必要（admin） |
| PUT | `/api/tasks/:id` | タスク更新 | 必要 |
| DELETE | `/api/tasks/:id` | タスク削除 | 必要（admin） |
| PUT | `/api/tasks/:id/completed` | タスク完了 | 必要 |
| PUT | `/api/tasks/:id/ng` | タスクNG登録 | 必要 |
| POST | `/api/tasks/:id/newCycle` | 新しい割り当てサイクル作成 | 必要（admin） |
| POST | `/api/tasks/:id/tag` | タグ追加 | 必要 |
| DELETE | `/api/tasks/:id/tag` | タグ削除 | 必要 |
| GET | `/api/unfulfilled-count` | 未完了タスク数 | 必要 |
| GET | `/api/completed-data` | 完了タスクデータ | 必要 |

### エリア管理

| メソッド | エンドポイント | 説明 | 認証 |
|---------|--------------|------|-----|
| GET | `/api/areas` | 全エリア一覧 | 必要 |
| POST | `/api/areas` | エリア作成 | 必要（admin） |
| PUT | `/api/areas/:id` | エリア更新 | 必要（admin） |
| DELETE | `/api/areas/:id` | エリア削除 | 必要（admin） |

### コメント

| メソッド | エンドポイント | 説明 | 認証 |
|---------|--------------|------|-----|
| GET | `/api/comments` | コメント一覧 | 必要 |
| POST | `/api/comments` | コメント作成 | 必要 |
| PUT | `/api/comments/:id` | コメント更新 | 必要 |
| DELETE | `/api/comments/:id` | コメント削除 | 必要 |

### タスク割り当て

| メソッド | エンドポイント | 説明 | 認証 |
|---------|--------------|------|-----|
| POST | `/api/tasks/assign/cycle` | サイクル割り当て実行 | 必要（admin） |

### ヘルスチェック

| メソッド | エンドポイント | 説明 | 認証 |
|---------|--------------|------|-----|
| GET | `/health` | ヘルスチェック | 不要 |

## 認証フロー

### JWT認証

1. クライアントが `/api/account/login` にメールアドレスとパスワードを送信
2. サーバーが認証情報を検証し、成功時にJWTトークンを返却（有効期限24時間）
3. クライアントは以降のリクエストでAuthorizationヘッダーにトークンを含める
4. サーバーは各リクエストでトークンを検証（`authorize_request`）

```ruby
# ヘッダー形式
Authorization: Bearer <JWT_TOKEN>
```

### トークンの構造

```ruby
# app/controllers/concerns/json_web_token.rb
def encode(payload, exp = 24.hours.from_now)
  payload[:exp] = exp.to_i
  token = JWT.encode(payload, SECRET_KEY)
end
```

## テスト

### テストの実行

```bash
# 全テスト実行
bundle exec rspec

# 特定のファイルのテスト実行
bundle exec rspec spec/models/account_spec.rb

# カバレッジレポート生成（SimpleCov）
bundle exec rspec
# coverage/index.htmlを開く
```

### テスト構成

- **モデルテスト**: バリデーション、アソシエーション、メソッドの動作確認
- **コントローラーテスト**: API エンドポイントのレスポンス確認
- **Factory Bot**: テストデータの生成

主要なテスト対象：
- Account モデル（バリデーション、パスワード暗号化）
- Task モデル（ステータス管理、割り当てロジック）
- Area モデル（エリア管理）
- AssignCycle モデル（割り当てアルゴリズム）
- Authentications コントローラー（ログイン認証）

## コード品質

### リファクタリング実施内容

1. **セキュリティ強化**
   - JWT有効期限の実装（24時間）
   - スタックトレース露出の防止
   - パスワード検証の強化

2. **エラーハンドリングの統一**
   - 統一されたエラーレスポンス形式
   - 適切なHTTPステータスコード
   - ログ出力の改善

3. **コードの整理**
   - タイポ修正（Accout→Account、unuthorized→unauthorized）
   - デバッグコード削除（puts文）
   - テストコード削除（completed_test）
   - マジックナンバーの定数化（CAPACITY_MULTIPLIER）

4. **モデルの改善**
   - 重複コードの削除（Task/Areaモデル）
   - ゼロ除算対策の改善
   - 命名規則の統一（snake_case）

### RuboCop

```bash
# コードスタイルチェック
bundle exec rubocop

# 自動修正
bundle exec rubocop -a
```

## デプロイ

### AWS ECS Fargate

このプロジェクトはAWS ECS Fargateを使用したコンテナデプロイに対応しています。

#### 必要なAWSリソース

- **ECS Cluster**: Fargateクラスター
- **ECR**: Dockerイメージレポジトリ
- **RDS**: PostgreSQLデータベース
- **ALB**: Application Load Balancer
- **Route53**: DNSルーティング

#### デプロイ手順

```bash
# Dockerイメージのビルド
docker build -t photo-in-backend .

# ECRへのプッシュ
aws ecr get-login-password --region ap-northeast-1 | docker login --username AWS --password-stdin <ECR_URI>
docker tag photo-in-backend:latest <ECR_URI>/photo-in-backend:latest
docker push <ECR_URI>/photo-in-backend:latest

# ECSタスク定義の更新とサービスデプロイはAWS Console or AWS CLIで実行
```

## パフォーマンス最適化

### 実施済みの最適化

1. **データベースクエリ**
   - N+1クエリの防止（includes/joins使用）
   - インデックスの適切な設定

2. **アルゴリズム最適化**
   - AssignCycleモデルの割り当てロジック最適化
   - 定数化によるパフォーマンス改善

3. **キャッシング**
   - フロントエンド側でNext.js revalidateを使用

## トラブルシューティング

### データベース接続エラー

```bash
# Dockerの場合
docker-compose down
docker-compose up -d db
docker-compose run web rails db:migrate

# ローカルの場合
# PostgreSQLサービスの起動を確認
sudo service postgresql start
```

### マイグレーションエラー

```bash
# マイグレーションのロールバック
rails db:rollback

# マイグレーションのリセット（開発環境のみ）
rails db:reset
```

## 貢献

1. 新機能追加時はRSpecテストを追加してください
2. コミット前に `bundle exec rubocop` を実行してください
3. モデルのメソッドには適切なコメントを追加してください
4. APIエンドポイント追加時は本READMEも更新してください

## ライセンス

このプロジェクトはプライベートプロジェクトです。

## 関連リンク

- [Ruby on Rails Guides](https://guides.rubyonrails.org/)
- [RSpec Documentation](https://rspec.info/documentation/)
- [PostgreSQL Documentation](https://www.postgresql.org/docs/)
- フロントエンドリポジトリ: `photo-in-frontend`
