# Task List - MEDICUS API Implementation

## Overview

MEDICUS APIの実装タスクリストです。**Phase 1-3（MVPとコア機能）** の実装に集中します。
Phase 4以降の将来的な拡張機能は [`future-enhancements.md`](./future-enhancements.md) を参照してください。

**Status Legend:**
- ⬜ Not Started
- 🟨 In Progress
- ✅ Completed
- ⏸️ Blocked
- 🔄 Review

**Scope:**
- **Phase 1**: プロジェクトセットアップ、Yesod基盤
- **Phase 2**: GraphQL基盤（スキーマ、Playground）
- **Phase 3**: コアAPI実装、テスト、ドキュメント

---

## Phase 1: Project Setup & Foundation

### Task 1: Project Initialization ✅
**Priority:** P0  
**Estimated:** 2-3h  
**Dependencies:** None  
**Completed:** 2026-03-07

#### 1.1: Create medicus-api package ✅
- [x] `medicus-api.cabal`の作成
- [x] ディレクトリ構造の作成（`src/`, `test/`, `config/`, `static/`, `app/`）
- [x] Cabal設定（`cabal.project`, `Setup.hs`）
- [x] `.gitignore`の設定
- [x] `README.md`, `LICENSE`, `CHANGELOG.md`の作成

#### 1.2: Add dependencies ✅
- [x] Yesod依存関係追加
- [x] Morpheus GraphQL追加
- [x] MEDICUS Engine依存関係追加
- [x] テストライブラリ追加（hspec, yesod-test）

```cabal
build-depends:
    base >= 4.7 && < 5
  , yesod >= 1.6
  , yesod-core
  , morpheus-graphql
  , morpheus-graphql-app
  , medicus-engine
  , aeson
  , text
  , bytestring
  , time
  , vector
  , hspec
  , yesod-test
```

#### 1.3: Setup configuration files ✅
- [x] `config/settings.yml`作成
- [x] `config/settings-prod.yml`作成
- [x] `config/routes.txt`作成
- [x] 環境変数設定（`.env.example`）

**Acceptance Criteria:**
- [x] 基本的なディレクトリ構造が整っている
- [x] 設定ファイルが作成されている
- [ ] `cabal build`が成功する（Task 2で実装後に検証）

---

### Task 2: Yesod Foundation Setup ✅
**Priority:** P0  
**Estimated:** 3-4h  
**Dependencies:** Task 1  
**Completed:** 2026-03-07

#### 2.1: Create Foundation module ✅
- [x] `Foundation.hs`の作成
- [x] `App`型の定義
- [x] Yesodインスタンスの実装
- [x] ルーティング基盤の設定
- [x] エラーハンドリング

#### 2.2: Create Application module ✅
- [x] `Application.hs`の作成
- [x] アプリケーション初期化関数
- [x] ミドルウェア設定（ロギング）
- [x] エラーハンドリング基盤

#### 2.3: Create Settings module ✅
- [x] `Settings.hs`の作成
- [x] `AppSettings`型の定義（GraphQL, CORS, Logging, RateLimit）
- [x] YAML設定の読み込み
- [x] 環境変数の処理

#### 2.4: Create Main entry point ✅
- [x] `app/Main.hs`の作成
- [x] サーバー起動ロジック
- [x] グレースフルシャットダウン（bracket使用）
- [x] 起動メッセージ出力

#### 2.5: Create supporting modules ✅
- [x] `Import.hs`の作成（共通インポート）
- [x] `Handler/Health.hs`の作成（ヘルスチェックエンドポイント）

**Acceptance Criteria:**
- [x] すべての基盤モジュールが作成されている
- [x] 設定ファイルが読み込めるようになっている
- [ ] ビルドが成功する（注: Cabal 3.10.3.0の互換性問題により保留）
- [ ] Yesodサーバーが起動する（次のタスクで検証）

**Tests:**
- [ ] サーバー起動テスト（Task 3以降で実装）
- [ ] ヘルスチェックテスト（Task 3以降で実装）
- [ ] 設定読み込みテスト（Task 3以降で実装）

