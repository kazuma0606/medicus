# GraphQL Playground 使い方ガイド

GraphQL Playgroundの使い方と、MEDICUS APIでの動作確認方法を説明します。

## アクセス方法

### 開発環境

サーバー起動後、ブラウザで以下のURLにアクセス：

```
http://localhost:3000/playground
```

### 本番環境

セキュリティ上の理由から、本番環境ではPlaygroundは無効化されています。

`config/settings-prod.yml`:
```yaml
graphql:
  playground-enabled: false
```

## Playgroundの画面構成

```
┌─────────────────────────────────────────────────────────────┐
│  [Tab: health]                                    [PRETTIFY] │
├──────────────────────┬──────────────────────────────────────┤
│                      │                                      │
│  # クエリエディタ      │         レスポンス表示                 │
│                      │                                      │
│  query {             │  {                                   │
│    health {          │    "data": {                         │
│      status          │      "health": {                     │
│      service         │        "status": "healthy",          │
│    }                 │        "service": "medicus-api"      │
│  }                   │      }                               │
│                      │    }                                 │
│                      │  }                                   │
│                      │                                      │
├──────────────────────┴──────────────────────────────────────┤
│  QUERY VARIABLES  │  HTTP HEADERS  │  [DOCS]  │  [SCHEMA]  │
└─────────────────────────────────────────────────────────────┘
```

## 基本的な使い方

### 1. シンプルなクエリ

```graphql
query {
  health {
    status
    service
    version
    timestamp
  }
}
```

**実行方法:** 中央の▶ボタンをクリック

**期待される結果:**
```json
{
  "data": {
    "health": {
      "status": "healthy",
      "service": "medicus-api",
      "version": "0.1.0",
      "timestamp": "2026-03-07T11:10:01UTC"
    }
  }
}
```

### 2. リストを返すクエリ

```graphql
query {
  listAvailableConstraints
}
```

**結果:**
```json
{
  "data": {
    "listAvailableConstraints": [
      "PrivacyProtection",
      "EmergencyAccess",
      "SystemAvailability",
      "RegulatoryCompliance",
      "CustomConstraint"
    ]
  }
}
```

### 3. 引数付きクエリ

```graphql
query {
  validateSpace(config: {
    dimension: 3
    normWeights: {
      lambda: 0.3
      mu: 0.5
      nu: 0.2
    }
    constraints: []
  }) {
    valid
    errors {
      field
      errorMessage
      errorCode
    }
    warnings {
      field
      warningMessage
    }
  }
}
```

**結果（成功時）:**
```json
{
  "data": {
    "validateSpace": {
      "valid": true,
      "errors": [],
      "warnings": []
    }
  }
}
```

## Introspection機能

### スキーマの確認

```graphql
query IntrospectionQuery {
  __schema {
    queryType {
      name
    }
    mutationType {
      name
    }
    types {
      name
      kind
      description
    }
  }
}
```

### 特定の型の詳細

```graphql
query {
  __type(name: "ValidationResult") {
    name
    kind
    fields {
      name
      type {
        name
        kind
        ofType {
          name
          kind
        }
      }
    }
  }
}
```

### フィールドの引数確認

```graphql
query {
  __type(name: "Query") {
    fields {
      name
      args {
        name
        type {
          name
          kind
        }
        defaultValue
      }
    }
  }
}
```

## DOCSパネルの使い方

右側の**DOCS**タブをクリックすると、自動生成されたドキュメントが表示されます。

### スキーマブラウジング

1. **Query** - 利用可能なクエリ一覧
2. **Mutation** - 利用可能なミューテーション一覧
3. **Types** - すべての型定義

### 型の詳細表示

型名をクリックすると、フィールド、引数、説明が表示されます。

## Variables の使用

### クエリ変数の定義

クエリ:
```graphql
query ValidateSpaceQuery($dim: Int!, $weights: NormWeightsInput!) {
  validateSpace(config: {
    dimension: $dim
    normWeights: $weights
    constraints: []
  }) {
    valid
    errors {
      field
      errorMessage
    }
  }
}
```

Variables (下部のQUERY VARIABLESパネル):
```json
{
  "dim": 5,
  "weights": {
    "lambda": 0.4,
    "mu": 0.4,
    "nu": 0.2
  }
}
```

## HTTP Headers の設定

下部の**HTTP HEADERS**パネルで、カスタムヘッダーを追加できます。

```json
{
  "Authorization": "Bearer your-token-here",
  "X-Custom-Header": "custom-value"
}
```

## クエリの保存と管理

### タブ機能

複数のクエリを異なるタブで管理：

1. **[+]ボタン** - 新しいタブを追加
2. **タブ名をクリック** - タブ名の変更
3. **[×]ボタン** - タブを閉じる

### 推奨タブ構成

- `health` - ヘルスチェック用
- `listConstraints` - 制約一覧確認用
- `validateSpace` - スペース検証テスト用
- `createSpace` - スペース作成テスト用
- `optimize` - 最適化テスト用

## 便利なショートカット

