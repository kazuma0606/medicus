# Future Enhancements - MEDICUS API

このドキュメントは、MEDICUS APIの将来的な拡張機能をまとめたものです。Phase 1-3（MVPとコア機能実装）の完了後に、優先度と必要性に応じて実装を検討します。

---

## Phase 4: Data Visualization API

### Overview
MEDICUS.Visualizationモジュールを活用した可視化データ提供API。フロントエンドUI実装時に必要となる機能です。

### Requirements

#### Requirement: データ可視化API
**User Story:** As a UIエンジニア, I want 可視化データをGraphQL経由で取得できる, so that チャートやグラフをフロントエンドで描画できる

**Acceptance Criteria:**
1. WHEN `plotConvergence`クエリを実行する時 THEN システムは収束プロットのためのデータポイントを返す
2. WHEN `visualizeConstraints`クエリを実行する時 THEN システムは制約満足度の可視化データを返す
3. WHEN `exploreParameterSpace`クエリを実行する時 THEN システムはパラメータ空間探索の結果を返す
4. WHEN `sensitivityAnalysis`クエリを実行する時 THEN システムは感度分析の結果を返す
5. WHEN `generateReport`クエリを実行する時 THEN システムは最適化の全体レポートを返す

### GraphQL Schema Extensions

```graphql
extend type Query {
  """収束プロットデータの取得"""
  plotConvergence(resultId: ID!): ConvergencePlotData!
  
  """制約の可視化"""
  visualizeConstraints(
    spaceId: ID!
    point: [Float!]!
  ): ConstraintVisualization!
  
  """パラメータ空間の探索"""
  exploreParameterSpace(
    spaceId: ID!
    ranges: [ParameterRange!]!
    gridSize: Int
  ): ParameterSpaceData!
  
  """感度分析"""
  sensitivityAnalysis(
    resultId: ID!
    parameters: [Int!]!
  ): SensitivityAnalysisResult!
  
  """最適化レポートの生成"""
  generateReport(resultId: ID!): OptimizationReport!
}

type ConvergencePlotData {
  iterations: [Int!]!
  objectiveValues: [Float!]!
  gradientNorms: [Float!]!
  constraintViolations: [Float!]!
}

type ConstraintVisualization {
  constraints: [ConstraintStatus!]!
  overallSatisfaction: Float!
}

type ConstraintStatus {
  id: String!
  name: String!
  satisfied: Boolean!
  violation: Float!
  threshold: Float!
}

type ParameterSpaceData {
  gridPoints: [[Float!]!]!
  objectiveValues: [Float!]!
  feasibilityFlags: [Boolean!]!
}

type SensitivityAnalysisResult {
  parameters: [Int!]!
  sensitivities: [Float!]!
  partialDerivatives: [[Float!]!]!
}

type OptimizationReport {
  summary: String!
  convergencePlot: ConvergencePlotData!
  constraintAnalysis: ConstraintVisualization!
  recommendations: [String!]!
}
```

### Implementation Tasks

#### Task: Visualization Service Implementation
**Estimated:** 4-5h

**Subtasks:**
- [ ] Create `Service/Visualization.hs`
- [ ] Implement `plotConvergence` function
- [ ] Implement `visualizeConstraints` function
- [ ] Implement `exploreParameterSpace` function
- [ ] Implement `sensitivityAnalysis` function
- [ ] Implement `generateReport` function
- [ ] Integrate with MEDICUS.Visualization module

**Tests:**
- [ ] Unit tests for each visualization function
- [ ] Data format validation tests
- [ ] Large dataset performance tests

#### Task: Visualization Query Resolvers
**Estimated:** 3-4h

**Subtasks:**
- [ ] Create `GraphQL/Query/Visualization.hs`
- [ ] Implement all visualization query resolvers
- [ ] Add error handling
- [ ] Add result caching (optional)

**Tests:**
- [ ] Resolver unit tests
- [ ] Integration tests with MEDICUS.Visualization
- [ ] GraphQL query tests

---

## Phase 5: Database Integration

### Overview
Persistent（Yesodのデータベース抽象化層）を使用したPostgreSQL統合。最適化履歴の保存、空間設定のライブラリ化、ユーザー管理などを実現します。

### Requirements

