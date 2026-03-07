# Requirements Document - MEDICUS API

## Introduction

MEDICUS APIは、MEDICUS Engine（医療データセキュリティ最適化計算エンジン）をWeb APIとして提供するプロジェクトです。YesodフレームワークとGraphQLを使用し、型安全かつ自己文書化されたAPIを通じて、MEDICUS Engineの高度な数学的最適化機能にアクセスできるようにします。

## Glossary

- **MEDICUS Engine**: 医療データセキュリティのための数学的最適化計算ライブラリ
- **Yesod**: Haskellの型安全なWebフレームワーク
- **GraphQL**: 型付きクエリ言語とランタイム
- **Morpheus GraphQL**: HaskellのGraphQLライブラリ（型安全なスキーマ生成）
- **Introspection**: GraphQLスキーマの自動文書化機能
- **Resolver**: GraphQLクエリ/ミューテーションの実装ハンドラ
- **Persistent**: Yesodのデータベース抽象化層（将来用）

## Project Goals

### Primary Goals
1. MEDICUS Engineの全機能をWeb API経由でアクセス可能にする
2. GraphQLによる柔軟で型安全なクエリインターフェース提供
3. 自己文書化とIntrospectionによる開発者体験の向上
4. Yesodによる堅牢なWebアプリケーション基盤

### Secondary Goals
1. 将来のデータベース統合への準備
2. 認証・認可システムの基盤構築
3. スケーラブルなアーキテクチャ設計
4. 包括的なテストカバレッジ（ユニット、統合、E2E）

## Requirements

### Requirement 1: GraphQL API基盤

**User Story:** As an API利用者, I want GraphQLでMEDICUS Engineにアクセスできる, so that 必要なデータだけを柔軟に取得できる

#### Acceptance Criteria

1. WHEN GraphQL Introspectionクエリを実行する時 THEN システムは完全なAPIスキーマを返す
2. WHEN 無効なクエリを送信する時 THEN システムは型エラーを返す前にコンパイル時に検出する（Morpheus GraphQL）
3. WHEN 複数の関連データを取得する時 THEN システムは1回のクエリで必要なフィールドのみを返す
4. WHEN GraphQL Playgroundにアクセスする時 THEN システムは対話的なAPI探索UIを提供する
5. WHEN スキーマドキュメントを生成する時 THEN システムは型定義から自動的にドキュメントを生成する

**技術詳細:**
- Morpheus GraphQLによる型安全なスキーマ定義
- 自動的なドキュメント生成（Introspection）
- GraphQL Playground統合

**テスト要件:**
- [ ] Introspectionクエリのテスト
- [ ] 型エラーの検出テスト
- [ ] スキーマバリデーションテスト

---

### Requirement 2: MEDICUS空間操作API

**User Story:** As a 医療システム開発者, I want GraphQL経由でMEDICUS空間を作成・検証できる, so that Webアプリケーションから最適化機能を利用できる

#### Acceptance Criteria

1. WHEN `createSpace`ミューテーションを実行する時 THEN システムは設定に基づいてMEDICUS空間を作成し、空間IDを返す
2. WHEN `validateSpace`クエリを実行する時 THEN システムは空間設定の妥当性を検証し、エラーがあれば詳細を返す
3. WHEN `getSpaceInfo`クエリを実行する時 THEN システムは空間の次元数、制約数、ノルム設定等の情報を返す
4. WHEN 無効な空間設定を送信する時 THEN システムは検証エラーとして具体的な問題点を返す
5. WHEN 空間設定をJSON形式で取得する時 THEN システムは`exportSpace`でシリアライズ可能な形式を返す

**GraphQLスキーマ例:**
```graphql
type Query {
  validateSpace(config: SpaceConfigInput!): ValidationResult!
  getSpaceInfo(spaceId: ID!): SpaceInfo
  listAvailableConstraints: [ConstraintType!]!
}

type Mutation {
  createSpace(config: SpaceConfigInput!): CreateSpaceResult!
  deleteSpace(spaceId: ID!): Boolean!
}

input SpaceConfigInput {
  dimension: Int!
  normWeights: NormWeightsInput!
  constraints: [ConstraintInput!]!
}

type SpaceInfo {
  id: ID!
  dimension: Int!
  constraintCount: Int!
  normWeights: NormWeights!
  createdAt: DateTime!
}
```