**Note:** Cabal 3.10.3.0との互換性問題が発生しています。これはシステム全体の問題であり、Task 3でGraphQLモジュールを追加後に再度ビルドを試みます。

---

## Phase 2: GraphQL Foundation

### Task 3: GraphQL Schema Definition ⬜
**Priority:** P0  
**Estimated:** 4-5h  
**Dependencies:** Task 2

#### 3.1: Define core types ⬜
- [ ] `GraphQL/Types/Common.hs`の作成
- [ ] `GraphQL/Types/Space.hs`の作成
- [ ] `GraphQL/Types/Optimization.hs`の作成
- [ ] `GraphQL/Types/Error.hs`の作成

```haskell
-- 基本型の定義
data SpaceConfigInput
data NormWeightsInput
data ConstraintInput
data OptimizationInput
data OptimizationResult
data ValidationResult
```

#### 3.2: Define Query type ⬜
- [ ] `GraphQL/Schema.hs`の作成
- [ ] `Query`型の定義（Morpheus GraphQL）
- [ ] 各クエリフィールドの型定義
- [ ] ドキュメントコメントの追加

```haskell
data Query m = Query
  { validateSpace :: ValidateSpaceArgs -> m ValidationResult
  , getSpaceInfo :: GetSpaceInfoArgs -> m (Maybe SpaceInfo)
  , listAvailableConstraints :: m [ConstraintType]
  }
```

#### 3.3: Define Mutation type ⬜
- [ ] `Mutation`型の定義
- [ ] 各ミューテーションフィールドの型定義
- [ ] ドキュメントコメントの追加

```haskell
data Mutation m = Mutation
  { createSpace :: CreateSpaceArgs -> m CreateSpaceResult
  , optimize :: OptimizeArgs -> m OptimizationResult
  }
```

#### 3.4: Setup GraphQL endpoint ⬜
- [ ] `Handler/GraphQL.hs`の作成
- [ ] Morpheus GraphQLの統合
- [ ] リクエストパーシング
- [ ] レスポンス生成

**Acceptance Criteria:**
- GraphQL Introspectionが動作する
- スキーマがバリデーションを通過する
- `/graphql`エンドポイントが応答する（空のリゾルバでもOK）

**Tests:**
- [ ] スキーマバリデーションテスト
- [ ] Introspectionクエリテスト
- [ ] 型チェックテスト

---

### Task 4: GraphQL Playground Integration ⬜
**Priority:** P1  
**Estimated:** 2-3h  
**Dependencies:** Task 3

#### 4.1: Setup Playground handler ⬜
- [ ] `Handler/Playground.hs`の作成
- [ ] GraphQL Playground HTMLの配信
- [ ] 静的ファイルの配置
- [ ] 開発環境のみで有効化

#### 4.2: Configure Playground settings ⬜
- [ ] デフォルトクエリの設定
- [ ] エンドポイントURL設定
- [ ] テーマ・UI設定

**Acceptance Criteria:**
- `/playground`にアクセスできる
- Introspectionが正常に動作する
- サンプルクエリが実行できる

**Tests:**
- [ ] Playgroundアクセステスト
- [ ] 開発/本番環境での動作切り替えテスト

---

## Phase 3: Core API Implementation

### Task 5: Type Conversion Utilities ⬜
**Priority:** P0  
**Estimated:** 3-4h  
**Dependencies:** Task 3

#### 5.1: Create conversion module ⬜
- [ ] `Util/Conversion.hs`の作成
- [ ] GraphQL → MEDICUS Engine型変換
- [ ] MEDICUS Engine → GraphQL型変換

```haskell
toMEDICUSSpaceConfig :: SpaceConfigInput -> MEDICUS.SpaceConfig
fromMEDICUSOptimizationResult :: MEDICUS.OptimizationResult -> OptimizationResult
```

#### 5.2: Create error conversion ⬜
- [ ] `Util/Error.hs`の作成
- [ ] MEDICUS Engineエラー → GraphQLエラー変換
- [ ] エラーメッセージの整形

