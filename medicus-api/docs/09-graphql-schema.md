# GraphQL スキーマ設計ドキュメント

MEDICUS APIのGraphQLスキーマの設計思想と実装詳細を説明します。

## 設計原則

### 1. Type-First Design

Haskellの型システムから自動的にGraphQLスキーマを生成：

```haskell
-- Haskell型定義
data HealthStatus = HealthStatus
    { status :: Text
    , service :: Text
    , version :: Text
    , timestamp :: Text
    } deriving (Generic, GQLType)
```

↓ 自動生成

```graphql
type HealthStatus {
  status: String!
  service: String!
  version: String!
  timestamp: String!
}
```

### 2. Null Safety

デフォルトでnon-nullable（`!`）、オプショナルのみ`Maybe`型を使用：

```haskell
-- Non-nullable
data User = User { userId :: Int }  -- GraphQL: Int!

-- Nullable
data User = User { email :: Maybe Text }  -- GraphQL: String
```

### 3. 明示的なInput/Output分離

```haskell
-- Input型
data SpaceConfigInput = SpaceConfigInput {...}

-- Output型
data SpaceConfig = SpaceConfig {...}
```

---

## スキーマ構造

### ルートタイプ

```graphql
schema {
  query: Query
  mutation: Mutation
}
```

現在、`subscription`は未実装です。

---

## Query設計

### health クエリ

**目的:** サービスの健全性を確認

**設計判断:**
- 引数なし（常に現在の状態を返す）
- キャッシュ不要（常に最新の状態）
- タイムスタンプを含める（いつの状態か明確に）

```haskell
data Query m = Query
    { health :: m HealthStatus
    }
```

**実装:**
```haskell
resolveHealth :: IO HealthStatus
resolveHealth = do
    now <- getCurrentTime
    return $ HealthStatus
        { status = "healthy"
        , service = "medicus-api"
        , version = "0.1.0"
        , timestamp = T.pack $ show now
        }
```

---

### listAvailableConstraints クエリ

**目的:** 利用可能な制約タイプの一覧を取得

**設計判断:**
- 列挙型を返す（型安全）
- 静的リスト（システム定義）
- キャッシュ可能

```haskell
data Query m = Query
    { listAvailableConstraints :: m [ConstraintType]
    }
```

**実装:**
```haskell
resolveListConstraints :: IO [ConstraintType]
resolveListConstraints = return
    [ PrivacyProtection
    , EmergencyAccess
    , SystemAvailability
    , RegulatoryCompliance
    , CustomConstraint
    ]
```

---

### validateSpace クエリ

**目的:** 空間設定の妥当性を検証

**設計判断:**
- Queryとして実装（副作用なし）
- 詳細なエラー情報を返す（`ValidationError`リスト）
- 警告も返す（エラーではないが注意すべき点）

```haskell
data Query m = Query
    { validateSpace :: ValidateSpaceArgs -> m ValidationResult
    }

data ValidateSpaceArgs = ValidateSpaceArgs
    { config :: SpaceConfigInput
    } deriving (Generic)
```

**実装:**
```haskell
resolveValidateSpace :: ValidateSpaceArgs -> IO ValidationResult
resolveValidateSpace args = do
    let cfg = config args
    -- 検証ロジック
    if dimension cfg <= 0
        then return $ ValidationResult
            { valid = False
            , errors = [ValidationError
                { field = "dimension"
                , errorMessage = "Dimension must be positive"
                , errorCode = "INVALID_DIMENSION"
                }]
            , warnings = []
            }
        else return $ ValidationResult
            { valid = True
            , errors = []
            , warnings = []
            }
```

---

## Mutation設計

### createSpace ミューテーション

**目的:** 新しい医療空間を作成

**設計判断:**
- Mutationとして実装（副作用あり：空間が作成される）
- IDを返す（作成された空間を特定）
- 成功/失敗をBoolean + メッセージで返す

```haskell
data Mutation m = Mutation
    { createSpace :: CreateSpaceArgs -> m SpaceCreationResult
    }

data CreateSpaceArgs = CreateSpaceArgs
    { config :: SpaceConfigInput
    } deriving (Generic)
```

