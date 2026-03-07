# Design Document - MEDICUS API

## Overview

MEDICUS APIは、MEDICUS Engine（医療データセキュリティ最適化計算エンジン）をYesod + GraphQLベースのWeb APIとして提供します。Morpheus GraphQLによる型安全なスキーマ定義と、Yesodの堅牢なWeb基盤を組み合わせ、スケーラブルで保守性の高いAPIサーバーを実現します。

## Architecture

### System Architecture

```
┌─────────────────────────────────────────────────────────────┐
│                     Client Layer                            │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Web UI     │  │ GraphQL      │  │  API Client  │     │
│  │  (React/Vue) │  │  Playground  │  │   Library    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                      API Layer                              │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              Yesod Web Server                        │  │
│  │  ┌────────────────┐  ┌────────────────┐            │  │
│  │  │  HTTP Handler  │  │  CORS / Auth   │            │  │
│  │  │   (Routing)    │  │   (Middleware) │            │  │
│  │  └────────────────┘  └────────────────┘            │  │
│  └──────────────────────────────────────────────────────┘  │
│                            ▼                                │
│  ┌──────────────────────────────────────────────────────┐  │
│  │         Morpheus GraphQL Engine                      │  │
│  │  ┌────────────┐  ┌────────────┐  ┌──────────────┐  │  │
│  │  │  Schema    │  │  Resolver  │  │ Introspection│  │  │
│  │  │ Definition │  │   Router   │  │    Engine    │  │  │
│  │  └────────────┘  └────────────┘  └──────────────┘  │  │
│  └──────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                   Business Logic Layer                      │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │   Query      │  │   Mutation   │  │  Validation  │     │
│  │  Handlers    │  │   Handlers   │  │    Logic     │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  MEDICUS Engine Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │ Optimization │  │ Visualization│  │   Analysis   │     │
│  │   Engine     │  │    Engine    │  │    Engine    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
│          (medicus-engine library)                           │
└─────────────────────────────────────────────────────────────┘
                              ▼
┌─────────────────────────────────────────────────────────────┐
│                  Data Access Layer (Future)                 │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐     │
│  │  Persistent  │  │    Cache     │  │   Session    │     │
│  │  (Database)  │  │   (Redis)    │  │   Storage    │     │
│  └──────────────┘  └──────────────┘  └──────────────┘     │
└─────────────────────────────────────────────────────────────┘
```

### Module Structure

```
medicus-api/
├── src/
│   ├── Application.hs              # Yesodアプリケーション定義
│   ├── Foundation.hs               # App型、ルーティング基盤
│   ├── Settings.hs                 # 設定管理
│   ├── Import.hs                   # 共通インポート
│   │
│   ├── GraphQL/
│   │   ├── Schema.hs              # GraphQLスキーマ定義（型）
│   │   ├── Resolvers.hs           # トップレベルリゾルバ
│   │   ├── Query/
│   │   │   ├── Space.hs          # 空間関連クエリ
│   │   │   └── Health.hs         # ヘルスチェック
│   │   ├── Mutation/
│   │   │   ├── Space.hs          # 空間作成・削除
│   │   │   └── Optimization.hs  # 最適化実行
│   │   └── Types/
│   │       ├── Space.hs          # 空間関連型
│   │       ├── Optimization.hs  # 最適化関連型
│   │       ├── Error.hs          # エラー型
│   │       └── Common.hs         # 共通型
│   │
│   ├── Handler/
│   │   ├── GraphQL.hs             # GraphQLエンドポイント
│   │   ├── Health.hs              # ヘルスチェック
│   │   └── Playground.hs          # GraphQL Playground
│   │
│   ├── Service/
│   │   ├── Space.hs               # 空間ビジネスロジック
│   │   ├── Optimization.hs       # 最適化ビジネスロジック
│   │   └── Validation.hs         # バリデーションロジック
│   │
│   └── Util/
│       ├── Conversion.hs          # 型変換ユーティリティ
│       └── Error.hs               # エラーハンドリング
│
├── test/
│   ├── Spec.hs                    # テストエントリーポイント
│   ├── GraphQL/
│   │   ├── SchemaSpec.hs         # スキーマテスト
│   │   ├── QuerySpec.hs          # クエリテスト
│   │   └── MutationSpec.hs       # ミューテーションテスト
│   ├── Service/
│   │   ├── SpaceSpec.hs          # 空間サービステスト
│   │   ├── OptimizationSpec.hs  # 最適化サービステスト
│   │   └── ValidationSpec.hs    # バリデーションテスト
│   └── Integration/
│       └── E2ESpec.hs             # E2Eテスト
│
├── config/
│   ├── settings.yml               # 開発環境設定
│   ├── settings-prod.yml          # 本番環境設定
│   └── routes.txt                 # Yesodルーティング
│
├── static/
│   └── playground/                # GraphQL Playground静的ファイル
│
└── medicus-api.cabal
```