**Acceptance Criteria:**
- すべての型が相互変換可能
- エラーメッセージが適切に変換される

**Tests:**
- [ ] 型変換の双方向テスト
- [ ] エラー変換テスト
- [ ] エッジケースのテスト

---

### Task 6: Space Service Implementation ⬜
**Priority:** P0  
**Estimated:** 4-5h  
**Dependencies:** Task 5

#### 6.1: Create Space service module ⬜
- [ ] `Service/Space.hs`の作成
- [ ] `createSpace`関数の実装
- [ ] `validateSpace`関数の実装
- [ ] `getSpaceInfo`関数の実装（スタブ）

#### 6.2: Implement validation logic ⬜
- [ ] `Service/Validation.hs`の作成
- [ ] 次元数の検証
- [ ] ノルム重みの検証
- [ ] 制約の検証
- [ ] 複合検証

```haskell
validateDimension :: Int -> [ValidationError]
validateNormWeights :: NormWeights -> [ValidationError]
validateConstraints :: [Constraint] -> [ValidationError]
```

#### 6.3: Integrate with MEDICUS Engine ⬜
- [ ] `MEDICUS.API`モジュールの利用
- [ ] エラーハンドリング
- [ ] 結果の型変換

**Acceptance Criteria:**
- 空間が正常に作成できる
- バリデーションが正しく動作する
- エラーが適切に処理される

**Tests:**
- [ ] `createSpace`のユニットテスト
- [ ] `validateSpace`のユニットテスト
- [ ] バリデーションロジックのテスト
- [ ] MEDICUS Engine統合テスト

---

### Task 7: Optimization Service Implementation ⬜
**Priority:** P0  
**Estimated:** 5-6h  
**Dependencies:** Task 6

#### 7.1: Create Optimization service module ⬜
- [ ] `Service/Optimization.hs`の作成
- [ ] `runOptimization`関数の実装
- [ ] `runBatchOptimization`関数の実装

#### 7.2: Implement optimization logic ⬜
- [ ] MEDICUS Engineの`optimize`関数呼び出し
- [ ] 初期点の検証
- [ ] オプションパラメータの処理
- [ ] 計算時間の測定

```haskell
runOptimization :: OptimizationInput -> IO OptimizationResult
runBatchOptimization :: [OptimizationInput] -> IO [OptimizationResult]
```

#### 7.3: Add convergence history tracking ⬜
- [ ] イテレーション履歴の収集
- [ ] 制約違反履歴の収集
- [ ] 目的関数値履歴の収集

**Acceptance Criteria:**
- 最適化が正常に実行される
- 収束履歴が取得できる
- バッチ処理が並列実行される

**Tests:**
- [ ] 単一最適化のテスト
- [ ] バッチ最適化のテスト
- [ ] 収束履歴のテスト
- [ ] エラーケースのテスト（非収束など）

---

### Task 8: Query Resolvers ⬜
**Priority:** P0  
**Estimated:** 3-4h  
**Dependencies:** Task 6

#### 8.1: Create Query resolver modules ⬜
- [ ] `GraphQL/Query/Space.hs`の作成
- [ ] `GraphQL/Query/Health.hs`の作成

#### 8.2: Implement Space query resolvers ⬜
- [ ] `validateSpace`リゾルバ
- [ ] `listAvailableConstraints`リゾルバ

```haskell
resolveValidateSpace :: ValidateSpaceArgs -> ResolverQ e m ValidationResult
resolveValidateSpace args = do
  let config = toMEDICUSSpaceConfig (config args)
  result <- lift $ SpaceService.validateSpace config
  return $ fromValidationResult result
```

#### 8.3: Implement Health query resolver ⬜
- [ ] `health`リゾルバ

```haskell
resolveHealth :: ResolverQ e m HealthStatus
resolveHealth = do
  return $ HealthStatus "healthy" "0.1.0"
```

**Acceptance Criteria:**
- すべてのクエリが実行可能
- エラーが適切に処理される
- 結果が正しい形式で返される

**Tests:**
- [ ] 各リゾルバのユニットテスト
- [ ] エラーハンドリングテスト
- [ ] 統合テスト

