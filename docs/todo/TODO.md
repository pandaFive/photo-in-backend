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
| Tasks | 13/13 | 0 | ✅ 完了 |
| Areas | 5/5 | 0 | ✅ 完了 |
| Comments | 5/5 | 0 | ✅ 完了 |
| Tags | 5/5 | 0 | ✅ 完了 |
| Assigns | 1/1 | 0 | ✅ 完了 |
| AccountAreas | 0/2 | 2 | ⬜ 未着手 |
| TagAccounts | 0/2 | 2 | ⬜ 未着手 |

**合計: 36/40 (90%)**

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
- [x] `PUT /api/tasks/:id` (update)
  - Contract: `Contracts::Tasks::Update`
  - Service: `Services::Tasks::Update`
  - Repository: `update(task, attrs)`追加
  - Presenter: `TaskPresenter.render_task`（既存）
  - Model: `Task#current_assignee?`追加
  - 認証必須化、認可追加（admin + 担当者）
- [x] `DELETE /api/tasks/:id` (destroy)
  - Contract: `Contracts::Tasks::Destroy`
  - Service: `Services::Tasks::Destroy`
  - Repository: `delete(task)`追加
  - 認証必須化、認可追加（admin_only）

- [x] `POST /api/tasks/:id/tag` (add_tag)
  - Contract: `Contracts::Tasks::AddTag`
  - Service: `Services::Tasks::AddTag`
  - Repository: `find_tag`, `add_tag`追加
  - Presenter: `TaskPresenter.render_tags`（新規）
  - 認証必須化、認可追加（admin_only）
- [x] `DELETE /api/tasks/:id/tag` (remove_tag)
  - Contract: `Contracts::Tasks::RemoveTag`
  - Service: `Services::Tasks::RemoveTag`
  - Repository: `remove_tag`追加
  - 認証必須化、認可追加（admin_only）
- [x] `PUT /api/tasks/:id/completed` (completed)
  - Contract: `Contracts::Tasks::Completed`
  - Service: `Services::Tasks::Completed`
  - Repository: `find_assign_history_with_lock`, `complete_assign_history`, `deactivate_cycle`追加
  - 認証必須化、認可追加（admin + 担当者）
- [x] `PUT /api/tasks/:id/ng` (ng)
  - Contract: `Contracts::Tasks::Ng`
  - Service: `Services::Tasks::Ng`
  - Repository: `mark_ng`追加
  - 認証必須化、認可追加（admin + 担当者）
  - Note: NGマーク後にAssignCycle.assign で再割り当て実行
- [x] `POST /api/tasks/:id/newCycle` (create_new_cycle)
  - Contract: `Contracts::Tasks::CreateNewCycle`
  - Service: `Services::Tasks::CreateNewCycle`
  - Repository: `deactivate_all_cycles`, `create_cycle`追加
  - Presenter: `TaskPresenter.render_task`（既存）
  - 認証必須化、認可追加（admin_only）

- [x] `GET /api/unfulfilled-count` (unfulfilleds_count)
  - Service: `Services::Tasks::UnfulfilledsCount`
  - Repository: `count_unfulfilleds`追加
  - Note: Contractなし（パラメータなし）
  - 認証必須化

- [x] `GET /api/completed-data` (get_complete_data)
  - Service: `Services::Tasks::GetCompleteData`
  - Repository: `get_completed_past_week`追加
  - Note: Contractなし（パラメータなし）
  - 認証必須化
  - DBエラーハンドリング追加

- [x] `GET /api/account/tasks` (get_account_task)
  - Contract: `Contracts::Tasks::GetAccountTask`
  - Service: `Services::Tasks::GetAccountTask`
  - Repository: `get_account_assign_tasks`追加
  - Presenter: `TaskPresenter.render_account_assign_tasks`（新規）
  - 認証必須化、認可追加（admin + 自分のみ）
  - Note: `title` → `task_title` に変更（破壊的変更）

### リファクタリング完了 ✅
- [x] Result Struct 統合 - PR #73
  - 6つの個別Result Structを`Services::Tasks::Result`に統合
  - 削除: DestroyResult, CompletedResult, NgResult, CreateNewCycleResult, UnfulfilledsCountResult, GetCompleteDataResult
  - 統合フィールド: success?, task, tasks, message, count, data, errors, status

---

