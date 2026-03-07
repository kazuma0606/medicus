# API リファレンス

MEDICUS API の完全なAPIリファレンスです。

## エンドポイント

| エンドポイント | メソッド | 説明 |
|---|---|---|
| `/health` | GET | ヘルスチェック |
| `/graphql` | POST | GraphQLクエリ実行 |
| `/playground` | GET | GraphQL Playground UI |

## ベースURL

### 開発環境
```
http://localhost:3000
```

### 本番環境（将来）
```
https://api.medicus.example.com
```

---

## GraphQL スキーマ

### Query

#### health

サービスの健全性を確認します。

**シグネチャ:**
```graphql
health: HealthStatus!
```

**例:**
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

**レスポンス:**
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

---

#### listAvailableConstraints

利用可能な制約タイプの一覧を取得します。

**シグネチャ:**
```graphql
listAvailableConstraints: [ConstraintType!]!
```

**例:**
```graphql
query {
  listAvailableConstraints
}
```

**レスポンス:**
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

---

#### validateSpace

医療空間の設定を検証します。

**シグネチャ:**
```graphql
validateSpace(config: SpaceConfigInput!): ValidationResult!
```

**引数:**

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `config` | `SpaceConfigInput!` | ✅ | 検証する空間設定 |

**例:**
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

**レスポンス（成功時）:**
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

**レスポンス（エラー時）:**
```json
{
  "data": {
    "validateSpace": {
      "valid": false,
      "errors": [
        {
          "field": "dimension",
          "errorMessage": "Dimension must be positive",
          "errorCode": "INVALID_DIMENSION"
        }
      ],
      "warnings": []
    }
  }
}
```

---

### Mutation

#### createSpace

新しい医療空間を作成します。

**シグネチャ:**
```graphql
createSpace(config: SpaceConfigInput!): SpaceCreationResult!
```

**引数:**

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `config` | `SpaceConfigInput!` | ✅ | 空間の設定 |

**例:**
```graphql
mutation {
  createSpace(config: {
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
    spaceId
    success
    message
  }
}
```

**レスポンス:**
```json
{
  "data": {
    "createSpace": {
      "spaceId": "space-001",
      "success": true,
      "message": "Space created successfully"
    }
  }
}
```

---

#### optimize

最適化問題を実行します。

**シグネチャ:**
```graphql
optimize(input: OptimizationInput!): OptimizationResult!
```

**引数:**

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `input` | `OptimizationInput!` | ✅ | 最適化問題の定義 |