## Core Components

### 1. GraphQL Schema Definition

Morpheus GraphQLを使用した型安全なスキーマ定義。

```haskell
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}
{-# LANGUAGE TypeFamilies #-}

module GraphQL.Schema where

import Data.Morpheus.Types
import GHC.Generics

-- ルートリゾルバ
data Query m = Query
  { validateSpace :: ValidateSpaceArgs -> m ValidationResult
  , listAvailableConstraints :: m [ConstraintType]
  , health :: m HealthStatus
  } deriving (Generic, GQLType)

-- 将来の拡張（Phase 4以降）:
-- , getSpaceInfo :: GetSpaceInfoArgs -> m (Maybe SpaceInfo)
-- , plotConvergence :: PlotConvergenceArgs -> m ConvergencePlotData
-- , visualizeConstraints :: VisualizeConstraintsArgs -> m ConstraintVisualization
-- 詳細は future-enhancements.md を参照

data Mutation m = Mutation
  { createSpace :: CreateSpaceArgs -> m CreateSpaceResult
  , deleteSpace :: DeleteSpaceArgs -> m Bool
  , optimize :: OptimizeArgs -> m OptimizationResult
  } deriving (Generic, GQLType)

-- 入力型
data CreateSpaceArgs = CreateSpaceArgs
  { config :: SpaceConfigInput
  } deriving (Generic, GQLType)

data SpaceConfigInput = SpaceConfigInput
  { dimension :: Int
  , normWeights :: NormWeightsInput
  , constraints :: [ConstraintInput]
  } deriving (Generic, GQLType)

data NormWeightsInput = NormWeightsInput
  { lambda :: Double
  , mu :: Double
  , nu :: Double
  } deriving (Generic, GQLType)

-- 出力型
data SpaceInfo = SpaceInfo
  { id :: ID
  , dimension :: Int
  , constraintCount :: Int
  , normWeights :: NormWeights
  , createdAt :: DateTime
  } deriving (Generic, GQLType)

data ValidationResult = ValidationResult
  { valid :: Bool
  , errors :: [ValidationError]
  , warnings :: [ValidationWarning]
  } deriving (Generic, GQLType)

data OptimizationResult = OptimizationResult
  { success :: Bool
  , solution :: [Double]
  , objectiveValue :: Double
  , iterations :: Int
  , converged :: Bool
  , message :: Maybe Text
  , constraintViolations :: [ConstraintViolation]
  , convergenceHistory :: Maybe ConvergenceHistory
  , computationTimeMs :: Int
  } deriving (Generic, GQLType)
```

### 2. Resolver Implementation