## Phase 2: Areas コントローラー完了 (優先度: 中)

### 移行済み ✅ - PR #75
- [x] `GET /api/areas` (index)
  - Service: `Services::Areas::Index`
  - Repository: `all_areas`
  - Presenter: `AreaPresenter.render_areas`
  - 認証必須化
- [x] `GET /api/areas/:id` (show)
  - Contract: `Contracts::Areas::Show`
  - Service: `Services::Areas::Show`
  - Repository: `find_by_id`
  - Presenter: `AreaPresenter.render_area`
  - 認証必須化
- [x] `POST /api/areas` (create)
  - Contract: `Contracts::Areas::Create`
  - Service: `Services::Areas::Create`
  - Repository: `build`, `save`
  - Presenter: `AreaPresenter.render_area`
  - Policy: `AreaPolicy#admin_only?`
  - 認証必須化、認可追加（admin_only）
- [x] `PUT /api/areas/:id` (update)
  - Contract: `Contracts::Areas::Update`
  - Service: `Services::Areas::Update`
  - Repository: `find_by_id_with_lock`, `update`
  - Presenter: `AreaPresenter.render_area`
  - Policy: `AreaPolicy#admin_only?`
  - 認証必須化、認可追加（admin_only）
  - トランザクション + 悲観ロック
- [x] `DELETE /api/areas/:id` (destroy)
  - Contract: `Contracts::Areas::Destroy`
  - Service: `Services::Areas::Destroy`
  - Repository: `find_by_id_with_lock`, `destroy`
  - Policy: `AreaPolicy#admin_only?`
  - 認証必須化、認可追加（admin_only）
  - トランザクション + 悲観ロック
  - FK制約エラー処理（409 Conflict）

作成ファイル:
- `app/contracts/areas/` - id_contract, show, destroy, create, update
- `app/services/areas/` - index, show, create, update, destroy, repository, result
- `app/policies/area_policy.rb`
- `app/presenters/area_presenter.rb`

---

## Phase 3: Comments コントローラー完了 (優先度: 中)

### 移行済み ✅ - PR #76
- [x] `GET /api/comments` (index)
  - Contract: `Contracts::Comments::Index`
  - Service: `Services::Comments::Index`
  - Repository: `task_exists?`, `get_comments_for_admin`, `get_comments_for_member`
  - Presenter: `CommentPresenter.render_comments`
  - 認証必須化
  - 認可: admin=全コメント / member=自分+adminのコメントのみ
- [x] `GET /api/comments/:id` (show)
  - Contract: `Contracts::Comments::Show` (継承: IdContract)
  - Service: `Services::Comments::Show`
  - Repository: `find_by_id`
  - Presenter: `CommentPresenter.render_comment`
  - Policy: `CommentPolicy#can_view?`
  - 認証必須化、認可追加
- [x] `POST /api/comments` (create)
  - Contract: `Contracts::Comments::Create`
  - Service: `Services::Comments::Create`
  - Repository: `task_exists?`, `build`, `save`, `find_by_id`
  - Presenter: `CommentPresenter.render_comment`
  - 認証必須化
  - account_id 自動設定（なりすまし防止）
  - 例外処理: Deadlocked, LockWaitTimeout, RecordNotUnique, InvalidForeignKey, StatementInvalid
- [x] `PUT /api/comments/:id` (update)
  - Contract: `Contracts::Comments::Update`
  - Service: `Services::Comments::Update`
  - Repository: `find_by_id_with_lock`, `update`, `find_by_id`
  - Presenter: `CommentPresenter.render_comment`
  - Policy: `CommentPolicy#can_modify?`
  - 認証必須化、認可追加（admin + 所有者）
  - トランザクション + 悲観ロック
- [x] `DELETE /api/comments/:id` (destroy)
  - Contract: `Contracts::Comments::Destroy` (継承: IdContract)
  - Service: `Services::Comments::Destroy`
  - Repository: `find_by_id_with_lock`, `destroy`
  - Policy: `CommentPolicy#can_modify?`
  - 認証必須化、認可追加（admin + 所有者）
  - トランザクション + 悲観ロック

作成ファイル:
- `app/contracts/comments/` - id_contract, index, show, destroy, create, update
- `app/services/comments/` - index, show, create, update, destroy, repository, result
- `app/policies/comment_policy.rb`
- `app/presenters/comment_presenter.rb`