**実装:**
```haskell
resolveCreateSpace :: CreateSpaceArgs -> IO SpaceCreationResult
resolveCreateSpace args = do
    let cfg = config args
    -- 空間作成ロジック
    spaceId <- generateSpaceId  -- 仮実装
    return $ SpaceCreationResult
        { spaceId = spaceId
        , success = True
        , message = "Space created successfully"
        }
```

---

### optimize ミューテーション

**目的:** 最適化問題を実行

**設計判断:**
- 計算時間を返す（パフォーマンス計測）
- 収束判定を含む（結果の信頼性）
- 詳細なメッセージを返す（デバッグ用）

```haskell
data Mutation m = Mutation
    { optimize :: OptimizeArgs -> m OptimizationResult
    }

data OptimizeArgs = OptimizeArgs
    { input :: OptimizationInput
    } deriving (Generic)
```

---

### optimizeBatch ミューテーション

**目的:** 複数の最適化問題をバッチ実行

**設計判断:**
- 並列実行可能（パフォーマンス）
- 個別結果を返す（部分的な失敗にも対応）
- 全体の成否は各結果の`success`で判断

```haskell
data Mutation m = Mutation
    { optimizeBatch :: OptimizeBatchArgs -> m [OptimizationResult]
    }
```

---

## Input型の設計

### SpaceConfigInput

医療空間の設定を表すInput型。

**設計判断:**
- すべての必須フィールドはnon-nullable
- 制約リストは空配列を許可（制約なしの空間も有効）
- ノルムの重みは別のInput型に分離（再利用性）

```haskell
data SpaceConfigInput = SpaceConfigInput
    { dimension :: Int
    , normWeights :: NormWeightsInput
    , constraints :: [ConstraintInput]
    } deriving (Generic)
```

**GraphQL:**
```graphql
input SpaceConfigInput {
  dimension: Int!
  normWeights: NormWeightsInput!
  constraints: [ConstraintInput!]!
}
```

---

### NormWeightsInput

ノルムの重み設定。

**設計判断:**
- 3つのノルム（L1, L2, L∞）を明示的に分離
- フィールド名は数学的表記（lambda, mu, nu）
- 検証は別途実施（λ + μ + ν = 1.0）

```haskell
data NormWeightsInput = NormWeightsInput
    { lambda :: Double  -- L1ノルムの重み
    , mu :: Double      -- L2ノルムの重み
    , nu :: Double      -- L∞ノルムの重み
    } deriving (Generic)
```

**検証ロジック:**
```haskell
validateNormWeights :: NormWeightsInput -> Bool
validateNormWeights w =
    let sum = lambda w + mu w + nu w
    in abs (sum - 1.0) < 1e-10  -- 浮動小数点誤差を考慮
```

---

### ConstraintInput

制約の定義。

**設計判断:**
- `name`はユーザー定義の識別子
- `constraintType`は列挙型（型安全）
- `dimensions`と`weights`は対応する配列
- `threshold`は検証の基準値

```haskell
data ConstraintInput = ConstraintInput
    { name :: Text
    , constraintType :: ConstraintType
    , dimensions :: [Int]
    , weights :: [Double]
    , threshold :: Double
    } deriving (Generic)
```

**検証ルール:**
- `dimensions`と`weights`の長さが一致
- `dimensions`の各要素が空間の次元数未満
- `threshold`が適切な範囲内（0.0〜1.0など、制約タイプによる）

---

### OptimizationInput

最適化問題の定義。

**設計判断:**
- `spaceId`で空間を参照（事前に作成が必要）
- `objectiveFunction`は別のInput型（複雑な構造）
- `options`はオプショナル（デフォルト値を使用可能）

```haskell
data OptimizationInput = OptimizationInput
    { spaceId :: Text
    , objectiveFunction :: ObjectiveFunctionInput
    , initialPoint :: [Double]
    , options :: Maybe OptimizationOptionsInput
    } deriving (Generic)
```