```haskell
module GraphQL.Resolvers where

import qualified Service.Space as SpaceService
import qualified Service.Optimization as OptService

resolveQuery :: Query (ResolverQ e m)
resolveQuery = Query
  { validateSpace = resolveValidateSpace
  , listAvailableConstraints = resolveListConstraints
  , health = resolveHealth
  }

resolveMutation :: Mutation (ResolverM e m)
resolveMutation = Mutation
  { createSpace = resolveCreateSpace
  , deleteSpace = resolveDeleteSpace
  , optimize = resolveOptimize
  }

-- クエリリゾルバ
resolveValidateSpace :: ValidateSpaceArgs -> ResolverQ e m ValidationResult
resolveValidateSpace args = do
  let config = convertSpaceConfig (config args)
  result <- lift $ SpaceService.validateSpace config
  return $ convertValidationResult result

resolveHealth :: ResolverQ e m HealthStatus
resolveHealth = do
  return $ HealthStatus
    { status = "healthy"
    , version = "0.1.0"
    , timestamp = getCurrentTime
    }

-- ミューテーションリゾルバ
resolveCreateSpace :: CreateSpaceArgs -> ResolverM e m CreateSpaceResult
resolveCreateSpace args = do
  let config = convertSpaceConfig (config args)
  result <- lift $ SpaceService.createSpace config
  case result of
    Right space -> return $ CreateSpaceResult
      { spaceId = generateSpaceId space
      , success = True
      , message = Nothing
      }
    Left err -> return $ CreateSpaceResult
      { spaceId = ""
      , success = False
      , message = Just (toErrorMessage err)
      }

resolveOptimize :: OptimizeArgs -> ResolverM e m OptimizationResult
resolveOptimize args = do
  startTime <- getCurrentTime
  result <- lift $ OptService.runOptimization args
  endTime <- getCurrentTime
  let computationTime = diffTimeToMillis (endTime - startTime)
  return $ convertOptimizationResult result computationTime
```

### 3. Service Layer (Business Logic)

```haskell
module Service.Space where

import qualified MEDICUS.API as MEDICUS

-- 空間作成
createSpace :: SpaceConfig -> IO (Either MEDICUSError MedicusSpace)
createSpace config = do
  -- MEDICUS.APIを使用
  case MEDICUS.createSpace config of
    MEDICUS.Ok space -> return $ Right space
    MEDICUS.Error err -> return $ Left (convertError err)

-- 空間検証
validateSpace :: SpaceConfig -> IO ValidationResult
validateSpace config = do
  -- バリデーションロジック
  let dimErrors = validateDimension (dimension config)
      normErrors = validateNormWeights (normWeights config)
      constraintErrors = validateConstraints (constraints config)
      allErrors = dimErrors ++ normErrors ++ constraintErrors
  return $ ValidationResult
    { valid = null allErrors
    , errors = allErrors
    , warnings = generateWarnings config
    }

-- バリデーションヘルパー
validateDimension :: Int -> [ValidationError]
validateDimension dim
  | dim <= 0 = [ValidationError "dimension" "Must be positive" InvalidDimension]
  | dim > 10000 = [ValidationError "dimension" "Too large (max 10000)" InvalidDimension]
  | otherwise = []

validateNormWeights :: NormWeights -> [ValidationError]
validateNormWeights weights
  | lambda weights < 0 = [ValidationError "normWeights.lambda" "Must be non-negative" InvalidNormWeights]
  | mu weights < 0 = [ValidationError "normWeights.mu" "Must be non-negative" InvalidNormWeights]
  | nu weights < 0 = [ValidationError "normWeights.nu" "Must be non-negative" InvalidNormWeights]
  | otherwise = []
```

### 4. Yesod Application Foundation

```haskell
{-# LANGUAGE TemplateHaskell #-}
{-# LANGUAGE QuasiQuotes #-}
{-# LANGUAGE TypeFamilies #-}
{-# LANGUAGE MultiParamTypeClasses #-}

module Foundation where

import Yesod
import Yesod.Core.Types (Logger)

-- アプリケーション型
data App = App
  { appLogger :: Logger
  , appSettings :: AppSettings
  -- 将来追加:
  -- , appConnectionPool :: ConnectionPool
  -- , appHttpManager :: Manager
  }

-- ルーティング定義
mkYesodData "App" $(parseRoutesFile "config/routes.txt")

-- Yesodインスタンス
instance Yesod App where
  -- アプリケーション設定
  approot = ApprootRequest $ \app req ->
    case appRoot (appSettings app) of
      Nothing -> getApprootText guessApproot app req
      Just root -> root
  
  -- CORSサポート
  yesodMiddleware = defaultYesodMiddleware . defaultCsrfMiddleware
  
  -- エラーハンドリング
  errorHandler NotFound = selectRep $ do
    provideRep $ return $ object ["error" .= String "Not Found"]
  errorHandler other = defaultErrorHandler other

-- ロギング
instance YesodLog App where
  messageLoggerSource app logger loc source level msg =
    defaultMessageLoggerSource app logger loc source level msg
```