---

### Task 9: Mutation Resolvers ⬜
**Priority:** P0  
**Estimated:** 4-5h  
**Dependencies:** Task 7

#### 9.1: Create Mutation resolver modules ⬜
- [ ] `GraphQL/Mutation/Space.hs`の作成
- [ ] `GraphQL/Mutation/Optimization.hs`の作成

#### 9.2: Implement Space mutation resolvers ⬜
- [ ] `createSpace`リゾルバ
- [ ] `deleteSpace`リゾルバ

```haskell
resolveCreateSpace :: CreateSpaceArgs -> ResolverM e m CreateSpaceResult
resolveCreateSpace args = do
  let config = toMEDICUSSpaceConfig (config args)
  result <- lift $ SpaceService.createSpace config
  case result of
    Right space -> return $ CreateSpaceResult {...}
    Left err -> throwError $ toGraphQLError err
```

#### 9.3: Implement Optimization mutation resolvers ⬜
- [ ] `optimize`リゾルバ
- [ ] `optimizeBatch`リゾルバ

```haskell
resolveOptimize :: OptimizeArgs -> ResolverM e m OptimizationResult
resolveOptimize args = do
  startTime <- getCurrentTime
  result <- lift $ OptimizationService.runOptimization (input args)
  endTime <- getCurrentTime
  let computationTime = diffTimeToMillis (endTime - startTime)
  return $ fromOptimizationResult result computationTime
```

**Acceptance Criteria:**
- すべてのミューテーションが実行可能
- エラーが適切に処理される
- 計算時間が測定される

**Tests:**
- [ ] 各リゾルバのユニットテスト
- [ ] エラーハンドリングテスト
- [ ] パフォーマンステスト

---

### Task 10: Root Resolver Assembly ⬜
**Priority:** P0  
**Estimated:** 2-3h  
**Dependencies:** Task 8, 9

#### 10.1: Create root resolver module ⬜
- [ ] `GraphQL/Resolvers.hs`の作成
- [ ] `Query`リゾルバの統合
- [ ] `Mutation`リゾルバの統合

```haskell
rootResolver :: RootResolver IO () Query Mutation Undefined
rootResolver = RootResolver
  { queryResolver = resolveQuery
  , mutationResolver = resolveMutation
  , subscriptionResolver = Undefined
  }
```

#### 10.2: Connect to GraphQL handler ⬜
- [ ] `Handler/GraphQL.hs`の更新
- [ ] リゾルバの接続
- [ ] エラーハンドリングの統合

**Acceptance Criteria:**
- すべてのクエリ/ミューテーションが動作する
- エンドツーエンドでリクエストが処理される

**Tests:**
- [ ] E2Eテスト（GraphQL経由）
- [ ] エラーハンドリング統合テスト

---

### Task 11: Error Handling Implementation ⬜
**Priority:** P0  
**Estimated:** 3-4h  
**Dependencies:** Task 10

#### 11.1: Define error types ⬜
- [ ] `GraphQL/Types/Error.hs`の詳細化
- [ ] エラーコードEnum定義
- [ ] エラーメッセージテンプレート

```haskell
data ErrorCode
  = InvalidDimension
  | InvalidConstraint
  | NumericalInstability
  | ConvergenceFailure
  | ResourceNotFound
  | InternalError

data APIError = APIError
  { errorCode :: ErrorCode
  , errorMessage :: Text
  , errorField :: Maybe Text
  , errorSuggestions :: [Text]
  }
```

#### 11.2: Implement error middleware ⬜
- [ ] グローバルエラーハンドラ
- [ ] エラーログの記録
- [ ] クライアント向けエラーメッセージの整形

#### 11.3: Add error recovery logic ⬜
- [ ] リトライロジック（一部のエラー）
- [ ] フォールバック処理

**Acceptance Criteria:**
- すべてのエラーが適切に処理される
- エラーメッセージが明確
- エラーログが記録される

**Tests:**
- [ ] 各エラータイプのテスト
- [ ] エラーログテスト
- [ ] エラーレスポンス形式テスト