**テスト要件:**
- [ ] `createSpace`の正常系・異常系テスト
- [ ] `validateSpace`のバリデーションロジックテスト
- [ ] `getSpaceInfo`のデータ取得テスト
- [ ] エラーハンドリングテスト

---

### Requirement 3: 最適化実行API

**User Story:** As a 数値計算研究者, I want GraphQL経由で最適化を実行し、詳細な結果を取得できる, so that Webベースの研究ツールを構築できる

#### Acceptance Criteria

1. WHEN `optimize`ミューテーションを実行する時 THEN システムはMEDICUS Engineで最適化を実行し、結果を返す
2. WHEN 最適化が収束する時 THEN システムは解、目的関数値、イテレーション数、収束フラグを返す
3. WHEN 最適化が失敗する時 THEN システムは失敗理由と診断情報を返す
4. WHEN 収束履歴を要求する時 THEN システムは各イテレーションでの目的関数値と制約違反を返す
5. WHEN 制約違反が発生する時 THEN システムは違反した制約のリストと違反量を返す

**GraphQLスキーマ例:**
```graphql
type Mutation {
  optimize(input: OptimizationInput!): OptimizationResult!
}

input OptimizationInput {
  spaceId: ID!
  objective: ObjectiveFunctionInput!
  initialPoint: [Float!]!
  options: OptimizationOptions
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
```

**テスト要件:**
- [ ] 最適化の正常系テスト（収束ケース）
- [ ] 最適化の異常系テスト（非収束ケース）
- [ ] 制約違反の検出テスト
- [ ] 収束履歴の取得テスト
- [ ] パフォーマンステスト（大規模問題）

---

### Requirement 4: エラーハンドリングと型安全性

**User Story:** As an APIクライアント開発者, I want 明確で型安全なエラーメッセージ, so that 問題を素早く特定・修正できる

#### Acceptance Criteria

1. WHEN 入力バリデーションエラーが発生する時 THEN システムはGraphQLの型システムでエラーを返す
2. WHEN 計算エラーが発生する時 THEN システムはエラー種別と詳細メッセージを返す
3. WHEN 数値不安定性が検出される時 THEN システムは警告レベルと推奨対処法を返す
4. WHEN リソースが見つからない時 THEN システムは404相当のエラーを適切なメッセージで返す
5. WHEN 内部エラーが発生する時 THEN システムはログに詳細を記録し、安全なメッセージをクライアントに返す

**GraphQLスキーマ例:**
```graphql
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

enum ErrorCode {
  INVALID_DIMENSION
  INVALID_CONSTRAINT
  INVALID_NORM_WEIGHTS
  NUMERICAL_INSTABILITY
  CONVERGENCE_FAILURE
  RESOURCE_NOT_FOUND
}

type OptimizationResult {
  success: Boolean!
  solution: [Float!]
  error: OptimizationError
}

type OptimizationError {
  code: ErrorCode!
  message: String!
  suggestions: [String!]!
}
```

**テスト要件:**
- [ ] 各エラータイプのテスト
- [ ] エラーメッセージの品質テスト
- [ ] エラーログの記録テスト

---

### Requirement 5: パフォーマンスと並列処理

**User Story:** As a システム管理者, I want 大規模問題でも効率的に処理できる, so that 多数のユーザーの同時リクエストに対応できる

#### Acceptance Criteria

1. WHEN 複数の最適化リクエストが同時に来る時 THEN システムは並列処理で効率的に実行する
2. WHEN バッチ評価を実行する時 THEN システムは`parallelEvaluate`で高速化する
3. WHEN 大規模問題を解く時 THEN システムは適切なメモリ管理を行う
4. WHEN 長時間計算が必要な時 THEN システムはタイムアウトを設定し、クライアントに通知する
5. WHEN パフォーマンスメトリクスを取得する時 THEN システムは計算時間、メモリ使用量を返す

**GraphQLスキーマ例:**
```graphql
type Mutation {
  optimizeBatch(inputs: [OptimizationInput!]!): [OptimizationResult!]!
}

type Query {
  getPerformanceMetrics(resultId: ID!): PerformanceMetrics!
}

type PerformanceMetrics {
  computationTimeMs: Int!
  memoryUsageMb: Float!
  parallelWorkers: Int!
}

input OptimizationOptions {
  maxIterations: Int
  tolerance: Float
  timeoutSeconds: Int
  parallelEvaluation: Boolean
}
```