### 5. Configuration Management

```haskell
module Settings where

import Data.Aeson
import Data.Yaml

data AppSettings = AppSettings
  { appPort :: Int
  , appHost :: Text
  , appDevelopment :: Bool
  , appGraphQLEndpoint :: Text
  , appPlaygroundEnabled :: Bool
  , appCorsEnabled :: Bool
  , appCorsOrigins :: [Text]
  , appMaxQueryDepth :: Int
  , appRateLimitEnabled :: Bool
  } deriving (Show)

instance FromJSON AppSettings where
  parseJSON = withObject "AppSettings" $ \o -> do
    appPort <- o .: "port"
    appHost <- o .: "host"
    appDevelopment <- o .:? "development" .!= False
    appGraphQLEndpoint <- o .:? "graphql-endpoint" .!= "/graphql"
    appPlaygroundEnabled <- o .:? "playground-enabled" .!= True
    appCorsEnabled <- o .:? "cors-enabled" .!= True
    appCorsOrigins <- o .:? "cors-origins" .!= ["*"]
    appMaxQueryDepth <- o .:? "max-query-depth" .!= 10
    appRateLimitEnabled <- o .:? "rate-limit-enabled" .!= False
    return AppSettings {..}

loadSettings :: FilePath -> IO AppSettings
loadSettings path = do
  result <- decodeFileEither path
  case result of
    Left err -> error $ "Failed to load settings: " ++ show err
    Right settings -> return settings
```

## GraphQL Schema (Complete)

### Query Type

```graphql
type Query {
  """空間設定の検証"""
  validateSpace(config: SpaceConfigInput!): ValidationResult!
  
  """利用可能な制約タイプの一覧"""
  listAvailableConstraints: [ConstraintType!]!
  
  """ヘルスチェック"""
  health: HealthStatus!
}

# 将来の拡張（Phase 4以降）
# - getSpaceInfo: DB統合後に実装
# - plotConvergence, visualizeConstraints, exploreParameterSpace: UI実装時に追加
# - generateReport: レポート機能実装時に追加
# 詳細は future-enhancements.md を参照
```

### Mutation Type

```graphql
type Mutation {
  """MEDICUS空間の作成"""
  createSpace(config: SpaceConfigInput!): CreateSpaceResult!
  
  """MEDICUS空間の削除"""
  deleteSpace(spaceId: ID!): Boolean!
  
  """最適化の実行"""
  optimize(input: OptimizationInput!): OptimizationResult!
  
  """バッチ最適化の実行"""
  optimizeBatch(inputs: [OptimizationInput!]!): [OptimizationResult!]!
}
```

### Input Types

```graphql
input SpaceConfigInput {
  dimension: Int!
  normWeights: NormWeightsInput!
  constraints: [ConstraintInput!]!
}

input NormWeightsInput {
  lambda: Float!
  mu: Float!
  nu: Float!
}

input ConstraintInput {
  type: ConstraintType!
  threshold: Float!
  parameters: JSON
}

input OptimizationInput {
  spaceId: ID!
  objective: ObjectiveFunctionInput!
  initialPoint: [Float!]!
  options: OptimizationOptions
}

input ObjectiveFunctionInput {
  type: ObjectiveType!
  parameters: JSON!
}

input OptimizationOptions {
  maxIterations: Int
  tolerance: Float
  timeoutSeconds: Int
  parallelEvaluation: Boolean
}
```