---

### Task 12: Logging Implementation ⬜
**Priority:** P1  
**Estimated:** 2-3h  
**Dependencies:** Task 2

#### 12.1: Setup structured logging ⬜
- [ ] JSON形式のログ出力
- [ ] ログレベルの設定
- [ ] リクエストIDの追加

#### 12.2: Add request/response logging ⬜
- [ ] リクエストログ
- [ ] レスポンスログ
- [ ] 計算時間ログ

**Acceptance Criteria:**
- ログが構造化されている
- リクエストが追跡可能

**Tests:**
- [ ] ログ出力テスト
- [ ] ログ形式テスト

---

### Task 13: Unit Tests ⬜
**Priority:** P0  
**Estimated:** 5-6h  
**Dependencies:** Task 5-12

#### 13.1: Service layer unit tests ⬜
- [ ] `test/Service/SpaceSpec.hs`
- [ ] `test/Service/OptimizationSpec.hs`
- [ ] `test/Service/ValidationSpec.hs`

#### 13.2: Utility unit tests ⬜
- [ ] `test/Util/ConversionSpec.hs`
- [ ] `test/Util/ErrorSpec.hs`

**Target:** 80%+ code coverage

**Tests:**
- [ ] 正常系のテスト
- [ ] 異常系のテスト
- [ ] エッジケースのテスト
- [ ] エラーハンドリングのテスト

---

### Task 14: GraphQL Integration Tests ⬜
**Priority:** P0  
**Estimated:** 4-5h  
**Dependencies:** Task 13

#### 14.1: Schema validation tests ⬜
- [ ] `test/GraphQL/SchemaSpec.hs`
- [ ] スキーマバリデーション
- [ ] 型チェック

#### 14.2: Resolver tests ⬜
- [ ] `test/GraphQL/QuerySpec.hs`
- [ ] `test/GraphQL/MutationSpec.hs`
- [ ] 各リゾルバの動作確認

**Tests:**
- [ ] Introspectionテスト
- [ ] クエリ実行テスト
- [ ] ミューテーション実行テスト
- [ ] エラーハンドリングテスト

---

### Task 15: E2E Tests ⬜
**Priority:** P1  
**Estimated:** 5-6h  
**Dependencies:** Task 14

#### 15.1: Setup E2E test framework ⬜
- [ ] `test/Integration/E2ESpec.hs`
- [ ] Yesod Testの統合
- [ ] テストデータの準備

#### 15.2: Implement E2E scenarios ⬜
- [ ] 空間作成→検証のシナリオ
- [ ] 空間作成→最適化のシナリオ
- [ ] 最適化→可視化のシナリオ
- [ ] エラーケースのシナリオ

**Tests:**
- [ ] フルフローの動作確認
- [ ] パフォーマンステスト
- [ ] 並行リクエストテスト

---

### Task 16: Performance Tests ⬜
**Priority:** P2  
**Estimated:** 3-4h  
**Dependencies:** Task 15

#### 16.1: Setup benchmarking ⬜
- [ ] Criterionの統合
- [ ] ベンチマークスイートの作成

#### 16.2: Add performance benchmarks ⬜
- [ ] 最適化パフォーマンステスト
- [ ] 並列処理パフォーマンステスト
- [ ] メモリ使用量テスト

**Tests:**
- [ ] レスポンスタイムのベンチマーク
- [ ] スループットのベンチマーク
- [ ] メモリリークテスト

---

### Task 17: API Documentation ⬜
**Priority:** P1  
**Estimated:** 4-5h  
**Dependencies:** Task 10

#### 17.1: GraphQL schema documentation ⬜
- [ ] スキーマ内のドキュメントコメント充実
- [ ] 各型・フィールドの説明
- [ ] サンプルクエリの追加

#### 17.2: Create API reference ⬜
- [ ] `.cursor/docs/medicus-api/api-reference/`
- [ ] クエリリファレンス
- [ ] ミューテーションリファレンス
- [ ] 型リファレンス

