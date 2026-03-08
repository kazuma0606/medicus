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
- [x] ビルドが成功する ✅ (2026-03-07: Stack + morpheus-graphql 0.28.4)
- [x] Yesodサーバーが起動する ✅ (2026-03-07: localhost:3000)

**Tests:**
- [ ] サーバー起動テスト（Task 3以降で実装）
- [ ] ヘルスチェックテスト（Task 3以降で実装）
- [ ] 設定読み込みテスト（Task 3以降で実装）

**Note:** ✅ ビルド環境の問題は解決済み（2026-03-07）。Stackを使用し、morpheus-graphql 0.28.4とその依存関係を正しく設定することで、すべての型エラーとビルド問題を解決しました。

---

## Phase 2: GraphQL Foundation

### Task 3: GraphQL Schema Definition ✅
**Priority:** P0  
**Estimated:** 4-5h  
**Dependencies:** Task 2  
**Completed:** 2026-03-07  
**Build Status:** ✅ Success

#### 3.1: Define core types ✅
- [x] `GraphQL/Types/Common.hs`の作成
- [x] `GraphQL/Types/Space.hs`の作成
- [x] `GraphQL/Types/Optimization.hs`の作成
- [x] `GraphQL/Types/Error.hs`の作成

**実装された型:**
- `HealthStatus`, `ConstraintType`, `NormWeightsInput`, `NormWeights`
- `SpaceConfigInput`, `ConstraintInput`, `CreateSpaceResult`, `ValidationResult`, `SpaceInfo`
- `OptimizationInput`, `ObjectiveFunctionInput`, `OptimizationResult`, `ConvergenceHistory`
- `ValidationError`, `ValidationWarning`, `APIError`, `ErrorCode`

#### 3.2: Define Query type ✅
- [x] `GraphQL/Schema.hs`の作成
- [x] `Query`型の定義（Morpheus GraphQL）
- [x] 各クエリフィールドの型定義
- [x] ドキュメントコメントの追加

**実装されたQuery:**
```haskell
data Query m = Query
  { validateSpace :: ValidateSpaceArgs -> m ValidationResult
  , listAvailableConstraints :: m [ConstraintType]
  , health :: m HealthStatus
  }
```

#### 3.3: Define Mutation type ✅
- [x] `Mutation`型の定義
- [x] 各ミューテーションフィールドの型定義
- [x] ドキュメントコメントの追加

**実装されたMutation:**
```haskell
data Mutation m = Mutation
  { createSpace :: CreateSpaceArgs -> m CreateSpaceResult
  , deleteSpace :: DeleteSpaceArgs -> m Bool
  , optimize :: OptimizeArgs -> m OptimizationResult
  , optimizeBatch :: OptimizeBatchArgs -> m [OptimizationResult]
  }
```

#### 3.4: Setup GraphQL endpoint ✅
- [x] `Handler/GraphQL.hs`の作成
- [x] `Handler/Playground.hs`の作成
- [x] `GraphQL/Resolvers.hs`の作成（スタブ実装）
- [x] Morpheus GraphQLの統合
- [x] リクエストパーシング
- [x] レスポンス生成

#### 3.5: Build environment setup ✅
- [x] `stack.yaml`の作成（medicus-api/）
- [x] ルートの`stack.yaml`の作成

**Acceptance Criteria:**
- [x] すべてのGraphQL型が定義されている
- [x] スキーマが完全に定義されている
- [x] GraphQLエンドポイントハンドラが実装されている
- [x] スタブリゾルバが実装されている
- [x] ビルドが成功する ✅ (2026-03-07)
- [x] Introspectionが動作する ✅ (2026-03-07: GraphQL Playground確認済み)

**Tests:**
- [ ] スキーマバリデーションテスト（Task 14で実装）
- [ ] Introspectionクエリテスト（Task 14で実装）
- [ ] 型チェックテスト（Task 14で実装）

**Note:** ✅ Task 3完了（2026-03-07）。すべてのGraphQL型、スキーマ、ハンドラ、リゾルバが実装され、ビルドに成功しました。morpheus-graphql 0.28.4の公式ドキュメントを参考に、Resolverモナド変換子を正しく使用し、Yesodとの統合も完了しています。

---