### Output Types

```graphql
type SpaceInfo {
  id: ID!
  dimension: Int!
  constraintCount: Int!
  normWeights: NormWeights!
  createdAt: DateTime!
}

type NormWeights {
  lambda: Float!
  mu: Float!
  nu: Float!
}

type ValidationResult {
  valid: Boolean!
  errors: [ValidationError!]!
  warnings: [ValidationWarning!]!
}

type ValidationError {
  field: String!
  message: String!
  errorCode: ErrorCode!
}

type OptimizationResult {
  success: Boolean!
  solution: [Float!]!
  objectiveValue: Float!
  iterations: Int!
  converged: Boolean!
  message: String
  constraintViolations: [ConstraintViolation!]!
  convergenceHistory: ConvergenceHistory
  computationTimeMs: Int!
}

type ConvergenceHistory {
  objectiveValues: [Float!]!
  constraintViolations: [Float!]!
  iterations: [Int!]!
}

type ConstraintViolation {
  constraintId: String!
  violation: Float!
  description: String!
}
```

### Enum Types

```graphql
enum ConstraintType {
  PRIVACY_PROTECTION
  EMERGENCY_ACCESS
  SYSTEM_AVAILABILITY
  REGULATORY_COMPLIANCE
  CUSTOM
}

enum ObjectiveType {
  LINEAR
  QUADRATIC
  NONLINEAR
  CUSTOM
}

enum ErrorCode {
  INVALID_DIMENSION
  INVALID_CONSTRAINT
  INVALID_NORM_WEIGHTS
  NUMERICAL_INSTABILITY
  CONVERGENCE_FAILURE
  RESOURCE_NOT_FOUND
  INTERNAL_ERROR
}
```

## Data Flow

### Optimization Request Flow

```
1. Client sends GraphQL mutation:
   mutation {
     optimize(input: {...}) {
       success
       solution
       objectiveValue
     }
   }

2. Yesod Handler receives HTTP POST /graphql

3. Morpheus GraphQL parses and validates query
   - Schema validation
   - Type checking

4. Resolver (resolveOptimize) is called
   - Extract arguments
   - Convert GraphQL types to Haskell types

5. Service Layer (Service.Optimization)
   - Validate input
   - Call MEDICUS Engine API

6. MEDICUS Engine executes optimization
   - Newton method
   - Constraint checking
   - Convergence detection

7. Result flows back:
   Service -> Resolver -> GraphQL Engine -> HTTP Response

8. Client receives JSON response:
   {
     "data": {
       "optimize": {
         "success": true,
         "solution": [0.5, 0.3, ...],
         "objectiveValue": 1.234
       }
     }
   }
```

## Type Conversion Strategy

### GraphQL ↔ MEDICUS Engine

```haskell
module Util.Conversion where

import qualified MEDICUS.API as MEDICUS
import qualified GraphQL.Types as GQL

-- 空間設定の変換
toMEDICUSSpaceConfig :: GQL.SpaceConfigInput -> MEDICUS.SpaceConfig
toMEDICUSSpaceConfig input = MEDICUS.SpaceConfig
  { MEDICUS.dimension = GQL.dimension input
  , MEDICUS.normWeights = toMEDICUSNormWeights (GQL.normWeights input)
  , MEDICUS.constraints = map toMEDICUSConstraint (GQL.constraints input)
  }

-- ノルム重みの変換
toMEDICUSNormWeights :: GQL.NormWeightsInput -> MEDICUS.NormWeights
toMEDICUSNormWeights input = MEDICUS.NormWeights
  { MEDICUS.lambda = GQL.lambda input
  , MEDICUS.mu = GQL.mu input
  , MEDICUS.nu = GQL.nu input
  }

-- 最適化結果の変換
fromMEDICUSOptimizationResult 
  :: MEDICUS.OptimizationResult 
  -> Int  -- computation time
  -> GQL.OptimizationResult
fromMEDICUSOptimizationResult result computeTime = GQL.OptimizationResult
  { GQL.success = MEDICUS.converged result
  , GQL.solution = MEDICUS.solution result
  , GQL.objectiveValue = MEDICUS.objectiveValue result
  , GQL.iterations = MEDICUS.iterations result
  , GQL.converged = MEDICUS.converged result
  , GQL.message = MEDICUS.message result
  , GQL.constraintViolations = map fromConstraintViolation (MEDICUS.violations result)
  , GQL.convergenceHistory = fmap fromConvergenceHistory (MEDICUS.history result)
  , GQL.computationTimeMs = computeTime
  }
```