#### Why Database?
現在のステートレス設計では、以下の機能が実現できません：
1. **最適化履歴の保存** - 過去の結果の参照・比較
2. **空間設定のライブラリ化** - よく使う設定の保存・再利用
3. **ユーザー管理** - マルチユーザー対応
4. **結果のキャッシング** - パフォーマンス向上
5. **監査ログ** - 操作履歴の追跡

### Database Schema

```haskell
-- Persistent model definition
share [mkPersist sqlSettings, mkMigrate "migrateAll"] [persistLowerCase|
User
    email Text
    name Text
    createdAt UTCTime
    UniqueEmail email
    deriving Show

Project
    userId UserId
    name Text
    description Text Maybe
    createdAt UTCTime
    deriving Show

SpaceConfig
    projectId ProjectId
    name Text
    dimension Int
    normWeightsLambda Double
    normWeightsMu Double
    normWeightsNu Double
    constraintsJson Text  -- JSON serialized
    createdAt UTCTime
    deriving Show

OptimizationRun
    spaceConfigId SpaceConfigId
    objectiveFunctionJson Text  -- JSON serialized
    initialPoint Text  -- JSON serialized
    resultJson Text  -- JSON serialized
    success Bool
    computationTimeMs Int
    createdAt UTCTime
    deriving Show
|]
```

### GraphQL Schema Extensions

```graphql
extend type Query {
  """プロジェクト一覧の取得"""
  listProjects: [Project!]!
  
  """プロジェクトの取得"""
  getProject(id: ID!): Project
  
  """空間設定一覧の取得"""
  listSpaceConfigs(projectId: ID!): [SpaceConfig!]!
  
  """最適化履歴の取得"""
  listOptimizationRuns(
    spaceConfigId: ID!
    limit: Int
    offset: Int
  ): OptimizationRunConnection!
}

extend type Mutation {
  """プロジェクトの作成"""
  createProject(input: CreateProjectInput!): Project!
  
  """空間設定の保存"""
  saveSpaceConfig(input: SaveSpaceConfigInput!): SpaceConfig!
}

type Project {
  id: ID!
  name: String!
  description: String
  spaceConfigs: [SpaceConfig!]!
  createdAt: DateTime!
}

type SpaceConfig {
  id: ID!
  name: String!
  dimension: Int!
  normWeights: NormWeights!
  constraints: [Constraint!]!
  createdAt: DateTime!
}

type OptimizationRunConnection {
  nodes: [OptimizationRun!]!
  totalCount: Int!
  pageInfo: PageInfo!
}
```

### Implementation Tasks

#### Task: Database Setup
**Estimated:** 4-5h

**Subtasks:**
- [ ] Add Persistent dependencies to cabal
- [ ] Define Persistent models
- [ ] Create migration scripts
- [ ] Setup connection pool
- [ ] Add database configuration to settings.yml

#### Task: Database Service Layer
**Estimated:** 6-8h

**Subtasks:**
- [ ] Create `Service/Database/Project.hs`
- [ ] Create `Service/Database/SpaceConfig.hs`
- [ ] Create `Service/Database/OptimizationRun.hs`
- [ ] Implement CRUD operations
- [ ] Add transaction support

#### Task: GraphQL Resolvers for Database
**Estimated:** 4-5h

**Subtasks:**
- [ ] Update existing resolvers to use database
- [ ] Add new database-related resolvers
- [ ] Add pagination support

**Tests:**
- [ ] Database integration tests
- [ ] Migration tests
- [ ] CRUD operation tests

---

## Phase 6: Authentication & Authorization

### Overview
JWT（JSON Web Token）ベースの認証と、ロールベースのアクセス制御を実装します。

### Requirements

#### Authentication
- JWT生成・検証
- トークンリフレッシュ
- パスワードハッシング（bcrypt）

#### Authorization
- ロールベースアクセス制御（RBAC）
  - Admin: すべての操作
  - User: 自分のプロジェクトのみ
  - Guest: 読み取りのみ
- リソースレベル権限チェック

### GraphQL Schema Extensions