| 操作 | ショートカット |
|---|---|
| クエリ実行 | Ctrl + Enter |
| コード整形 | Ctrl + Shift + F |
| 履歴を表示 | Ctrl + H |
| ドキュメント表示 | Ctrl + K |

## MEDICUS API サンプルクエリ集

### Query Examples

#### 1. ヘルスチェック

```graphql
query HealthCheck {
  health {
    status
    service
    version
    timestamp
  }
}
```

#### 2. 利用可能な制約タイプ

```graphql
query ListConstraints {
  listAvailableConstraints
}
```

#### 3. スペース検証（基本）

```graphql
query ValidateBasicSpace {
  validateSpace(config: {
    dimension: 3
    normWeights: {
      lambda: 0.333
      mu: 0.333
      nu: 0.334
    }
    constraints: []
  }) {
    valid
    errors {
      field
      errorMessage
      errorCode
    }
  }
}
```

#### 4. スペース検証（制約付き）

```graphql
query ValidateSpaceWithConstraints {
  validateSpace(config: {
    dimension: 5
    normWeights: {
      lambda: 0.4
      mu: 0.4
      nu: 0.2
    }
    constraints: [
      {
        name: "privacy"
        constraintType: PrivacyProtection
        dimensions: [0, 1, 2]
        weights: [1.0, 1.0, 0.5]
        threshold: 0.8
      }
    ]
  }) {
    valid
    errors {
      field
      errorMessage
      errorCode
    }
    warnings {
      field
      warningMessage
    }
  }
}
```

### Mutation Examples（スタブ実装）

#### 1. スペース作成

```graphql
mutation CreateSpace {
  createSpace(config: {
    dimension: 3
    normWeights: {
      lambda: 0.3
      mu: 0.5
      nu: 0.2
    }
    constraints: []
  }) {
    spaceId
    success
    message
  }
}
```

#### 2. 最適化実行

```graphql
mutation Optimize {
  optimize(input: {
    spaceId: "space-001"
    objectiveFunction: {
      type: Minimize
      expression: "x^2 + y^2"
    }
    initialPoint: [0.5, 0.5]
    options: {
      maxIterations: 1000
      tolerance: 0.001
      parallel: true
    }
  }) {
    success
    solution
    objectiveValue
    iterations
    converged
    message
    computationTimeMs
  }
}
```

#### 3. バッチ最適化

```graphql
mutation BatchOptimize {
  optimizeBatch(batch: {
    spaceId: "space-001"
    problems: [
      {
        objectiveFunction: {
          type: Minimize
          expression: "x^2"
        }
        initialPoint: [1.0]
        options: null
      },
      {
        objectiveFunction: {
          type: Maximize
          expression: "sin(x)"
        }
        initialPoint: [0.5]
        options: null
      }
    ]
  }) {
    success
    solution
    objectiveValue
    iterations
  }
}
```

## エラーメッセージの読み方

### 構文エラー

```json
{
  "errors": [
    {
      "message": "Syntax Error: Expected Name, found }",
      "locations": [{"line": 3, "column": 5}]
    }
  ]
}
```

**対処:** クエリの構文を確認

### フィールドエラー

```json
{
  "errors": [
    {
      "message": "Unknown Field \"userName\" on type \"User\"",
      "locations": [{"line": 4, "column": 5}]
    }
  ]
}
```

**対処:** DOCSパネルで正しいフィールド名を確認

### 引数エラー

```json
{
  "errors": [
    {
      "message": "Argument \"config\" got invalid value. in field \"normWeights\": Undefined Field \"l1\".",
      "locations": [{"line": 2, "column": 17}]
    }
  ]
}
```

**対処:** 正しいフィールド名を使用（例: `l1` → `lambda`）

## Playgroundのカスタマイズ

### デフォルトクエリの設定

`Handler/Playground.hs`でデフォルトクエリを設定できます：

```haskell
let defaultQuery = T.unlines
        [ "# Welcome to MEDICUS API GraphQL Playground"
        , ""
        , "query HealthCheck {"
        , "  health {"
        , "    status"
        , "    service"
        , "    version"
        , "  }"
        , "}"
        ]
```

### テーマの変更

GraphQL Playground CDNのバージョンやテーマを変更：

```html
<script src="//cdn.jsdelivr.net/npm/graphql-playground-react/build/static/js/middleware.js"></script>
<script>
  GraphQLPlayground.init(root, {
    endpoint: '/graphql',
    settings: {
      'editor.theme': 'dark',  // 'dark' or 'light'
      'editor.fontSize': 14
    }
  })
</script>
```

## 開発ワークフロー

### 1. 新しいクエリの追加

1. `GraphQL/Schema.hs`に型を追加
2. `GraphQL/Resolvers.hs`にresolver実装
3. ビルド: `stack build --fast`
4. サーバー再起動
5. Playgroundで動作確認

### 2. スキーマの確認

DOCSパネルで自動生成されたドキュメントを確認

### 3. デバッグ

```graphql
# サーバーログを確認しながら実行
query {
  validateSpace(config: {...}) {
    valid
    errors {
      field
      errorMessage
      errorCode
    }
  }
}
```