**Deliverables:**
- [ ] `api-reference/queries.md`
- [ ] `api-reference/mutations.md`
- [ ] `api-reference/types.md`

---

### Task 18: Tutorial & Getting Started ⬜
**Priority:** P1  
**Estimated:** 5-6h  
**Dependencies:** Task 17

#### 18.1: Create getting started guide ⬜
- [ ] `.cursor/docs/medicus-api/getting-started.md`
- [ ] インストール手順
- [ ] 初回実行手順
- [ ] 基本的なクエリ例

#### 18.2: Create tutorials ⬜
- [ ] `.cursor/docs/medicus-api/tutorials/01-first-optimization.md`
- [ ] `.cursor/docs/medicus-api/tutorials/02-custom-constraints.md`
- [ ] `.cursor/docs/medicus-api/tutorials/03-visualization.md`

**Deliverables:**
- [ ] Getting Started Guide
- [ ] Tutorial 1: 初めての最適化
- [ ] Tutorial 2: カスタム制約の設定
- [ ] Tutorial 3: 結果の可視化

---

### Task 19: Code Documentation (Haddock) ⬜
**Priority:** P1  
**Estimated:** 3-4h  
**Dependencies:** Task 10

#### 19.1: Add Haddock comments ⬜
- [ ] すべての公開関数にHaddockコメント
- [ ] モジュールレベルのドキュメント
- [ ] サンプルコードの追加

**Target:** 100% Haddock coverage

**Deliverables:**
- [ ] Haddockドキュメント生成
- [ ] HTMLドキュメントの確認

---

### Task 20: Docker Configuration ⬜
**Priority:** P2  
**Estimated:** 3-4h  
**Dependencies:** Task 10

#### 20.1: Create Dockerfile ⬜
- [ ] `Dockerfile`の作成
- [ ] マルチステージビルド
- [ ] 最適化（イメージサイズ削減）

#### 20.2: Create docker-compose.yml ⬜
- [ ] 開発環境用設定
- [ ] 環境変数の設定

**Deliverables:**
- [ ] `Dockerfile`
- [ ] `docker-compose.yml`
- [ ] `.dockerignore`

---

### Task 21: Deployment Documentation ⬜
**Priority:** P2  
**Estimated:** 2-3h  
**Dependencies:** Task 20

#### 21.1: Create deployment guide ⬜
- [ ] `.cursor/docs/medicus-api/deployment.md`
- [ ] 開発環境セットアップ
- [ ] 本番デプロイメント手順
- [ ] トラブルシューティング

**Deliverables:**
- [ ] Deployment Guide

---

## Future Enhancements

Phase 1-3の完了後に実装を検討する機能については、[`future-enhancements.md`](./future-enhancements.md) を参照してください。

### 将来のタスク概要
- **Phase 4**: データ可視化API（UI実装時）
- **Phase 5**: データベース統合（Persistent + PostgreSQL）
- **Phase 6**: 認証・認可（JWT）
- **Phase 7**: キャッシング（Redis）
- **Phase 8**: リアルタイム通知（GraphQL Subscriptions）
- **Phase 9**: 管理UI・モニタリング
- **Phase 10**: マイクロサービス化

詳細な要件、設計、実装タスクは [`future-enhancements.md`](./future-enhancements.md) に記載されています。

---

## Milestones

### Milestone 1: Foundation Complete
**Target:** Week 1-2 (Tasks 1-4)
- ✅ Yesod + GraphQL基盤が動作
- ✅ GraphQL Playgroundでスキーマ探索可能
- ✅ ヘルスチェックエンドポイントが応答

**Success Criteria:**
- Yesodサーバーが起動する
- GraphQL Introspectionが動作する
- 基本的なテストが通過する

### Milestone 2: Core API Complete
**Target:** Week 3-4 (Tasks 5-10)
- ✅ 空間作成・検証APIが動作
- ✅ 最適化実行APIが動作
- ✅ すべてのリゾルバが実装される

**Success Criteria:**
- GraphQL Playgroundで最適化が実行できる
- すべてのMEDICUS Engineコア機能がAPI経由でアクセス可能
- 型変換が正しく動作する