```graphql
extend type Query {
  """現在のユーザー情報"""
  me: User
}

extend type Mutation {
  """ユーザー登録"""
  register(input: RegisterInput!): AuthPayload!
  
  """ログイン"""
  login(input: LoginInput!): AuthPayload!
  
  """トークンリフレッシュ"""
  refreshToken(refreshToken: String!): AuthPayload!
}

type User {
  id: ID!
  email: String!
  name: String!
  role: UserRole!
  createdAt: DateTime!
}

enum UserRole {
  ADMIN
  USER
  GUEST
}

type AuthPayload {
  token: String!
  refreshToken: String!
  user: User!
}

input RegisterInput {
  email: String!
  password: String!
  name: String!
}

input LoginInput {
  email: String!
  password: String!
}
```

### Implementation Tasks

#### Task: JWT Authentication
**Estimated:** 5-6h

**Subtasks:**
- [ ] Add JWT library dependencies
- [ ] Implement JWT generation/verification
- [ ] Add password hashing (bcrypt)
- [ ] Create User model (if not in Phase 5)
- [ ] Implement authentication middleware

#### Task: Authorization Logic
**Estimated:** 4-5h

**Subtasks:**
- [ ] Define roles and permissions
- [ ] Implement authorization checks
- [ ] Add role-based resolver guards
- [ ] Add resource ownership checks

#### Task: Auth Resolvers
**Estimated:** 3-4h

**Subtasks:**
- [ ] Implement register mutation
- [ ] Implement login mutation
- [ ] Implement refreshToken mutation
- [ ] Implement me query

**Tests:**
- [ ] Authentication tests
- [ ] Authorization tests
- [ ] JWT token tests
- [ ] Password hashing tests

---

## Phase 7: Caching & Performance

### Overview
Redis統合によるキャッシング、クエリ結果のキャッシュ、計算結果の再利用によるパフォーマンス向上を実現します。

### Requirements

#### Caching Strategy
1. **GraphQL Query Result Caching**
   - Key: hash(query + variables + user)
   - TTL: クエリタイプごとに設定可能
   
2. **Computation Result Caching**
   - 同一入力に対する最適化結果をキャッシュ
   - Key: hash(spaceConfig + objectiveFunction + initialPoint)
   - TTL: 1時間（設定可能）

3. **Space Configuration Caching**
   - In-memory LRU cache
   - よく使われる空間設定をメモリに保持

### Implementation Tasks

#### Task: Redis Integration
**Estimated:** 4-5h

**Subtasks:**
- [ ] Add Redis client dependencies
- [ ] Setup Redis connection pool
- [ ] Create caching utility module
- [ ] Add cache configuration

#### Task: Query Result Caching
**Estimated:** 3-4h

**Subtasks:**
- [ ] Implement cache key generation
- [ ] Add caching middleware
- [ ] Implement cache invalidation logic

#### Task: Computation Caching
**Estimated:** 3-4h

**Subtasks:**
- [ ] Add caching to optimization resolver
- [ ] Implement smart cache invalidation
- [ ] Add cache statistics

**Tests:**
- [ ] Cache hit/miss tests
- [ ] Cache invalidation tests
- [ ] Performance improvement tests

---

## Phase 8: GraphQL Subscriptions (Real-time)

### Overview
GraphQL Subscriptionsによるリアルタイム通知機能。長時間実行される最適化の進捗をリアルタイムで通知します。

### GraphQL Schema Extensions

```graphql
type Subscription {
  """最適化の進捗通知"""
  optimizationProgress(runId: ID!): OptimizationProgress!
  
  """新規最適化実行の通知（プロジェクト単位）"""
  newOptimizationRun(projectId: ID!): OptimizationRun!
}

type OptimizationProgress {
  runId: ID!
  iteration: Int!
  objectiveValue: Float!
  constraintViolation: Float!
  status: OptimizationStatus!
}

enum OptimizationStatus {
  RUNNING
  CONVERGED
  FAILED
  TIMEOUT
}
```

### Implementation Tasks

#### Task: Subscriptions Setup
**Estimated:** 5-6h

**Subtasks:**
- [ ] Add WebSocket support to Yesod
- [ ] Configure Morpheus GraphQL Subscriptions
- [ ] Implement subscription resolvers

#### Task: Progress Tracking
**Estimated:** 4-5h

**Subtasks:**
- [ ] Modify optimization service to emit progress events
- [ ] Implement event broadcasting
- [ ] Add subscription filters

**Tests:**
- [ ] Subscription connection tests
- [ ] Progress event tests
- [ ] WebSocket tests

---