エラーハンドリング:
- `Deadlocked`, `LockWaitTimeout` → 503 Service Unavailable
- `RecordNotUnique`, `InvalidForeignKey` → 409 Conflict
- `StatementInvalid` → 500 Internal Server Error
- nil チェック + 警告ログ（Presenter, Policy）

---

## Phase 4: Tags コントローラー完了 (優先度: 低)

### 移行済み ✅ - PR #77
- [x] `GET /api/tags` (index)
  - Service: `Services::Tags::Index`
  - Repository: `all_tags`
  - Presenter: `TagPresenter.render_tags`
  - 認証必須化
- [x] `GET /api/tags/:id` (show) ※新規追加
  - Contract: `Contracts::Tags::Show` (継承: IdContract)
  - Service: `Services::Tags::Show`
  - Repository: `find_by_id`
  - Presenter: `TagPresenter.render_tag`
  - 認証必須化
- [x] `POST /api/tags` (create)
  - Contract: `Contracts::Tags::Create`
  - Service: `Services::Tags::Create`
  - Repository: `build`, `save`
  - Presenter: `TagPresenter.render_tag`
  - Policy: `TagPolicy#admin_only?`
  - 認証必須化、認可追加（admin_only）
- [x] `PUT /api/tags/:id` (update)
  - Contract: `Contracts::Tags::Update`
  - Service: `Services::Tags::Update`
  - Repository: `find_by_id_with_lock`, `update`
  - Presenter: `TagPresenter.render_tag`
  - Policy: `TagPolicy#admin_only?`
  - 認証必須化、認可追加（admin_only）
  - トランザクション + 悲観ロック
- [x] `DELETE /api/tags/:id` (destroy)
  - Contract: `Contracts::Tags::Destroy` (継承: IdContract)
  - Service: `Services::Tags::Destroy`
  - Repository: `find_by_id_with_lock`, `destroy`
  - Policy: `TagPolicy#admin_only?`
  - 認証必須化、認可追加（admin_only）
  - トランザクション + 悲観ロック
  - FK制約エラー処理（409 Conflict）

作成ファイル:
- `app/contracts/tags/` - id_contract, show, destroy, create, update
- `app/services/tags/` - index, show, create, update, destroy, repository, result
- `app/policies/tag_policy.rb`
- `app/presenters/tag_presenter.rb`

エラーハンドリング:
- `Deadlocked`, `LockWaitTimeout` → 503 Service Unavailable
- `RecordNotUnique`, `InvalidForeignKey` → 409 Conflict
- `StatementInvalid` → 500 Internal Server Error
- ArgumentError（Presenterでnil受信時）

---

## Phase 5: 中間テーブル操作 (優先度: 低)

### Assigns ✅ - PR #78
- [x] `POST /api/tasks/assign/cycle` (cycle_create)
  - Contract: `Contracts::Assigns::CycleCreate`
  - Service: `Services::Assigns::CycleCreate`
  - Repository: `find_task_with_lock`, `deactivate_all_cycles`, `create_cycle`
  - Presenter: `AssignCyclePresenter.render_cycle`
  - Policy: `AccountPolicy#admin_only?`
  - 認証必須化、認可追加（admin_only）
  - トランザクション + 悲観ロック
  - 既存サイクル非活性化 + 自動割り当て実行
  - AssignCycle#assign を `.save!` に修正（サイレントエラー防止）

作成ファイル:
- `app/contracts/assigns/cycle_create.rb`
- `app/services/assigns/cycle_create.rb`, `repository.rb`, `result.rb`
- `app/presenters/assign_cycle_presenter.rb`