**テスト要件:**
- [ ] 並列処理のパフォーマンステスト
- [ ] バッチ処理のテスト
- [ ] メモリリークテスト
- [ ] タイムアウトテスト

---

### Requirement 6: Yesod統合と基盤機能

**User Story:** As a Webアプリケーション開発者, I want Yesodの機能を活用したセキュアなAPI基盤, so that 本番環境で安全に運用できる

#### Acceptance Criteria

1. WHEN APIサーバーを起動する時 THEN システムはYesodのルーティングとミドルウェアを初期化する
2. WHEN リクエストログを記録する時 THEN システムはYesodのロギング機能を使用する
3. WHEN セッション管理が必要な時 THEN システムはYesodのセッション機能を活用する（将来用）
4. WHEN 静的ファイルを配信する時 THEN システムはYesodの静的ファイル機能を使用する（GraphQL Playground用）
5. WHEN 環境設定を読み込む時 THEN システムはYesodの設定管理を使用する

**技術詳細:**
- Yesodルーティング
- Yesodミドルウェア（CORS、ロギング、セキュリティヘッダー）
- Yesod設定管理（開発/本番環境の切り替え）
- Persistentの準備（スキーマ定義、マイグレーション設定）

**テスト要件:**
- [ ] ルーティングテスト
- [ ] ミドルウェアテスト
- [ ] 環境設定の読み込みテスト
- [ ] CORS設定テスト

---

### Requirement 7: テストとCI/CD

**User Story:** As a 品質保証エンジニア, I want 包括的なテストスイート, so that APIの品質を保証できる

#### Acceptance Criteria

1. WHEN ユニットテストを実行する時 THEN システムは各GraphQL Resolverの動作を検証する
2. WHEN 統合テストを実行する時 THEN システムはMEDICUS Engineとの統合を検証する
3. WHEN E2Eテストを実行する時 THEN システムは実際のGraphQLクエリを送信してレスポンスを検証する
4. WHEN スキーマテストを実行する時 THEN システムはGraphQLスキーマの一貫性を検証する
5. WHEN カバレッジレポートを生成する時 THEN システムは80%以上のカバレッジを達成する

**テストツール:**
- Hspec: ユニットテスト・統合テスト
- Yesod Test: Yesod固有のテスト
- GraphQL Schema Test: スキーマバリデーション
- HPC: カバレッジ測定

**テスト要件:**
- [ ] ユニットテスト（Resolver単位）
- [ ] 統合テスト（MEDICUS Engineとの連携）
- [ ] E2Eテスト（GraphQLクエリ）
- [ ] スキーマバリデーションテスト
- [ ] パフォーマンステスト
- [ ] リグレッションテスト

---

### Requirement 8: ドキュメントと開発者体験

**User Story:** As an API新規利用者, I want 充実したドキュメント, so that 迅速にAPIの使い方を理解できる

#### Acceptance Criteria

1. WHEN GraphQL Playgroundにアクセスする時 THEN システムは対話的なAPI探索UIを提供する
2. WHEN スキーマドキュメントを参照する時 THEN システムはIntrospectionで自動生成されたドキュメントを提供する
3. WHEN サンプルクエリを参照する時 THEN システムは典型的なユースケースの例を提供する
4. WHEN APIリファレンスを参照する時 THEN システムは各型・フィールド・引数の詳細説明を提供する
5. WHEN チュートリアルを参照する時 THEN システムは段階的な学習ガイドを提供する

**ドキュメント構成:**
```
.cursor/docs/medicus-api/
├── README.md                 # プロジェクト概要
├── getting-started.md        # クイックスタート
├── graphql-schema.md         # スキーマリファレンス
├── tutorials/
│   ├── 01-first-optimization.md
│   ├── 02-custom-constraints.md
│   └── 03-visualization.md
├── api-reference/
│   ├── queries.md
│   ├── mutations.md
│   └── types.md
└── deployment.md             # デプロイメントガイド
```

**テスト要件:**
- [ ] ドキュメントのサンプルコードの動作確認
- [ ] GraphQL Playgroundの動作確認
- [ ] Introspectionの完全性確認

---

---

## Future Enhancements

以下の機能は、Phase 1-3（MVPとコア機能）の完了後に実装を検討します。詳細は [`future-enhancements.md`](./future-enhancements.md) を参照してください。