---

## Output型の設計

### ValidationResult

検証結果を表すOutput型。

**設計判断:**
- `valid`フラグで一目で判断可能
- `errors`リストで詳細なエラー情報
- `warnings`リストでエラーではないが注意すべき点

```haskell
data ValidationResult = ValidationResult
    { valid :: Bool
    , errors :: [ValidationError]
    , warnings :: [ValidationWarning]
    } deriving (Generic, GQLType)
```

**使用例:**
```graphql
{
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
```

---

### ValidationError

検証エラーの詳細。

**設計判断:**
- `field`でエラー箇所を特定
- `errorMessage`は人間が読める説明
- `errorCode`はプログラムが処理可能な識別子

```haskell
data ValidationError = ValidationError
    { field :: Text
    , errorMessage :: Text
    , errorCode :: Text
    } deriving (Generic, GQLType)
```

**エラーコードの命名規則:**
- `INVALID_` + フィールド名: 値が不正
- `MISSING_` + フィールド名: 必須フィールドが欠落
- `DIMENSION_MISMATCH`: 次元数の不一致

---

### OptimizationResult

最適化結果。

**設計判断:**
- 成功/失敗を`success`フラグで判断
- `solution`は解（最適点）
- `objectiveValue`は目的関数の値
- `computationTimeMs`でパフォーマンス計測

```haskell
data OptimizationResult = OptimizationResult
    { success :: Bool
    , solution :: [Double]
    , objectiveValue :: Double
    , iterations :: Int
    , converged :: Bool
    , message :: Text
    , computationTimeMs :: Int
    } deriving (Generic, GQLType)
```

---

## Enum型の設計

### ConstraintType

制約のタイプ。

**設計判断:**
- 医療ドメイン特有の制約を列挙
- 拡張可能（`CustomConstraint`）
- 型安全（存在しない制約タイプは指定不可）

```haskell
data ConstraintType
    = PrivacyProtection      -- プライバシー保護
    | EmergencyAccess        -- 緊急アクセス
    | SystemAvailability     -- システム可用性
    | RegulatoryCompliance   -- 規制準拠
    | CustomConstraint       -- カスタム制約
    deriving (Generic, Enum, GQLType)
```

**GraphQL:**
```graphql
enum ConstraintType {
  PrivacyProtection
  EmergencyAccess
  SystemAvailability
  RegulatoryCompliance
  CustomConstraint
}
```

---

### OptimizationType

最適化タイプ。

**設計判断:**
- 最小化/最大化の2種類のみ
- シンプルで直感的

```haskell
data OptimizationType
    = Minimize
    | Maximize
    deriving (Generic, Enum, GQLType)
```

---

## スキーマの拡張性

### 将来の拡張ポイント

#### 1. Subscription の追加

リアルタイム更新のサポート：

```haskell
data Subscription m = Subscription
    { optimizationProgress :: OptimizationProgressArgs -> m OptimizationProgress
    }
```

```graphql
subscription {
  optimizationProgress(id: "opt-001") {
    progress
    currentIteration
    currentObjectiveValue
  }
}
```

#### 2. ページネーション

大量のデータを扱う場合：

```graphql
type Query {
  spaces(first: Int, after: String): SpaceConnection!
}

type SpaceConnection {
  edges: [SpaceEdge!]!
  pageInfo: PageInfo!
}

type SpaceEdge {
  node: Space!
  cursor: String!
}

type PageInfo {
  hasNextPage: Boolean!
  endCursor: String
}
```

#### 3. Filter/Sort

検索・ソート機能：

```graphql
type Query {
  spaces(
    filter: SpaceFilterInput
    sort: SpaceSortInput
  ): [Space!]!
}

input SpaceFilterInput {
  dimensionMin: Int
  dimensionMax: Int
  constraintTypes: [ConstraintType!]
}

input SpaceSortInput {
  field: SpaceSortField!
  order: SortOrder!
}

enum SpaceSortField {
  CREATED_AT
  DIMENSION
  NAME
}

enum SortOrder {
  ASC
  DESC
}
```