## Phase 9: Admin UI & Monitoring

### Overview
Yesod Templatesを使用した管理UIと、Prometheusメトリクスによるモニタリング機能。

### Admin UI Features
- ユーザー管理
- プロジェクト管理
- 最適化ジョブの監視
- システム設定
- ログビューア

### Monitoring Features
- APIリクエストメトリクス
- 最適化パフォーマンスメトリクス
- エラーレート
- レスポンスタイム分布

### Implementation Tasks

#### Task: Admin UI
**Estimated:** 10-12h

**Subtasks:**
- [ ] Create Yesod templates for admin pages
- [ ] Implement admin routes
- [ ] Add admin authentication
- [ ] Create dashboard

#### Task: Prometheus Metrics
**Estimated:** 4-5h

**Subtasks:**
- [ ] Add prometheus-client library
- [ ] Define custom metrics
- [ ] Add metrics middleware
- [ ] Create /metrics endpoint

**Tests:**
- [ ] UI functional tests
- [ ] Metrics collection tests

---

## Phase 10: Microservices Architecture (Long-term)

### Overview
将来的なスケーリング要求に備えた、マイクロサービスへの分割。

### Service Decomposition

```
┌─────────────────┐
│  API Gateway    │
│  (GraphQL)      │
└────────┬────────┘
         │
    ┌────┴────┐
    │         │
┌───▼───┐ ┌──▼────┐
│ Space │ │  Opt  │
│Service│ │Service│
└───┬───┘ └───┬───┘
    │         │
    └────┬────┘
         │
    ┌────▼────┐
    │   DB    │
    └─────────┘
```

### Services
1. **Space Service** - 空間管理
2. **Optimization Service** - 最適化実行
3. **Visualization Service** - 可視化データ生成
4. **Auth Service** - 認証・認可
5. **API Gateway** - GraphQL統合エンドポイント

### Implementation Considerations
- サービス間通信（gRPC or HTTP/JSON）
- 分散トレーシング（Jaeger）
- サービスディスカバリー
- 負荷分散

---

## Priority Matrix

| Phase | Feature | Priority | Complexity | Value |
|-------|---------|----------|------------|-------|
| 4 | Visualization API | Medium | Low | High (with UI) |
| 5 | Database | High | Medium | High |
| 6 | Auth | High | Medium | High |
| 7 | Caching | Medium | Low | Medium |
| 8 | Subscriptions | Low | Medium | Medium |
| 9 | Admin UI | Medium | High | Medium |
| 10 | Microservices | Low | Very High | Low (initially) |

## Recommended Implementation Order

### After MVP (Phase 1-3)
1. **Phase 5: Database** - 履歴管理の基盤
2. **Phase 6: Auth** - セキュリティ基盤
3. **Phase 4: Visualization** - UI実装時
4. **Phase 7: Caching** - パフォーマンス改善

### Future
5. **Phase 8: Subscriptions** - リアルタイム要求時
6. **Phase 9: Admin UI** - 運用管理が必要になったら
7. **Phase 10: Microservices** - スケーリング要求時

---

## Estimated Total Effort

| Phase | Tasks | Estimated Hours |
|-------|-------|----------------|
| 4. Visualization | 2 tasks | 7-9h |
| 5. Database | 3 tasks | 14-18h |
| 6. Auth | 3 tasks | 12-15h |
| 7. Caching | 3 tasks | 10-13h |
| 8. Subscriptions | 2 tasks | 9-11h |
| 9. Admin & Monitoring | 2 tasks | 14-17h |
| 10. Microservices | - | 40-60h |
| **Total (Phase 4-9)** | | **66-83h** |
| **Total (Phase 4-10)** | | **106-143h** |

---

## Migration Path

### From MVP to Full System

#### Step 1: Add Database (Phase 5)
- Minimal disruption: API remains stateless initially
- Gradually migrate to database-backed storage
- Keep JSON export/import for backward compatibility

#### Step 2: Add Authentication (Phase 6)
- Add optional authentication first (anonymous access allowed)
- Gradually enforce authentication
- Migrate existing data to user accounts

#### Step 3: Add Other Features
- Independent features can be added in any order
- Each phase is designed to be non-breaking

---

**Last Updated:** 2026-03-07  
**Version:** 0.1.0  
**Status:** Future Planning