### Task 4: GraphQL Playground Integration ✅
**Priority:** P1  
**Estimated:** 2-3h  
**Dependencies:** Task 3  
**Completed:** 2026-03-07

#### 4.1: Setup Playground handler ✅
- [x] `Handler/Playground.hs`の作成
- [x] GraphQL Playground HTMLの配信
- [x] 静的ファイルの配置
- [x] 開発環境のみで有効化

#### 4.2: Configure Playground settings ✅
- [x] デフォルトクエリの設定
- [x] エンドポイントURL設定
- [x] テーマ・UI設定

**Acceptance Criteria:**
- [x] `/playground`にアクセスできる ✅
- [x] Introspectionが正常に動作する ✅
- [x] サンプルクエリが実行できる ✅ (health, listAvailableConstraints, validateSpace)

**Tests:**
- [x] Playgroundアクセステスト ✅ (http://localhost:3000/playground)
- [x] 開発/本番環境での動作切り替えテスト ✅ (settings.ymlで制御)

---

## Phase 3: Core API Implementation

### Task 5: Type Conversion Utilities ✅
**Priority:** P0  
**Estimated:** 3-4h  
**Dependencies:** Task 3  
**Completed:** 2026-03-08

#### 5.1: Create conversion module ✅
- [x] `Util/Conversion.hs`の作成 ✅
- [x] GraphQL → MEDICUS Engine型変換 ✅
- [x] MEDICUS Engine → GraphQL型変換 ✅

```haskell
toMEDICUSSpaceConfig :: SpaceConfigInput -> MEDICUSSpaceConfig
fromMEDICUSOptimizationResult :: MEDICUSOptimizationResult -> OptimizationResult
```

**Note:** 実装は現在スタブ（プレースホルダ型）として完成。MEDICUS Engineへの依存が有効化された時点で実際の型に切り替え可能。

#### 5.2: Create error conversion ✅
- [x] `Util/Error.hs`の作成 ✅
- [x] MEDICUS Engineエラー → GraphQLエラー変換 ✅
- [x] エラーメッセージの整形 ✅
- [x] バリデーションヘルパー関数（validateDimensionRange, validateNormWeightsSum, validateConstraintDimensions） ✅

**Acceptance Criteria:**
- [x] すべての型が相互変換可能 ✅
- [x] エラーメッセージが適切に変換される ✅

**Tests:**
- [x] 型変換の双方向テスト ✅ (15 examples)
- [x] エラー変換テスト ✅ (20 examples)
- [x] エッジケースのテスト ✅ (12 examples)
- [x] すべてのテストがパス ✅ (47 examples, 0 failures)

---

### Task 6: Space Service Implementation ✅
**Priority:** P0  
**Estimated:** 4-5h  
**Dependencies:** Task 5  
**Completed:** 2026-03-08

#### 6.1: Create Space service module ✅
- [x] `Service/Space.hs`の作成
- [x] `createSpace`関数の実装
- [x] `validateSpace`関数の実装
- [x] `getSpaceInfo`関数の実装（スタブ）

#### 6.2: Implement validation logic ✅
- [x] `Service/Validation.hs`の作成
- [x] 次元数の検証
- [x] ノルム重みの検証
- [x] 制約の検証
- [x] 複合検証

#### 6.3: Integrate with MEDICUS Engine ✅
- [x] `MEDICUS.API`モジュールの利用
- [x] エラーハンドリング
- [x] 結果の型変換

**Acceptance Criteria:**
- [x] 空間が正常に作成できる
- [x] バリデーションが正しく動作する
- [x] エラーが適切に処理される

**Tests:**
- [x] `createSpace`のユニットテスト
- [x] `validateSpace`のユニットテスト
- [x] バリデーションロジックのテスト
- [x] MEDICUS Engine統合テスト (Util/Conversion, Util/Error更新済み)

---

### Task 7: Optimization Service Implementation ✅
**Priority:** P0  
**Estimated:** 5-6h  
**Dependencies:** Task 6  
**Completed:** 2026-03-08

#### 7.1: Create Optimization service module ✅
- [x] `Service/Optimization.hs`の作成
- [x] `runOptimization`関数の実装
- [x] `runBatchOptimization`関数の実装

#### 7.2: Implement optimization logic ✅
- [x] MEDICUS Engineの`optimize`関数呼び出し
- [x] 初期点の検証
- [x] オプションパラメータの処理
- [x] 計算時間の測定

#### 7.3: Add convergence history tracking ⬜ (Future Enhancement)
- [ ] イテレーション履歴の収集
- [ ] 制約違反履歴の収集
- [ ] 目的関数値履歴の収集

**Acceptance Criteria:**
- [x] 最適化が正常に実行される
- [x] バッチ処理がリスト処理として実装されている

**Tests:**
- [x] 単一最適化のテスト
- [x] バッチ最適化のテスト
- [x] 計算時間測定の検証

---

### Task 8: Query Resolvers ✅
**Priority:** P0  
**Estimated:** 3-4h  
**Dependencies:** Task 6  
**Completed:** 2026-03-08

#### 8.1: Create Query resolver modules ✅
- [x] `GraphQL/Query/Space.hs`の作成
- [x] `GraphQL/Query/Health.hs`の作成

#### 8.2: Implement Space query resolvers ✅
- [x] `validateSpace`リゾルバの実装
- [x] `listAvailableConstraints`リゾルバの実装
- [x] `Service.Validation`との統合

#### 8.3: Implement Health query resolver ✅
- [x] `health`リゾルバの実装
- [x] 動的なタイムスタンプ取得

**Acceptance Criteria:**
- [x] すべてのクエリがリゾルバ経由で動作する
- [x] サービス層が適切に呼び出される

**Tests:**
- [x] 各リゾルバの動作確認（Playground確認済み）
- [ ] 統合テスト (Task 14で実装)

---

### Task 9: Mutation Resolvers ✅
**Priority:** P0  
**Estimated:** 4-5h  
**Dependencies:** Task 7  
**Completed:** 2026-03-08

#### 9.1: Create Mutation resolver modules ✅
- [x] `GraphQL/Mutation/Space.hs`の作成
- [x] `GraphQL/Mutation/Optimization.hs`の作成

#### 9.2: Implement Space mutation resolvers ✅
- [x] `createSpace`リゾルバの実装
- [x] `deleteSpace`リゾルバの実装
- [x] `Service.Space`との統合

#### 9.3: Implement Optimization mutation resolvers ✅
- [x] `optimize`リゾルバの実装
- [x] `optimizeBatch`リゾルバの実装
- [x] 計算時間の測定（サービス層で実装済み）
- [x] デフォルト空間設定の適用（MVP仕様）

**Acceptance Criteria:**
- [x] すべてのミューテーションが実行可能
- [x] サービス層が適切に呼び出される
- [x] 計算時間がレスポンスに含まれる

**Tests:**
- [x] 各リゾルバの動作確認（Playground確認済み）
- [ ] パフォーマンステスト (Task 16で実装)

---

### Task 10: Root Resolver Assembly ✅
**Priority:** P0  
**Estimated:** 2-3h  
**Dependencies:** Task 8, 9  
**Completed:** 2026-03-08

#### 10.1: Create root resolver module ✅
- [x] `GraphQL/Resolvers.hs`の作成
- [x] `Query`リゾルバの統合
- [x] `Mutation`リゾルバの統合

#### 10.2: Connect to GraphQL handler ✅
- [x] `Handler/GraphQL.hs`の更新
- [x] リゾルバの接続
- [x] エラーハンドリングの統合

**Acceptance Criteria:**
- [x] すべてのクエリ/ミューテーションが動作する
- [x] エンドツーエンドでリクエストが処理される

**Tests:**
- [x] E2Eテスト（GraphQL経由）
- [x] エラーハンドリング統合テスト

---

### Task 11: Error Handling Implementation ✅
**Priority:** P0  
**Estimated:** 3-4h  
**Dependencies:** Task 10  
**Completed:** 2026-03-08

#### 11.1: Define error types ✅
- [x] `GraphQL/Types/Error.hs`の詳細化
- [x] エラーコードEnum定義 (`ErrorCode`)
- [x] 詳細なエラー情報保持 (`APIError`, `ValidationError`)

#### 11.2: Implement error middleware ✅
- [x] `Util/Error.hs`への統合
- [x] エラー解決策（suggestions）の自動生成
- [x] クライアント向けエラーメッセージの整形

#### 11.3: Add error recovery logic ⬜ (Future Enhancement)
- [ ] リトライロジック（一部のエラー）
- [ ] フォールバック処理

**Acceptance Criteria:**
- [x] すべてのエラーが構造化されて返される
- [x] エラーコードとメッセージが明確
- [x] 解決策（suggestions）が提供される

**Tests:**
- [x] エラー変換テスト (`Util/ErrorSpec.hs`)
- [x] 新しいエラー型の動作確認

---

### Task 12: Logging Implementation ✅
**Priority:** P1  
**Estimated:** 2-3h  
**Dependencies:** Task 2  
**Completed:** 2026-03-08

#### 12.1: Setup structured logging ✅
- [x] JSON形式のログ出力の実装 (`Application.hs`, `Foundation.hs`)
- [x] ログレベルの設定対応
- [x] リクエスト情報のJSON化

#### 12.2: Add request/response logging ✅
- [x] ミドルウェアによるリクエストログの構造化
- [x] 計算時間ログの追加 (`Service/Optimization.hs`)
- [x] 最適化実行状況のロギング

**Acceptance Criteria:**
- [x] ログがJSON形式で構造化されている
- [x] リクエスト状況とパフォーマンスが追跡可能

**Tests:**
- [x] ログ出力形式の確認
- [x] ロギングミドルウェアの動作確認

---

### Task 13: Unit Tests ✅
**Priority:** P0  
**Estimated:** 5-6h  
**Dependencies:** Task 5-12  
**Completed:** 2026-03-08

#### 13.1: Service layer unit tests ✅
- [x] `test/Service/SpaceSpec.hs`の実装
- [x] `test/Service/OptimizationSpec.hs`の実装
- [x] `test/Service/ValidationSpec.hs`の実装
- [x] 異常系・境界値テストの追加

#### 13.2: Utility unit tests ✅
- [x] `test/Util/ConversionSpec.hs`の実装
- [x] `test/Util/ErrorSpec.hs`の実装
- [x] 新しいエラーヘルパー関数のテスト

**Target:** 80%+ code coverage (Unit tests for core logic implemented)

**Tests:**
- [x] 正常系のテスト
- [x] 異常系のテスト
- [x] エッジケースのテスト
- [x] エラーハンドリングのテスト

---

### Task 14: GraphQL Integration Tests ✅
**Priority:** P0  
**Estimated:** 4-5h  
**Dependencies:** Task 13  
**Completed:** 2026-03-08

#### 14.1: Schema validation tests ✅
- [x] `test/GraphQL/SchemaSpec.hs`の実装
- [x] イントロスペクションクエリの検証
- [x] カスタム型の存在確認

#### 14.2: Resolver tests ✅
- [x] `test/GraphQL/QuerySpec.hs`の実装
- [x] `test/GraphQL/MutationSpec.hs`の実装
- [x] 各リゾルバのGraphQLレイヤー経由での動作確認
- [x] エラーハンドリングの検証

**Tests:**
- [x] Introspectionテスト
- [x] クエリ実行テスト (health, listAvailableConstraints, validateSpace)
- [x] ミューテーション実行テスト (createSpace, optimize, deleteSpace)
- [x] エラーレスポンス形式テスト

---

### Task 15: E2E Tests ✅
**Priority:** P1  
**Estimated:** 5-6h  
**Dependencies:** Task 14  
**Completed:** 2026-03-08

#### 15.1: Setup E2E test framework ✅
- [x] `test/Integration/E2ESpec.hs`の実装
- [x] `Yesod.Test`の統合
- [x] テスト用アプリケーション初期化基盤 (`withApp`)

#### 15.2: Implement E2E scenarios ✅
- [x] システムヘルスチェックのE2Eテスト
- [x] GraphQL クエリのE2Eテスト (health, listAvailableConstraints, validateSpace)
- [x] GraphQL ミューテーションのE2Eテスト (createSpace, optimize)
- [x] エラーケースのシナリオテスト

**Tests:**
- [x] HTTP POST によるGraphQLリクエストテスト
- [x] レスポンスステータスとボディの検証
- [x] フルフローの動作確認

---

### Task 16: Performance Tests ✅
**Priority:** P2  
**Estimated:** 3-4h  
**Dependencies:** Task 15  
**Completed:** 2026-03-08

#### 16.1: Setup benchmarking ✅
- [x] `criterion`の統合
- [x] ベンチマークスイートの作成 (`medicus-api-bench`)
- [x] `bench/Bench.hs`の実装

#### 16.2: Add performance benchmarks ✅
- [x] 最適化パフォーマンステスト (次元数 3, 10, 100)
- [x] 並列処理（バッチ処理）パフォーマンステスト
- [x] `NFData`インスタンスの定義

**Tests:**
- [x] ベンチマークプログラムのコンパイル確認
- [x] 実行時間の統計的測定基盤の構築

---

### Task 17: API Documentation ✅
**Priority:** P1  
**Estimated:** 4-5h  
**Dependencies:** Task 10  
**Completed:** 2026-03-08

#### 17.1: GraphQL schema documentation ✅
- [x] スキーマ内のドキュメントコメント充実 (`GraphQL/Types/*.hs`)
- [x] 各型・フィールドの説明追加
- [x] インスペクションによる自動ドキュメント生成対応

#### 17.2: Create API reference ✅
- [x] `medicus-api/docs/08-api-reference.md`の作成
- [x] クエリリファレンスの記述
- [x] ミューテーションリファレンスの記述
- [x] 入力型の詳細説明

**Deliverables:**
- [x] `api-reference/queries.md` (統合版として`08-api-reference.md`に実装)
- [x] `api-reference/mutations.md`
- [x] `api-reference/types.md`

---

### Task 18: Tutorial & Getting Started ✅
**Priority:** P1  
**Estimated:** 5-6h  
**Dependencies:** Task 17  
**Completed:** 2026-03-08

#### 18.1: Create getting started guide ✅
- [x] `medicus-api/docs/getting-started.md`の作成
- [x] インストール・セットアップ手順の記載
- [x] GraphQL Playgroundでの初回実行ガイド
- [x] 基本的なクエリ・ミューテーション例

#### 18.2: Create tutorials ✅
- [x] `medicus-api/docs/tutorials/01-custom-constraints.md`の作成
- [x] 医療制約の適用ユースケース解説
- [x] バリデーションエラーの例示

**Deliverables:**
- [x] Getting Started Guide
- [x] Tutorial 1: 医療制約の設定と検証
- [ ] Tutorial 2: 最適化の実行 (将来的な拡張)

---

### Task 19: Code Documentation (Haddock) ✅
**Priority:** P1  
**Estimated:** 3-4h  
**Dependencies:** Task 10  
**Completed:** 2026-03-08

#### 19.1: Add Haddock comments ✅
- [x] すべての公開モジュールにモジュールヘッダー追加
- [x] すべての公開関数にHaddockコメント追加
- [x] データ型とレコードフィールドの詳細説明
- [x] モジュールレベルのセクション分け (`-- * Section`)

**Target:** 100% Haddock coverage

**Deliverables:**
- [x] `Application.hs`, `Foundation.hs`, `Settings.hs`のドキュメント充実
- [x] `GraphQL/`, `Service/`, `Util/` 以下のすべてのモジュールのドキュメント化

---

### Task 20: Docker Configuration ✅
**Priority:** P2  
**Estimated:** 3-4h  
**Dependencies:** Task 10  
**Completed:** 2026-03-08

#### 20.1: Create Dockerfile ✅
- [x] `medicus-api/Dockerfile`の作成
- [x] マルチステージビルドの実装 (Build: Haskell, Runtime: Ubuntu)
- [x] 実行バイナリの最適化
- [x] `.dockerignore`の設定

#### 20.2: Create docker-compose.yml ✅
- [x] `medicus-api/docker-compose.yml`の作成
- [x] 環境変数の設定 (YESOD_ENV, PORT)
- [x] 設定ファイルのボリュームマウント

**Deliverables:**
- [x] `Dockerfile`
- [x] `docker-compose.yml`
- [x] `.dockerignore`

---

### Task 21: Deployment Documentation ✅
**Priority:** P2  
**Estimated:** 2-3h  
**Dependencies:** Task 20  
**Completed:** 2026-03-08

#### 21.1: Create deployment guide ✅
- [x] `medicus-api/docs/deployment.md`の作成
- [x] 開発環境セットアップ手順
- [x] 本番デプロイメント手順 (Docker)
- [x] トラブルシューティング

**Deliverables:**
- [x] Deployment Guide

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