## Error Handling

### Error Types Hierarchy

```haskell
module GraphQL.Types.Error where

data MEDICUSAPIError
  = ValidationError ValidationErrorData
  | ComputationError ComputationErrorData
  | ResourceNotFound ResourceNotFoundData
  | InternalError InternalErrorData
  deriving (Show, Eq, Generic)

data ValidationErrorData = ValidationErrorData
  { validationField :: Text
  , validationMessage :: Text
  , validationCode :: ErrorCode
  } deriving (Show, Eq, Generic, GQLType)

-- GraphQLエラーへの変換
toGraphQLError :: MEDICUSAPIError -> GQLError
toGraphQLError (ValidationError err) = GQLError
  { message = validationMessage err
  , locations = []
  , path = [validationField err]
  , extensions = Just $ object
      [ "code" .= validationCode err
      , "field" .= validationField err
      ]
  }
```

## Testing Strategy

### 1. Unit Tests

```haskell
-- test/Service/SpaceSpec.hs
module Service.SpaceSpec where

import Test.Hspec
import Service.Space

spec :: Spec
spec = do
  describe "validateSpace" $ do
    it "accepts valid space config" $ do
      let config = validSpaceConfig
      result <- validateSpace config
      valid result `shouldBe` True
      errors result `shouldBe` []
    
    it "rejects negative dimension" $ do
      let config = validSpaceConfig { dimension = -1 }
      result <- validateSpace config
      valid result `shouldBe` False
      errors result `shouldNotBe` []
```

### 2. GraphQL Schema Tests

```haskell
-- test/GraphQL/SchemaSpec.hs
module GraphQL.SchemaSpec where

import Test.Hspec
import Data.Morpheus.Types (validateSchema)

spec :: Spec
spec = do
  describe "GraphQL Schema" $ do
    it "is valid" $ do
      let result = validateSchema schema
      result `shouldBe` Valid
    
    it "has all required queries" $ do
      let queries = schemaQueries schema
      queries `shouldContain` ["validateSpace", "optimize"]
```

### 3. Integration Tests

```haskell
-- test/Integration/E2ESpec.hs
module Integration.E2ESpec where

import Test.Hspec
import Yesod.Test

spec :: Spec
spec = withApp $ do
  describe "GraphQL endpoint" $ do
    it "handles optimization mutation" $ do
      request $ do
        setMethod "POST"
        setUrl GraphQLR
        setRequestBody $ encode optimizationQuery
      
      statusIs 200
      bodyContains "\"success\":true"
```

## Performance Considerations

### 1. Query Complexity

```haskell
-- GraphQLクエリの深さ制限
maxQueryDepth :: Int
maxQueryDepth = 10

-- クエリコスト計算
data QueryCost = QueryCost
  { depth :: Int
  , nodeCount :: Int
  , estimatedTime :: Int  -- milliseconds
  }

calculateQueryCost :: GraphQLQuery -> QueryCost
```

### 2. Parallel Processing

```haskell
-- バッチ最適化の並列実行
optimizeBatch :: [OptimizationInput] -> IO [OptimizationResult]
optimizeBatch inputs = do
  -- MEDICUS.APIのparallelEvaluateを活用
  results <- parallel $ map runSingleOptimization inputs
  return results
```

### 3. Caching Strategy (Future)