---

## 型変換の戦略

### GraphQL型 ↔ MEDICUS Engine型

**将来の実装:**

```haskell
-- GraphQL → Engine
toEngineSpaceConfig :: SpaceConfigInput -> Engine.SpaceConfig
toEngineSpaceConfig input = Engine.SpaceConfig
    { Engine.dimension = dimension input
    , Engine.normWeights = toEngineNormWeights (normWeights input)
    , Engine.constraints = map toEngineConstraint (constraints input)
    }

-- Engine → GraphQL
fromEngineOptimizationResult :: Engine.OptimizationResult -> OptimizationResult
fromEngineOptimizationResult result = OptimizationResult
    { success = Engine.success result
    , solution = Engine.solution result
    , objectiveValue = Engine.objectiveValue result
    , ...
    }
```

---

## ベストプラクティス

### 1. Null Safety

```haskell
-- ❌ 避ける（Maybeの乱用）
data User = User
    { userId :: Maybe Int  -- IDはnullになるべきではない
    }

-- ✅ 推奨
data User = User
    { userId :: Int  -- 必須
    , email :: Maybe Text  -- オプショナル
    }
```

### 2. エラーハンドリング

```haskell
-- ❌ 避ける（例外をスロー）
resolveUser :: UserArgs -> IO User
resolveUser args = 
    if userId args <= 0
        then error "Invalid user ID"  -- 例外
        else fetchUser (userId args)

-- ✅ 推奨（エラーを返す）
data UserResult
    = UserSuccess User
    | UserError Text

resolveUser :: UserArgs -> IO UserResult
resolveUser args =
    if userId args <= 0
        then return $ UserError "Invalid user ID"
        else UserSuccess <$> fetchUser (userId args)
```

### 3. 命名規則

| 型の種類 | 命名規則 | 例 |
|---|---|---|
| Input型 | `*Input` | `SpaceConfigInput` |
| Output型 | 名詞 | `ValidationResult` |
| Args型 | `*Args` | `ValidateSpaceArgs` |
| Enum | 名詞 | `ConstraintType` |
| Query/Mutation | 動詞 | `validateSpace`, `createSpace` |

### 4. ドキュメンテーション

Haskellのコメントは自動的にGraphQLのdescriptionに変換されます：

```haskell
-- | ヘルスチェック結果
data HealthStatus = HealthStatus
    { status :: Text      -- ^ ステータス（"healthy" または "unhealthy"）
    , service :: Text     -- ^ サービス名
    , version :: Text     -- ^ バージョン
    , timestamp :: Text   -- ^ タイムスタンプ（ISO 8601形式）
    } deriving (Generic, GQLType)
```

---

## パフォーマンス最適化

### 1. N+1問題の回避（将来のDB統合時）

DataLoaderパターンの使用：

```haskell
-- ❌ N+1問題
resolveUsers :: [Int] -> IO [User]
resolveUsers userIds = mapM fetchUser userIds  -- 各IDごとにクエリ

-- ✅ バッチ取得
resolveUsers :: [Int] -> IO [User]
resolveUsers userIds = fetchUsersBatch userIds  -- 1回のクエリ
```

### 2. フィールド遅延評価

不要なフィールドは計算しない：

```haskell
data User = User
    { userId :: Int
    , userName :: Text
    , userProfile :: IO Profile  -- IO actionなので必要なときのみ実行
    }
```

### 3. キャッシング

静的データはキャッシュ：

```haskell
import Data.Cache

constraintsCache :: Cache Text [ConstraintType]
constraintsCache = ...

resolveListConstraints :: IO [ConstraintType]
resolveListConstraints = do
    cached <- Data.Cache.lookup constraintsCache "all"
    case cached of
        Just cs -> return cs
        Nothing -> do
            cs <- computeConstraints
            Data.Cache.insert constraintsCache "all" cs
            return cs
```

---

## テスト戦略

### 1. 型レベルテスト

Haskellの型システムによる自動検証：

