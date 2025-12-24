# 4層アーキテクチャ移行 TODO

## アーキテクチャ概要

```
Controller → Contract → Service → Repository → Model
                              ↘ Policy
                              ↘ Domain
```

各層の役割:
- **Contract** (`app/contracts/`): 入力検証 + データ変換
- **Service** (`app/services/`): ユースケース（トランザクション/副作用の統括）
- **Repository** (`app/services/*/repository.rb`): DBアクセス（Modelへの委譲）
- **Domain** (`app/domain/`): 純粋な業務ロジック（副作用なし）
- **Policy** (`app/policies/`): 認可ルール
- **Presenter** (`app/presenters/`): レスポンス整形

---

## 移行状況サマリー

| コントローラー | 移行済み | 未移行 | 進捗 |
|--------------|---------|-------|------|
| Accounts | 6/6 | 0 | ✅ 完了 |
| Authentications | 1/1 | 0 | ✅ 完了 |
| Tasks | 3/12 | 9 | 🔶 進行中 |
| Areas | 0/5 | 5 | ⬜ 未着手 |
| Comments | 0/5 | 5 | ⬜ 未着手 |
| Tags | 0/4 | 4 | ⬜ 未着手 |
| Assigns | 0/1 | 1 | ⬜ 未着手 |
| AccountAreas | 0/2 | 2 | ⬜ 未着手 |
| TagAccounts | 0/2 | 2 | ⬜ 未着手 |

**合計: 10/38 (26%)**

---

## Phase 1: Tasks コントローラー完了 (優先度: 高)

### 移行済み ✅
- [x] `GET /api/tasks` (index) - PR #62
- [x] `POST /api/tasks` (create) - PR #61
- [x] `GET /api/tasks/:id` (show)
  - Contract: `Contracts::Tasks::Show`
  - Service: `Services::Tasks::Show`
  - Repository: `find_by_id`追加
  - Presenter: `TaskPresenter.render_task`（既存）
  - 認証必須化

### 未移行
- [ ] `PUT /api/tasks/:id` (update)
  - Contract: `Contracts::Tasks::Update`
  - Service: `Services::Tasks::Update`
  - Repository: `update(task, attrs)`
  - Presenter: `TaskPresenter.render_task`（既存）

- [ ] `DELETE /api/tasks/:id` (destroy)
  - Contract: `Contracts::Tasks::Destroy`
  - Service: `Services::Tasks::Destroy`
  - Repository: `delete(task)`

- [ ] `POST /api/tasks/:id/tag` (add_tag)
  - Contract: `Contracts::Tasks::AddTag`
  - Service: `Services::Tasks::AddTag`
  - Presenter: `TagPresenter.render_tags`（新規）

- [ ] `DELETE /api/tasks/:id/tag` (remove_tag)
  - Contract: `Contracts::Tasks::RemoveTag`
  - Service: `Services::Tasks::RemoveTag`

- [ ] `PUT /api/tasks/:id/completed` (completed)
  - Contract: `Contracts::Tasks::Completed`
  - Service: `Services::Tasks::Completed`
  - Note: AssignHistory操作

- [ ] `PUT /api/tasks/:id/ng` (ng)
  - Contract: `Contracts::Tasks::Ng`
  - Service: `Services::Tasks::Ng`
  - Note: AssignHistory + AssignCycle.assign 呼び出し

- [ ] `POST /api/tasks/:id/newCycle` (create_new_cycle)
  - Contract: `Contracts::Tasks::CreateNewCycle`
  - Service: `Services::Tasks::CreateNewCycle`
  - Note: Task + AssignCycle操作

- [ ] `GET /api/unfulfilled-count` (unfulfilleds_count)
  - Service: `Services::Tasks::UnfulfilledsCount`
  - Note: Contractなし（パラメータなし）

- [ ] `GET /api/completed-data` (get_complete_data)
  - Service: `Services::Tasks::GetCompleteData`
  - Note: Contractなし（パラメータなし）

- [ ] `GET /api/account/tasks` (get_account_task)
  - Contract: `Contracts::Tasks::GetAccountTask`
  - Service: `Services::Tasks::GetAccountTask`

---

