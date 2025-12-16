# ARCHITECTURE

## 概要

本ドキュメントは、本アプリケーションにおける **Rails 7（Zeitwerk）前提のアーキテクチャ方針** を定義する。

目的は以下の通り。

* 業務ロジックの肥大化・密結合を防ぐ
* autoload / eager_load の事故を防ぐ
* 副作用と純粋ロジックを分離する
* テスト容易性・変更耐性を高める

本アプリケーションでは、主に以下の 4 レイヤを中心に設計する。

* Service（ユースケース層）
* Domain（業務ルール層）
* Contract（入力契約層）
* Validator（入力検証層）

---

## 前提

* Rails 7.x
* Autoloader: Zeitwerk
* `require` を書かない
* 定数名とファイルパスは 1 対 1 対応

---

## ディレクトリ構成

すべて `app/` 配下に配置し、Zeitwerk の自動認識に委ねる。

```
app/
  contracts/     # 入力契約（検証 + データ変換）
  domain/        # 業務ルール（pure）
  services/      # ユースケース（副作用の統括）
  validators/    # 入力検証（ActiveModel::Validator）
```

### 方針

* `lib/` は原則使用しない
* autoload 対象は `app/` のみとする
* 命名規約を厳守する

---

## レイヤ責務

### Domain（ドメイン層）

#### 役割

* 業務ルール・仕様の表現
* **副作用を持たない純粋なロジック**
* Rails / ActiveRecord / 外部API に依存しない

#### 禁止事項

* DB アクセス
* HTTP / Mail / Job
* ActiveRecord
* Rails 固有 API

#### 内容例

* 状態遷移ルール
* 可否判定
* 計算ロジック
* ポリシー・ルールセット

#### 命名規約

```
app/domain/task/state_machine.rb
→ Domain::Task::StateMachine
```

---

### Service（サービス層 / ユースケース）

#### 役割

* ユースケースの実装
* 副作用のオーケストレーション
* トランザクション境界

#### 許可事項

* DB 更新
* トランザクション制御
* Domain 呼び出し
* Validator / Form 利用

#### 禁止事項

* 業務ルールの直接実装（Domain に委譲）
* Controller ロジックの肥大化

#### 命名規約

```
app/services/task/complete.rb
→ Services::Task::Complete
```

#### 戻り値ポリシー

* 例外をそのまま返さない
* 成功 / 失敗を Result オブジェクトで表現する

---

### Validator（入力検証層）

#### 役割

* 入力値の形式的妥当性を保証する
* ActiveModel::Validator に準拠
* **再利用可能な単一検証ロジック**

#### 扱う内容

* フォーマット
* 長さ
* 必須チェック
* 単項目検証

#### 扱わない内容

* 業務仕様上の可否
* 状態遷移
* DB 横断チェック（原則）

---

### Contract（入力契約層）

#### 役割

* Controller からの入力パラメータを受け取る
* 複数の Validator を組み合わせて検証を実行
* 検証済みデータの正規化・変換
* Result オブジェクトで成功/失敗を表現

#### 許可事項

* ActiveModel::Model による検証定義
* Validator の利用（validates_with）
* データ変換（型変換、正規化）

#### 禁止事項

* DB アクセス
* 業務ロジックの実装（Domain に委譲）
* 副作用を伴う処理

#### 命名規約

```
app/contracts/<context>/<action>.rb
→ Contracts::<Context>::<Action>
```

#### 例

```
app/contracts/accounts/create.rb
→ Contracts::Accounts::Create

app/contracts/tasks/update.rb
→ Contracts::Tasks::Update
```

#### 戻り値ポリシー

* `Contracts::Result` を使用する
* `success?` / `value` / `errors` を持つ Struct

---

## 命名規約

本アプリケーションでは、**ディレクトリ構成と定数名を厳密に対応**させることで、
Zeitwerk による autoload の安全性と可読性を担保する。

### 基本ルール

* ファイルパス = 定数名（1 対 1 対応）
* トップレベル定数は定義しない（必ず名前空間を切る）
* 省略語・略称は使用しない（例: `Svc`, `Mgr` などは禁止）

---

### Service の命名規約

**ユースケース単位で 1 Service** を原則とする。

#### 形式

```
app/services/<context>/<action>.rb
→ Services::<Context>::<Action>
```

#### Action 命名指針

* `Create`   : 新規作成
* `Update`   : 更新
* `Delete`   : 削除
* `Complete` : 完了・確定
* `Execute`  : 手続き的処理（副作用が多い場合）

#### 例

```
app/services/task/complete.rb
→ Services::Task::Complete

app/services/user/register.rb
→ Services::User::Register
```

---

### Domain の命名規約

Domain は**業務概念・仕様単位**で命名する。

#### 形式

```
app/domain/<context>/<concept>.rb
→ Domain::<Context>::<Concept>
```

#### 命名指針

* 動詞よりも名詞を優先する
* `Rules` / `Policy` / `StateMachine` / `Calculator` などを明示する

#### 例

```
app/domain/task/state_machine.rb
→ Domain::Task::StateMachine

app/domain/billing/price_calculator.rb
→ Domain::Billing::PriceCalculator
```

---

### Validator の命名規約

Validator は **何を検証するかが一目で分かる名前** とする。

#### 形式（フラット構造）

```
app/validators/<name>_validator.rb
→ <Name>Validator
```

#### 形式（ネスト構造）

コンテキストごとにグルーピングする場合：

```
app/validators/<context>/<name>.rb
→ Validators::<Context>::<Name>
```

#### 命名指針

* `Format` / `Presence` / `Length` / `Uniqueness` など目的を明示
* 業務仕様を含む名称は禁止

#### 例

```
app/validators/email_format_validator.rb
→ EmailFormatValidator

app/validators/accounts/create.rb
→ Validators::Accounts::Create
```

---

## 依存方向ルール

依存関係は必ず以下を守る。

```
Contract  → Validator     OK
Contract  → Domain        OK
Service   → Contract      OK
Service   → Domain        OK
Service   → Validator     OK
Validator → Domain        OK

Domain    → Service       NG
Domain    → Contract      NG
Domain    → Validator     NG
Domain    → ActiveRecord  NG
Contract  → Service       NG
Contract  → ActiveRecord  NG
```

Domain は最下層の純粋レイヤとする。
Contract は入力層として Controller と Service の間に位置する。

---

## Controller / Model の責務

### Controller

* パラメータ取得
* Contract による入力検証
* Service 呼び出し
* 結果に応じたレスポンス生成

### Model（ActiveRecord）

* 永続化
* 関連定義
* scope
* 業務ロジックは極力持たせない

---

## autoload 安全性

### チェック

```
bin/rails zeitwerk:check
```

### よくある NG

* ファイル名と定数名の不一致
* module ネスト不足
* トップレベル定数の乱立

---

## 設計判断チェックリスト

* DB に触るか？ → Service
* 計算・判定のみか？ → Domain
* 入力の形式チェックか？ → Validator
* 入力検証 + データ変換か？ → Contract
* トランザクション境界か？ → Service
* 業務仕様か？ → Domain

---

## 設計思想まとめ

* 副作用は Service に閉じ込める
* 業務ルールは Domain に集約する
* 入力検証とデータ変換は Contract で統括する
* 単一の検証ロジックは Validator に切り出す
* autoload は app/ 配下 + 命名規約で守る

本方針に従うことで、変更に強く、壊れにくく、テストしやすい Rails アプリケーションを実現する。