### 将来的な拡張候補
1. **データ可視化API** - UI実装時に必要（Phase 4）
2. **データベース統合** - PostgreSQL + Persistent（Phase 5）
3. **認証・認可** - JWT、OAuth2（Phase 6）
4. **キャッシング** - Redis統合（Phase 7）
5. **リアルタイム通知** - GraphQL Subscriptions（Phase 8）
6. **管理UI** - Yesod Templates（Phase 9）
7. **マイクロサービス化** - 長期的なスケーリング対応（Phase 10）

### アーキテクチャの拡張性

Phase 1-3の実装では、将来の拡張に対応できるアーキテクチャを採用します：

**設計原則:**
- レイヤードアーキテクチャ（プレゼンテーション、ビジネスロジック、計算エンジン）
- 依存性注入パターン（Reader Monad）
- モジュール境界の明確化
- インターフェース設計（型クラス活用）

**拡張ポイント:**
1. **Database Layer** - 将来のPersistent統合に備えた抽象化
2. **Auth Layer** - 認証ミドルウェアの追加ポイント
3. **Cache Layer** - キャッシング機構の挿入ポイント
4. **Service Layer** - ビジネスロジックの独立性

---

## Non-Functional Requirements

### パフォーマンス
- 単純な最適化リクエスト: < 1秒
- 中規模最適化（100次元）: < 5秒
- 大規模最適化（1000次元）: < 30秒
- GraphQLクエリレスポンス: < 100ms（計算除く）
- 同時接続: 100ユーザー

### セキュリティ
- HTTPS必須（本番環境）
- GraphQLクエリの深さ制限
- レート制限（将来）
- 入力バリデーション（すべてのフィールド）
- SQL/NoSQLインジェクション対策（将来のDB統合時）

### 可用性
- アップタイム: 99.9%目標（将来）
- グレースフルシャットダウン
- ヘルスチェックエンドポイント

### 保守性
- Haddockカバレッジ: 100%
- テストカバレッジ: 80%以上
- モジュール境界の明確化
- コードレビュー必須

### スケーラビリティ
- ステートレス設計（水平スケーリング対応）
- 並列処理対応
- 将来的なマイクロサービス化対応

---

## Success Metrics

### Phase 1: Project Setup & Foundation
- [ ] Yesodサーバーが起動する
- [ ] GraphQL APIが動作する
- [ ] ヘルスチェックエンドポイントが応答する
- [ ] GraphQL Playgroundでスキーマが探索可能
- [ ] 基本的なテストが通過する

### Phase 2: GraphQL Foundation
- [ ] 完全なGraphQLスキーマが定義される
- [ ] Introspectionが正常に動作する
- [ ] GraphQL Playgroundが動作する
- [ ] スキーマバリデーションが通過する

### Phase 3: Core API Implementation
- [ ] 空間作成・検証APIが動作する
- [ ] 最適化実行APIが動作する
- [ ] すべてのMEDICUS Engineコア機能がAPI経由でアクセス可能
- [ ] エラーハンドリングが正しく動作する
- [ ] ユニットテストカバレッジ 80%+
- [ ] 統合テストが通過する
- [ ] E2Eテストが通過する
- [ ] ドキュメントが完成する
- [ ] Docker化が完了する

### MVP Complete (Phase 1-3)
- [ ] すべてのコア機能が実装される
- [ ] テストカバレッジ 80%以上
- [ ] Haddockカバレッジ 100%
- [ ] APIドキュメントが完成する
- [ ] Getting Startedガイドが完成する
- [ ] デプロイメント可能な状態

---

## References

### 関連ドキュメント
- `.kiro/specs/medicus-engine/` - MEDICUS Engineの仕様
- `reports/MEDICUS_CAPABILITIES.md` - 実装済み機能の詳細

### 技術スタック
- [Yesod](https://www.yesodweb.com/) - Webフレームワーク
- [Morpheus GraphQL](https://morpheusgraphql.com/) - GraphQLライブラリ
- [Persistent](https://www.yesodweb.com/book/persistent) - データベース抽象化（将来用）

### 学習リソース
- Yesod Book: https://www.yesodweb.com/book
- Morpheus GraphQL Documentation: https://morpheusgraphql.com/
- GraphQL Best Practices: https://graphql.org/learn/best-practices/

---

**Last Updated:** 2026-03-07  
**Version:** 0.1.0  
**Status:** Draft