## Phase 2: Areas コントローラー (優先度: 中)

- [ ] `GET /api/areas` (index)
- [ ] `GET /api/areas/:id` (show)
- [ ] `POST /api/areas` (create)
- [ ] `PUT /api/areas/:id` (update)
- [ ] `DELETE /api/areas/:id` (destroy)

必要なファイル:
- `app/contracts/areas/` - create, show, update, destroy
- `app/services/areas/` - index, show, create, update, destroy, repository, result
- `app/presenters/area_presenter.rb`

---

## Phase 3: Comments コントローラー (優先度: 中)

- [ ] `GET /api/comments` (index)
- [ ] `GET /api/comments/:id` (show)
- [ ] `POST /api/comments` (create)
- [ ] `PUT /api/comments/:id` (update)
- [ ] `DELETE /api/comments/:id` (destroy)

必要なファイル:
- `app/contracts/comments/`
- `app/services/comments/`
- `app/presenters/comment_presenter.rb`

---

## Phase 4: Tags コントローラー (優先度: 低)

- [ ] `GET /api/tags` (index)
- [ ] `POST /api/tags` (create)
- [ ] `PUT /api/tags/:id` (update)
- [ ] `DELETE /api/tags/:id` (destroy)

必要なファイル:
- `app/contracts/tags/`
- `app/services/tags/`
- `app/presenters/tag_presenter.rb`

---

## Phase 5: 中間テーブル操作 (優先度: 低)

### Assigns
- [ ] `POST /api/tasks/assign/cycle` (cycle_create)

### AccountAreas
- [ ] `POST /api/account_areas` (create)
- [ ] `DELETE /api/account_areas/:id` (destroy)

### TagAccounts
- [ ] `POST /api/tag_accounts` (create)
- [ ] `DELETE /api/tag_accounts/:id` (destroy)

---

## 移行時の共通チェックリスト

### Contract作成時
- [ ] ActiveModel::Model を include
- [ ] 必須バリデーション (presence)
- [ ] 型バリデーション (inclusion, format)
- [ ] `self.call(params)` メソッドで Result を返す
- [ ] テスト: 正常系 + 異常系（空、nil、不正値）

### Service作成時
- [ ] Repository を DI で受け取る
- [ ] 認証チェック（必要な場合）
- [ ] Contract呼び出し
- [ ] Result オブジェクトで成功/失敗を返す
- [ ] テスト: 正常系 + 異常系 + DI検証

### Repository追加時
- [ ] Model への委譲のみ
- [ ] DB操作ロジックを含めない
- [ ] テスト: Model呼び出し確認

### Presenter追加/修正時
- [ ] フィールド名の統一（task_title等）
- [ ] 不要なフィールドを含めない
- [ ] テスト: 出力形式の確認

### Controller修正時
- [ ] `before_action :authenticated?` 追加
- [ ] `render_result` ブロックで Presenter 呼び出し
- [ ] private メソッドで params 整形
- [ ] テスト: HTTPステータス + レスポンス形式

---

## 既知の破壊的変更

| エンドポイント | 変更内容 | 対応PR |
|--------------|---------|-------|
| `GET /api/tasks` | 認証必須化、`title` → `task_title` | #62 |
| `POST /api/tasks` | 認証必須化、レスポンス形式変更 | #61 |
| `GET /api/tasks/:id` | 認証必須化、Presenter経由レスポンス | - |

---

## 参考: 既存の4層実装例

### Accounts CRUD
- `app/contracts/accounts/create.rb`
- `app/services/accounts/create.rb`
- `app/services/accounts/repository.rb`
- `app/presenters/account_presenter.rb`
- `app/policies/account_policy.rb`

### Authentications Login
- `app/contracts/authentications/login.rb`
- `app/services/authentications/login.rb`

### Tasks Index/Create
- `app/contracts/tasks/index.rb`, `create.rb`
- `app/services/tasks/index.rb`, `create.rb`
- `app/services/tasks/repository.rb`
- `app/presenters/task_presenter.rb`

---

## 関連ドキュメント

- `CLAUDE.md`: アーキテクチャ詳細、コーディング規約
- `ARCHITECTURE.md`: 設計思想（存在する場合）