サーバーログ:
```
[Info] Validating space with dimension: 3
[Debug] Norm weights: lambda=0.3, mu=0.5, nu=0.2
[Info] Validation result: valid=true
```

## トラブルシューティング

### Playgroundが表示されない

**確認事項:**

1. サーバーが起動しているか
   ```bash
   curl http://localhost:3000/health
   ```

2. 設定でPlaygroundが有効か
   ```yaml
   # config/settings.yml
   graphql:
     playground-enabled: true
   ```

3. ルートが定義されているか
   ```
   # config/routes.txt
   /playground PlaygroundR GET
   ```

### "Network Error"が表示される

**原因:** GraphQLエンドポイントに接続できない

**対処法:**

1. エンドポイントURLを確認
   ```javascript
   // Playgroundのコンソールで確認
   endpoint: '/graphql'
   ```

2. CORSが有効か確認
   ```yaml
   # config/settings.yml
   cors:
     enabled: true
   ```

3. サーバーログでエラーを確認
   ```
   [Error] Failed to parse GraphQL query: ...
   ```

### クエリが実行できない

**チェックリスト:**

1. ✅ 構文が正しいか（PrettifyボタンでフォーマットPrettifyボタンでフォーマット確認）
2. ✅ フィールド名が正しいか（DOCSパネルで確認）
3. ✅ 引数の型が正しいか
4. ✅ 必須フィールドが含まれているか

## 高度な使い方

### Fragment の使用

```graphql
fragment ErrorDetails on ValidationError {
  field
  errorMessage
  errorCode
}

query {
  validateSpace(config: {...}) {
    valid
    errors {
      ...ErrorDetails
    }
  }
}
```

### Named Queries

```graphql
query GetHealthStatus {
  health {
    status
  }
}

query ListAllConstraints {
  listAvailableConstraints
}

# 実行時にどちらを実行するか選択できる
```

### Inline Fragments

```graphql
query {
  __typename
  ... on Query {
    health {
      status
    }
  }
}
```

## パフォーマンス計測

### 実行時間の確認

Playgroundのレスポンス下部に実行時間が表示されます：

```
Query executed in 45ms
```

### 複雑なクエリのベンチマーク

```graphql
query BenchmarkQuery {
  # 複数のフィールドを同時にクエリ
  health { status }
  listAvailableConstraints
  space1: validateSpace(config: {...}) { valid }
  space2: validateSpace(config: {...}) { valid }
  space3: validateSpace(config: {...}) { valid }
}
```

## CURL での代替テスト

Playgroundが使えない場合、curlでテスト：

### シンプルなクエリ

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ health { status service } }"}'
```

### 変数を使用したクエリ

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "query($dim: Int!) { validateSpace(config: { dimension: $dim, normWeights: { lambda: 0.3, mu: 0.5, nu: 0.2 }, constraints: [] }) { valid } }",
    "variables": {"dim": 3}
  }'
```

### PowerShell での実行

```powershell
$body = @{
    query = "{ health { status } }"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/graphql" `
    -Method POST `
    -ContentType "application/json" `
    -Body $body
```

## ベストプラクティス

### 1. クエリの命名

```graphql
# ❌ 悪い例
query {
  health { status }
}

# ✅ 良い例
query GetServiceHealth {
  health {
    status
    service
    version
  }
}
```

### 2. フィールドの選択

```graphql
# ❌ 全フィールドを取得（非効率）
query {
  validateSpace(config: {...}) {
    valid
    errors { field errorMessage errorCode }
    warnings { field warningMessage }
  }
}

# ✅ 必要なフィールドのみ
query {
  validateSpace(config: {...}) {
    valid
  }
}
```

### 3. エラーハンドリング

```graphql
query {
  validateSpace(config: {...}) {
    valid
    errors {
      field
      errorMessage
      errorCode  # エラーコードで処理を分岐
    }
  }
}
```

## デバッグテクニック

### 1. 段階的なクエリ構築

```graphql
# ステップ1: 最小限のクエリ
query { health { status } }

# ステップ2: フィールドを追加
query { health { status service } }

# ステップ3: 完全なクエリ
query { health { status service version timestamp } }
```

### 2. サーバーログの活用

サーバー側のログを確認しながらクエリ実行：

```bash
# サーバーログをリアルタイム表示
stack exec medicus-api 2>&1 | tee server.log
```

### 3. ネットワークタブの確認

ブラウザの開発者ツール → Network タブで：
- リクエストボディの確認
- レスポンスヘッダーの確認
- 実行時間の詳細確認

## 次のステップ

- [06-troubleshooting.md](./06-troubleshooting.md) - よくある問題と解決法
- [08-api-reference.md](./08-api-reference.md) - 完全なAPI仕様
- [09-graphql-schema.md](./09-graphql-schema.md) - スキーマ設計の詳細

## 参考リンク

- [GraphQL Playground GitHub](https://github.com/graphql/graphql-playground)
- [GraphQL 公式ドキュメント](https://graphql.org/learn/)
- [Morpheus GraphQL Examples](https://github.com/morpheusgraphql/morpheus-graphql/tree/master/examples)