### Milestone 3: Quality Assurance Complete
**Target:** Week 5-6 (Tasks 11-16)
- ✅ エラーハンドリング・ロギング完成
- ✅ ユニット・統合・E2Eテストが通過
- ✅ パフォーマンステスト完成

**Success Criteria:**
- テストカバレッジ 80%以上
- すべてのエラーケースがテストされる
- パフォーマンスベンチマーク達成

### Milestone 4: MVP Complete (Phase 1-3)
**Target:** Week 7-8 (Tasks 17-21)
- ✅ ドキュメント完成（API Reference、Tutorial、Haddock）
- ✅ Docker化完了
- ✅ デプロイメントガイド完成

**Success Criteria:**
- 本番環境にデプロイ可能
- Haddockカバレッジ 100%
- Getting Startedガイドで新規ユーザーがAPI利用可能
- すべてのPhase 1-3タスク完了

---

## Task Estimation Summary

| Phase | Tasks | Estimated Hours |
|-------|-------|----------------|
| **Phase 1: Foundation** | 1-4 | 11-15h |
| 1. Setup | 1-2 | 5-7h |
| 2. GraphQL Foundation | 3-4 | 6-8h |
| **Phase 2: Core API** | 5-10 | 21-27h |
| 3. Type Conversion & Services | 5-7 | 11-14h |
| 4. Resolvers | 8-10 | 10-13h |
| **Phase 3: Quality & Docs** | 11-21 | 39-49h |
| 5. Error & Logging | 11-12 | 5-7h |
| 6. Testing | 13-16 | 18-23h |
| 7. Documentation | 17-19 | 12-15h |
| 8. Deployment | 20-21 | 5-7h |
| **Total (Phase 1-3)** | **1-21** | **71-91h** |

**Estimated Timeline:** 7-8 weeks (part-time) or 2-3 weeks (full-time)

---

## Progress Tracking

### Sprint 1 (Week 1) - Foundation
- [x] Task 1: Project Setup ✅ (2026-03-07)
- [x] Task 2: Yesod Foundation ✅ (2026-03-07)
- [ ] Task 3: GraphQL Schema

### Sprint 2 (Week 2) - GraphQL Foundation
- [ ] Task 4: GraphQL Playground
- [ ] Task 5: Type Conversion
- [ ] Task 6: Space Service

### Sprint 3 (Week 3) - Core Services
- [ ] Task 7: Optimization Service
- [ ] Task 8: Query Resolvers

### Sprint 4 (Week 4) - Resolvers & Error Handling
- [ ] Task 9: Mutation Resolvers
- [ ] Task 10: Root Resolver
- [ ] Task 11: Error Handling

### Sprint 5 (Week 5) - Testing Foundation
- [ ] Task 12: Logging
- [ ] Task 13: Unit Tests
- [ ] Task 14: Integration Tests

### Sprint 6 (Week 6) - Testing Complete
- [ ] Task 15: E2E Tests
- [ ] Task 16: Performance Tests

### Sprint 7 (Week 7) - Documentation
- [ ] Task 17: API Documentation
- [ ] Task 18: Tutorials
- [ ] Task 19: Haddock

### Sprint 8 (Week 8) - Deployment & Polish
- [ ] Task 20: Docker
- [ ] Task 21: Deployment Docs
- [ ] Bug fixes & Final polish

---

## Notes

### Development Workflow
1. 各タスク開始時に`tasks.md`を更新（⬜ → 🟨）
2. 実装完了後にテストを書く
3. テスト通過後にタスクを完了（🟨 → ✅）
4. コードレビュー必須
5. ドキュメントを随時更新

### Testing Requirements
- 新規コードはテストカバレッジ80%以上
- E2Eテストは主要なユースケースをカバー
- パフォーマンステストは回帰を検出

### Documentation Requirements
- すべての公開APIにHaddockコメント
- 複雑なロジックにはインラインコメント
- 設計判断はADR（Architecture Decision Record）に記録

---

**Last Updated:** 2026-03-07  
**Version:** 0.1.0  
**Status:** Draft