```haskell
-- コンパイルが通れば型の整合性は保証される
validateSpaceQuery :: Query (Resolver QUERY () IO)
validateSpaceQuery = Query
    { validateSpace = \args -> lift $ resolveValidateSpace args
    }
```

### 2. プロパティベーステスト

QuickCheckを使用：

```haskell
import Test.QuickCheck

-- ノルムの重みの合計は常に1
prop_normWeightsSum :: NormWeightsInput -> Bool
prop_normWeightsSum w =
    abs (lambda w + mu w + nu w - 1.0) < 1e-10
```

### 3. GraphQLクエリテスト

```haskell
import Yesod.Test

spec :: Spec
spec = withApp $ do
    it "validates space configuration" $ do
        request $ do
            setMethod "POST"
            setUrl GraphQLR
            setRequestBody $ encode $ object
                [ "query" .= validationQuery
                ]
        
        statusIs 200
        bodyContains "\"valid\":true"
```

---

## ドキュメント生成

### Introspection クエリ

スキーマドキュメントの自動生成：

```graphql
query IntrospectionQuery {
  __schema {
    types {
      name
      kind
      description
      fields {
        name
        description
        type {
          name
          kind
        }
        args {
          name
          type {
            name
          }
        }
      }
    }
  }
}
```

### graphql-docgenの使用（将来）

```bash
# スキーマドキュメントのHTML生成
graphql-doc-gen --schema schema.graphql --output docs/
```

---

## マイグレーション戦略

### スキーマ変更のベストプラクティス

#### 1. 非破壊的変更

```haskell
-- ✅ 新しいフィールドを追加（既存のクライアントに影響なし）
data User = User
    { userId :: Int
    , userName :: Text
    , userEmail :: Maybe Text  -- 新規追加、オプショナル
    }
```

#### 2. Deprecation

```haskell
-- 古いフィールドを非推奨にマーク
data User = User
    { userId :: Int
    , userName :: Text  -- @deprecated: Use 'name' instead
    , name :: Text      -- 新しいフィールド
    }
```

#### 3. バージョニング

```haskell
-- 型にバージョンを持たせる
data UserV1 = UserV1 {...}
data UserV2 = UserV2 {...}

data Query m = Query
    { user :: UserArgs -> m User  -- 最新版を指す
    , userV1 :: UserArgs -> m UserV1  -- 後方互換性のため残す
    }
```

---

## セキュリティ考慮事項

### 1. Depth Limiting

深いネストを制限（将来の実装）：

```haskell
-- 最大深度を10に制限
maxQueryDepth :: Int
maxQueryDepth = 10
```

### 2. Query Complexity

クエリの複雑度を制限（将来の実装）：

```haskell
-- 複雑度の計算
queryComplexity :: Query -> Int
queryComplexity = ...

-- 最大複雑度
maxQueryComplexity :: Int
maxQueryComplexity = 1000
```

### 3. Rate Limiting

クライアントごとのレート制限（将来の実装）：

```haskell
-- 1時間あたり1000リクエスト
rateLimit :: Int
rateLimit = 1000
```

---

## 関連ドキュメント

- [03-graphql-integration.md](./03-graphql-integration.md) - morpheus-graphql統合
- [08-api-reference.md](./08-api-reference.md) - API完全リファレンス
- [04-yesod-graphql.md](./04-yesod-graphql.md) - Yesod統合

---

## まとめ

MEDICUS APIのGraphQLスキーマは以下の原則に基づいて設計されています：

1. **Type Safety** - Haskellの型システムによる静的検証
2. **Explicitness** - 明示的な型定義、暗黙的な変換を避ける
3. **Null Safety** - デフォルトでnon-nullable
4. **Separation** - Input/Output型の明確な分離
5. **Extensibility** - 将来の拡張を考慮した設計
6. **Documentation** - 自動生成されるドキュメント
7. **Performance** - 効率的なクエリ実行

これらの原則により、型安全で保守しやすく、拡張可能なGraphQL APIを実現しています。

---

**ドキュメント作成日:** 2026-03-07  
**最終更新日:** 2026-03-07