**例:**
```graphql
mutation {
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

**レスポンス:**
```json
{
  "data": {
    "optimize": {
      "success": true,
      "solution": [0.0, 0.0],
      "objectiveValue": 0.0,
      "iterations": 42,
      "converged": true,
      "message": "Optimization completed successfully",
      "computationTimeMs": 125
    }
  }
}
```

---

#### optimizeBatch

複数の最適化問題をバッチ実行します。

**シグネチャ:**
```graphql
optimizeBatch(batch: BatchOptimizationInput!): [OptimizationResult!]!
```

**引数:**

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `batch` | `BatchOptimizationInput!` | ✅ | バッチ最適化の定義 |

**例:**
```graphql
mutation {
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

---

## 型定義

### Input Types

#### SpaceConfigInput

医療空間の設定。

```graphql
input SpaceConfigInput {
  dimension: Int!
  normWeights: NormWeightsInput!
  constraints: [ConstraintInput!]!
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `dimension` | `Int!` | ✅ | 空間の次元数（> 0） |
| `normWeights` | `NormWeightsInput!` | ✅ | ノルムの重み |
| `constraints` | `[ConstraintInput!]!` | ✅ | 制約のリスト（空配列可） |

---

#### NormWeightsInput

ノルムの重み設定。

```graphql
input NormWeightsInput {
  lambda: Float!
  mu: Float!
  nu: Float!
}
```

| フィールド | 型 | 必須 | 説明 | 制約 |
|---|---|---|---|---|
| `lambda` | `Float!` | ✅ | L1ノルムの重み | λ ≥ 0 |
| `mu` | `Float!` | ✅ | L2ノルムの重み | μ ≥ 0 |
| `nu` | `Float!` | ✅ | L∞ノルムの重み | ν ≥ 0 |

**検証ルール:**
- λ + μ + ν = 1.0（合計が1）
- すべての値が非負

---

#### ConstraintInput

制約の定義。

```graphql
input ConstraintInput {
  name: String!
  constraintType: ConstraintType!
  dimensions: [Int!]!
  weights: [Float!]!
  threshold: Float!
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `name` | `String!` | ✅ | 制約の名前 |
| `constraintType` | `ConstraintType!` | ✅ | 制約のタイプ |
| `dimensions` | `[Int!]!` | ✅ | 適用する次元のインデックス |
| `weights` | `[Float!]!` | ✅ | 各次元の重み |
| `threshold` | `Float!` | ✅ | 閾値 |

---

#### OptimizationInput

最適化問題の定義。

```graphql
input OptimizationInput {
  spaceId: String!
  objectiveFunction: ObjectiveFunctionInput!
  initialPoint: [Float!]!
  options: OptimizationOptionsInput
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `spaceId` | `String!` | ✅ | 対象空間のID |
| `objectiveFunction` | `ObjectiveFunctionInput!` | ✅ | 目的関数 |
| `initialPoint` | `[Float!]!` | ✅ | 初期点 |
| `options` | `OptimizationOptionsInput` | ❌ | オプション設定 |

---

#### ObjectiveFunctionInput

目的関数の定義。

```graphql
input ObjectiveFunctionInput {
  type: OptimizationType!
  expression: String!
}
```

| フィールド | 型 | 必須 | 説明 |
|---|---|---|---|
| `type` | `OptimizationType!` | ✅ | 最適化タイプ（Minimize / Maximize） |
| `expression` | `String!` | ✅ | 数式表現 |

---

#### OptimizationOptionsInput

最適化オプション。

```graphql
input OptimizationOptionsInput {
  maxIterations: Int
  tolerance: Float
  parallel: Boolean
}
```

| フィールド | 型 | デフォルト | 説明 |
|---|---|---|---|
| `maxIterations` | `Int` | 1000 | 最大反復回数 |
| `tolerance` | `Float` | 0.001 | 収束判定閾値 |
| `parallel` | `Boolean` | false | 並列実行の有効化 |

---

### Output Types

#### HealthStatus

サービスの健全性ステータス。

```graphql
type HealthStatus {
  status: String!
  service: String!
  version: String!
  timestamp: String!
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `status` | `String!` | ステータス（"healthy" / "unhealthy"） |
| `service` | `String!` | サービス名 |
| `version` | `String!` | バージョン |
| `timestamp` | `String!` | タイムスタンプ（ISO 8601形式） |

---

#### ValidationResult

検証結果。

```graphql
type ValidationResult {
  valid: Boolean!
  errors: [ValidationError!]!
  warnings: [ValidationWarning!]!
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `valid` | `Boolean!` | 検証が成功したか |
| `errors` | `[ValidationError!]!` | エラーのリスト |
| `warnings` | `[ValidationWarning!]!` | 警告のリスト |

---

#### ValidationError

検証エラー。

```graphql
type ValidationError {
  field: String!
  errorMessage: String!
  errorCode: String!
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `field` | `String!` | エラーが発生したフィールド |
| `errorMessage` | `String!` | エラーメッセージ |
| `errorCode` | `String!` | エラーコード（例: "INVALID_DIMENSION"） |

**エラーコード一覧:**

| コード | 説明 |
|---|---|
| `INVALID_DIMENSION` | 次元数が不正 |
| `INVALID_NORM_WEIGHTS` | ノルムの重みが不正（合計が1でない） |
| `INVALID_CONSTRAINT` | 制約定義が不正 |
| `DIMENSION_MISMATCH` | 次元数が一致しない |

---

#### ValidationWarning

検証警告。

```graphql
type ValidationWarning {
  field: String!
  warningMessage: String!
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `field` | `String!` | 警告が発生したフィールド |
| `warningMessage` | `String!` | 警告メッセージ |

---

#### SpaceCreationResult

空間作成結果。

```graphql
type SpaceCreationResult {
  spaceId: String!
  success: Boolean!
  message: String!
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `spaceId` | `String!` | 作成された空間のID |
| `success` | `Boolean!` | 作成が成功したか |
| `message` | `String!` | メッセージ |

---

#### OptimizationResult

最適化結果。

```graphql
type OptimizationResult {
  success: Boolean!
  solution: [Float!]!
  objectiveValue: Float!
  iterations: Int!
  converged: Boolean!
  message: String!
  computationTimeMs: Int!
}
```

| フィールド | 型 | 説明 |
|---|---|---|
| `success` | `Boolean!` | 最適化が成功したか |
| `solution` | `[Float!]!` | 解（最適点） |
| `objectiveValue` | `Float!` | 目的関数の値 |
| `iterations` | `Int!` | 反復回数 |
| `converged` | `Boolean!` | 収束したか |
| `message` | `String!` | メッセージ |
| `computationTimeMs` | `Int!` | 計算時間（ミリ秒） |

---

### Enum Types

#### ConstraintType

制約のタイプ。

```graphql
enum ConstraintType {
  PrivacyProtection
  EmergencyAccess
  SystemAvailability
  RegulatoryCompliance
  CustomConstraint
}
```

| 値 | 説明 |
|---|---|
| `PrivacyProtection` | プライバシー保護制約 |
| `EmergencyAccess` | 緊急アクセス制約 |
| `SystemAvailability` | システム可用性制約 |
| `RegulatoryCompliance` | 規制準拠制約 |
| `CustomConstraint` | カスタム制約 |

---

#### OptimizationType

最適化タイプ。

```graphql
enum OptimizationType {
  Minimize
  Maximize
}
```

| 値 | 説明 |
|---|---|
| `Minimize` | 最小化問題 |
| `Maximize` | 最大化問題 |

---

## エラーハンドリング

### GraphQLエラー形式

すべてのGraphQLエラーは以下の形式で返されます：

```json
{
  "errors": [
    {
      "message": "エラーメッセージ",
      "locations": [
        {
          "line": 2,
          "column": 3
        }
      ],
      "path": ["validateSpace", "config"],
      "extensions": {
        "code": "ERROR_CODE"
      }
    }
  ]
}
```

### HTTPステータスコード

| コード | 説明 |
|---|---|
| `200 OK` | 成功（GraphQLエラーも200で返る） |
| `400 Bad Request` | リクエストの構文エラー |
| `404 Not Found` | エンドポイントが存在しない |
| `405 Method Not Allowed` | メソッドが許可されていない |
| `500 Internal Server Error` | サーバー内部エラー |

---

## レート制限（将来の実装）

現在はレート制限なし。将来的には以下を実装予定：

```
X-RateLimit-Limit: 1000
X-RateLimit-Remaining: 999
X-RateLimit-Reset: 1709812801
```

---

## 認証（将来の実装）

現在は認証なし。将来的にはJWT認証を実装予定：

```http
Authorization: Bearer <jwt-token>
```

---

## バージョニング

現在のAPIバージョン: **v0.1.0**

将来的には以下の方法でバージョン管理：

1. URLベース: `/api/v1/graphql`, `/api/v2/graphql`
2. ヘッダーベース: `API-Version: 1`

---

## サンプルコード

### JavaScript / TypeScript

```typescript
// fetch APIを使用
async function queryHealth() {
  const response = await fetch('http://localhost:3000/graphql', {
    method: 'POST',
    headers: {
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      query: `
        query {
          health {
            status
            service
            version
          }
        }
      `
    })
  });
  
  const data = await response.json();
  console.log(data);
}
```

### Python

```python
import requests

def query_health():
    query = """
    query {
      health {
        status
        service
        version
      }
    }
    """
    
    response = requests.post(
        'http://localhost:3000/graphql',
        json={'query': query},
        headers={'Content-Type': 'application/json'}
    )
    
    return response.json()

result = query_health()
print(result)
```

### cURL

```bash
curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{
    "query": "{ health { status service version } }"
  }'
```

### Haskell

```haskell
{-# LANGUAGE OverloadedStrings #-}
{-# LANGUAGE QuasiQuotes #-}

import Network.HTTP.Simple
import Data.Aeson
import Data.Text (Text)

queryHealth :: IO (Response ByteString)
queryHealth = do
    let request = setRequestMethod "POST"
                $ setRequestPath "/graphql"
                $ setRequestHost "localhost"
                $ setRequestPort 3000
                $ setRequestBodyJSON (object
                    [ "query" .= ("{ health { status } }" :: Text)
                    ])
                $ defaultRequest
    httpBS request
```

---

## ベストプラクティス

### 1. 必要なフィールドのみ取得

```graphql
# ❌ 悪い例
query {
  health {
    status
    service
    version
    timestamp
  }
}

# ✅ 良い例（必要なフィールドのみ）
query {
  health {
    status
  }
}
```

### 2. Named Queries の使用

```graphql
# ✅ 推奨
query GetServiceHealth {
  health {
    status
    service
  }
}
```

### 3. 変数の使用

```graphql
query ValidateSpace($dimension: Int!, $weights: NormWeightsInput!) {
  validateSpace(config: {
    dimension: $dimension
    normWeights: $weights
    constraints: []
  }) {
    valid
  }
}
```

Variables:
```json
{
  "dimension": 5,
  "weights": {
    "lambda": 0.4,
    "mu": 0.4,
    "nu": 0.2
  }
}
```

### 4. エラーハンドリング

```typescript
const result = await fetch('/graphql', {...});
const json = await result.json();

if (json.errors) {
  // GraphQLエラーを処理
  console.error('GraphQL Errors:', json.errors);
} else if (json.data) {
  // データを処理
  console.log('Data:', json.data);
}
```

---

## パフォーマンス最適化

### 1. バッチクエリ

複数のクエリを1つのリクエストにまとめる：

```graphql
query {
  health { status }
  constraints: listAvailableConstraints
  space1: validateSpace(config: {...}) { valid }
  space2: validateSpace(config: {...}) { valid }
}
```

### 2. フィールドの選択

不要なフィールドを取得しない：

```graphql
# 必要最小限
query {
  validateSpace(config: {...}) {
    valid  # errorsやwarningsは不要なら取得しない
  }
}
```

---

## セキュリティ考慮事項

### 1. 入力検証

すべての入力は自動的に検証されますが、クライアント側でも検証を推奨：

```typescript
function validateDimension(dim: number): boolean {
  return dim > 0 && Number.isInteger(dim);
}
```

### 2. SQLインジェクション対策

将来DB統合時も、GraphQLの型システムにより自動的に保護されます。

### 3. XSS対策

レスポンスは自動的にエスケープされますが、クライアント側でも適切な処理を：

```typescript
function escapeHtml(text: string): string {
  return text.replace(/[&<>"']/g, (char) => {
    const entities: Record<string, string> = {
      '&': '&amp;',
      '<': '&lt;',
      '>': '&gt;',
      '"': '&quot;',
      "'": '&#39;'
    };
    return entities[char];
  });
}
```

---

## 付録

### A. よくある質問

**Q: GraphQLとRESTの違いは？**

A: GraphQLは必要なデータのみを1回のリクエストで取得できます。

**Q: introspectionとは？**

A: GraphQLスキーマの構造を取得するための機能です。

**Q: subscriptionsは使えますか？**

A: 現在は未実装です。将来的に追加予定です。

### B. 用語集

| 用語 | 説明 |
|---|---|
| Query | データ取得操作 |
| Mutation | データ変更操作 |
| Subscription | リアルタイム通知（未実装） |
| Resolver | クエリを実際のデータに解決する関数 |
| Introspection | スキーマ情報の取得 |

---

## 変更履歴

| バージョン | 日付 | 変更内容 |
|---|---|---|
| 0.1.0 | 2026-03-07 | 初版リリース |

---

## 関連ドキュメント

- [05-graphql-playground.md](./05-graphql-playground.md) - Playgroundの使い方
- [09-graphql-schema.md](./09-graphql-schema.md) - スキーマ設計の詳細
- [06-troubleshooting.md](./06-troubleshooting.md) - トラブルシューティング

---

**ドキュメント作成日:** 2026-03-07  
**最終更新日:** 2026-03-07