エラーハンドリング:
- `Deadlocked`, `LockWaitTimeout` → 503 Service Unavailable
- `RecordInvalid` → 422 Unprocessable Entity（詳細メッセージ付き）
- `StatementInvalid` → 500 Internal Server Error
- nil cycle → ArgumentError（Controller/Presenterで検出）

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
| `PUT /api/tasks/:id` | 認証必須化、認可追加(admin+担当者)、`is_complete`削除、Presenter経由レスポンス | - |
| `DELETE /api/tasks/:id` | 認証必須化、認可追加(admin_only)、レスポンス: 204→200+message | - |
| `PUT /api/tasks/:id/ng` | 認証必須化、認可追加(admin+担当者)、errors追加 | - |
| `GET /api/unfulfilled-count` | 認証必須化 | - |
| `GET /api/completed-data` | 認証必須化 | - |
| `GET /api/account/tasks` | 認証必須化、認可追加(admin+自分)、`title`→`task_title` | - |
| `GET /api/areas` | 認証必須化 | #75 |
| `GET /api/areas/:id` | 認証必須化 | #75 |
| `POST /api/areas` | 認証必須化、認可追加(admin_only) | #75 |
| `PUT /api/areas/:id` | 認証必須化、認可追加(admin_only)、悲観ロック | #75 |
| `DELETE /api/areas/:id` | 認証必須化、認可追加(admin_only)、悲観ロック、FK制約→409 | #75 |
| `GET /api/comments` | 認証必須化、認可追加(admin=全部/member=自分+admin) | #76 |
| `GET /api/comments/:id` | 認証必須化、認可追加(admin/所有者/adminコメント) | #76 |
| `POST /api/comments` | 認証必須化、account_id自動設定、Presenter経由レスポンス | #76 |
| `PUT /api/comments/:id` | 認証必須化、認可追加(admin+所有者)、悲観ロック | #76 |
| `DELETE /api/comments/:id` | 認証必須化、認可追加(admin+所有者)、悲観ロック、レスポンス: message追加 | #76 |
| `GET /api/tags` | 認証必須化 | #77 |
| `GET /api/tags/:id` | 新規追加、認証必須化 | #77 |
| `POST /api/tags` | 認証必須化、認可追加(admin_only) | #77 |
| `PUT /api/tags/:id` | 認証必須化、認可追加(admin_only)、悲観ロック | #77 |
| `DELETE /api/tags/:id` | 認証必須化、認可追加(admin_only)、悲観ロック、FK制約→409、レスポンス: message追加 | #77 |
| `POST /api/tasks/assign/cycle` | 認証必須化、認可追加(admin_only)、悲観ロック、既存サイクル非活性化、自動割り当て実行、レスポンス: 200→201 | #78 |

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

### Tasks Index/Create/Show/Update
- `app/contracts/tasks/index.rb`, `create.rb`, `show.rb`, `update.rb`
- `app/services/tasks/index.rb`, `create.rb`, `show.rb`, `update.rb`
- `app/services/tasks/repository.rb`
- `app/presenters/task_presenter.rb`

### Areas CRUD
- `app/contracts/areas/id_contract.rb`, `show.rb`, `destroy.rb`, `create.rb`, `update.rb`
- `app/services/areas/index.rb`, `show.rb`, `create.rb`, `update.rb`, `destroy.rb`
- `app/services/areas/repository.rb`, `result.rb`
- `app/presenters/area_presenter.rb`
- `app/policies/area_policy.rb`

### Comments CRUD
- `app/contracts/comments/id_contract.rb`, `index.rb`, `show.rb`, `destroy.rb`, `create.rb`, `update.rb`
- `app/services/comments/index.rb`, `show.rb`, `create.rb`, `update.rb`, `destroy.rb`
- `app/services/comments/repository.rb`, `result.rb`
- `app/presenters/comment_presenter.rb`
- `app/policies/comment_policy.rb`
- 特徴: 複合認可ルール（admin/所有者/adminコメント閲覧可）、包括的例外処理

### Tags CRUD
- `app/contracts/tags/id_contract.rb`, `show.rb`, `destroy.rb`, `create.rb`, `update.rb`
- `app/services/tags/index.rb`, `show.rb`, `create.rb`, `update.rb`, `destroy.rb`
- `app/services/tags/repository.rb`, `result.rb`
- `app/presenters/tag_presenter.rb`
- `app/policies/tag_policy.rb`
- 特徴: admin_only認可、ArgumentErrorパターン（Presenter）、FK制約エラー処理

### Assigns CycleCreate
- `app/contracts/assigns/cycle_create.rb`
- `app/services/assigns/cycle_create.rb`, `repository.rb`, `result.rb`
- `app/presenters/assign_cycle_presenter.rb`
- 特徴: admin_only認可、悲観ロック、既存サイクル非活性化、自動割り当て、nil cycleガード

---

## 関連ドキュメント

- `CLAUDE.md`: アーキテクチャ詳細、コーディング規約
- `ARCHITECTURE.md`: 設計思想（存在する場合）