```
- Query Result Caching (Redis)
  - Key: hash(query + variables)
  - TTL: configurable per query type
  
- Space Configuration Caching
  - In-memory LRU cache
  - Invalidation on update/delete
  
- GraphQL Schema Caching
  - Introspection結果のキャッシュ
  - 起動時に1回生成
```

## Deployment Architecture

### Development

```yaml
# docker-compose.yml
version: '3.8'
services:
  api:
    build: .
    ports:
      - "3000:3000"
    environment:
      - YESOD_ENV=development
    volumes:
      - ./config:/app/config
```

### Production (Future)

```
┌─────────────┐
│  Load       │
│  Balancer   │
└──────┬──────┘
       │
   ┌───┴────┐
   │        │
┌──▼──┐  ┌─▼───┐
│ API │  │ API │
│  1  │  │  2  │
└──┬──┘  └──┬──┘
   │        │
   └────┬───┘
        │
   ┌────▼────┐
   │ Redis   │
   │ Cache   │
   └────┬────┘
        │
   ┌────▼────┐
   │ Postgres│
   │   DB    │
   └─────────┘
```

## Configuration Files

### config/settings.yml

```yaml
# Development settings
port: 3000
host: "localhost"
development: true

graphql-endpoint: "/graphql"
playground-enabled: true

cors-enabled: true
cors-origins:
  - "*"

max-query-depth: 10
rate-limit-enabled: false

logging:
  level: DEBUG
  format: JSON
```

### config/settings-prod.yml

```yaml
# Production settings
port: 8080
host: "0.0.0.0"
development: false

graphql-endpoint: "/graphql"
playground-enabled: false

cors-enabled: true
cors-origins:
  - "https://app.example.com"

max-query-depth: 8
rate-limit-enabled: true
rate-limit: 100  # requests per minute

logging:
  level: INFO
  format: JSON
```

### config/routes.txt

```
/graphql GraphQLR POST
/playground PlaygroundR GET
/health HealthR GET
/static StaticR Static appStatic
```

## Security Considerations

### 1. Input Validation

- すべてのGraphQL入力を厳密に検証
- 次元数の上限チェック（DoS対策）
- 数値範囲の検証

### 2. Query Complexity Limits

- クエリ深さの制限
- フィールド数の制限
- タイムアウト設定

### 3. CORS Configuration

- 本番環境では特定オリジンのみ許可
- Credentialsの適切な処理

### 4. Rate Limiting (Future)

- IPベースのレート制限
- ユーザーベースのレート制限（認証後）

## Future Enhancements

このdesign.mdは、Phase 1-3（MVPとコア機能）の設計を対象としています。
以下の機能は将来的な拡張として [`future-enhancements.md`](./future-enhancements.md) で詳細に記載されています。

### Phase 1-3 Scope (Current)
- [x] Yesod + GraphQL基盤
- [ ] 空間操作API（作成、検証）
- [ ] 最適化実行API
- [ ] エラーハンドリング
- [ ] テスト（ユニット、統合、E2E）
- [ ] ドキュメント
- [ ] Docker化

### Phase 4+: Future Features
1. **データ可視化API** (Phase 4)
   - 収束プロット、制約可視化、パラメータ空間探索
   - UI実装時に必要
   
2. **データベース統合** (Phase 5)
   - Persistent + PostgreSQL
   - 最適化履歴の保存
   - 空間設定のライブラリ機能
   
3. **認証・認可** (Phase 6)
   - JWT認証
   - ロールベースアクセス制御
   
4. **キャッシング** (Phase 7)
   - Redis統合
   - クエリ結果キャッシュ
   
5. **リアルタイム通知** (Phase 8)
   - GraphQL Subscriptions
   - WebSocket統合
   
6. **管理UI・モニタリング** (Phase 9)
   - Yesod Templates
   - Prometheusメトリクス
   
7. **マイクロサービス化** (Phase 10)
   - 長期的なスケーリング対応

詳細な要件、設計、実装タスクは [`future-enhancements.md`](./future-enhancements.md) を参照してください。

---

**Last Updated:** 2026-03-07  
**Version:** 0.1.0  
**Status:** Draft
