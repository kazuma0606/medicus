# MEDICUS API - Specification Documents

MEDICUS Engine（医療データセキュリティ最適化計算エンジン）をWeb API化するプロジェクトの要件定義・設計ドキュメントです。

## 📋 ドキュメント一覧

### 1. [requirements.md](./requirements.md)
**要件定義書** - ユーザーストーリーベースの機能要件（Phase 1-3）

#### 主要要件（8個）
1. **GraphQL API基盤** - Morpheus GraphQLによる型安全なAPI
2. **MEDICUS空間操作API** - 空間の作成・検証
3. **最適化実行API** - Newton法による最適化実行
4. **エラーハンドリング** - 型安全で明確なエラーメッセージ
5. **パフォーマンス** - 並列処理とバッチ評価
6. **Yesod統合** - Webフレームワーク基盤
7. **テストとCI/CD** - 包括的なテストスイート
8. **ドキュメント** - GraphQL Playground、Introspection

#### Non-Functional Requirements
- パフォーマンス目標
- セキュリティ要件
- 可用性・保守性・スケーラビリティ

### 2. [design.md](./design.md)
**設計書** - アーキテクチャとモジュール構成（Phase 1-3）

#### 主要内容
- **System Architecture** - 4層アーキテクチャ（Client, API, Business Logic, MEDICUS Engine）
- **Module Structure** - ディレクトリ構成とモジュール設計
- **GraphQL Schema** - コアAPIスキーマ定義（Query, Mutation, Types）
- **Core Components**
  - Schema Definition (Morpheus GraphQL)
  - Resolver Implementation
  - Service Layer (Business Logic)
  - Yesod Foundation
  - Configuration Management
- **Data Flow** - リクエスト→レスポンスの流れ
- **Type Conversion** - GraphQL ↔ MEDICUS Engineの型変換
- **Error Handling** - エラー型とハンドリング戦略
- **Testing Strategy** - ユニット、統合、E2Eテスト
- **Performance** - クエリ複雑度、並列処理
- **Deployment** - Docker、本番環境構成

### 3. [tasks.md](./tasks.md)
**タスクリスト** - 実装タスクの詳細とチェックリスト（Phase 1-3）

#### フェーズ構成（3フェーズ、21タスク）
1. **Phase 1: Foundation** (Task 1-4) - プロジェクト初期化、Yesod基盤、GraphQLスキーマ、Playground
2. **Phase 2: Core API** (Task 5-10) - 型変換、サービス層、リゾルバ実装
3. **Phase 3: Quality & Docs** (Task 11-21) - エラーハンドリング、ログ、テスト、ドキュメント、デプロイメント

#### マイルストーン
- **Milestone 1: Foundation Complete** (Week 1-2) - Yesod + GraphQL基盤
- **Milestone 2: Core API Complete** (Week 3-4) - 空間・最適化API実装
- **Milestone 3: Quality Assurance** (Week 5-6) - テスト80%+、エラーハンドリング
- **Milestone 4: MVP Complete** (Week 7-8) - ドキュメント、Docker、デプロイ可能

#### 見積もり
- **Phase 1-3 (Task 1-21)**: 71-91時間
- **タイムライン**: 7-8週間（パートタイム）or 2-3週間（フルタイム）

### 4. [future-enhancements.md](./future-enhancements.md)
**将来的な拡張機能** - Phase 4以降の詳細設計

#### Phase 4以降の機能
1. **Phase 4: データ可視化API** (7-9h) - UI実装時に必要
2. **Phase 5: データベース統合** (14-18h) - PostgreSQL + Persistent
3. **Phase 6: 認証・認可** (12-15h) - JWT、RBAC
4. **Phase 7: キャッシング** (10-13h) - Redis統合
5. **Phase 8: リアルタイム通知** (9-11h) - GraphQL Subscriptions
6. **Phase 9: 管理UI・モニタリング** (14-17h) - Yesod Templates、Prometheus
7. **Phase 10: マイクロサービス化** (40-60h) - 長期的なスケーリング

**Phase 4-9 合計**: 66-83時間

## 🎯 プロジェクト概要

### 技術スタック
- **Webフレームワーク**: Yesod 1.6+
- **GraphQL**: Morpheus GraphQL
- **計算エンジン**: MEDICUS Engine (medicus-engine library)
- **テスト**: Hspec, Yesod Test
- **デプロイ**: Docker
- **将来**: PostgreSQL (Persistent), Redis (Cache), JWT (Auth)

### 主要機能（Phase 1-3）
1. **空間管理**
   - MEDICUS空間の作成・検証
   - 制約条件の設定
   - ノルム重みの調整

2. **最適化**
   - Newton法による高速最適化
   - バッチ処理・並列評価
   - 収束履歴の追跡

3. **開発者体験**
   - GraphQL Playground
   - Introspection（自動ドキュメント）
   - 型安全なAPI
   - 明確なエラーメッセージ

### 将来の拡張機能（Phase 4+）
- **可視化API** - 収束プロット、制約可視化、パラメータ空間探索（UI実装時）
- **データベース** - 最適化履歴、空間設定ライブラリ
- **認証・認可** - ユーザー管理、アクセス制御
- **リアルタイム通知** - 最適化進捗のWebSocket通知

詳細は [`future-enhancements.md`](./future-enhancements.md) を参照

### アーキテクチャの特徴
- **型安全**: Haskell + Morpheus GraphQLによるコンパイル時型チェック
- **レイヤードアーキテクチャ**: プレゼンテーション、ビジネスロジック、計算エンジンの分離
- **ステートレス設計**: 水平スケーリング対応（将来）
- **テスタブル**: 依存性注入、モジュール境界の明確化

## 📊 GraphQL Schema 概要（Phase 1-3）

### Query
- `validateSpace` - 空間設定の検証
- `listAvailableConstraints` - 利用可能な制約タイプ一覧
- `health` - ヘルスチェック

### Mutation
- `createSpace` - MEDICUS空間の作成
- `deleteSpace` - MEDICUS空間の削除
- `optimize` - 最適化の実行
- `optimizeBatch` - バッチ最適化の実行

### 主要な型
- `SpaceConfigInput` - 空間設定（次元、ノルム重み、制約）
- `OptimizationInput` - 最適化入力（目的関数、初期点、オプション）
- `OptimizationResult` - 最適化結果（解、目的関数値、収束情報、履歴）
- `ValidationResult` - 検証結果（エラー、警告）
- `ConvergenceHistory` - 収束履歴（イテレーション、目的関数値、制約違反）

### 将来追加予定（Phase 4+）
- `getSpaceInfo`, `plotConvergence`, `visualizeConstraints`, `exploreParameterSpace` など
- 詳細は [`future-enhancements.md`](./future-enhancements.md) を参照

## 🚀 開発の進め方

### Step 1: ドキュメントレビュー
1. `requirements.md`を読む - 何を作るか理解
2. `design.md`を読む - どう作るか理解
3. `tasks.md`を読む - 何から始めるか確認

### Step 2: プロジェクト初期化
```bash
# Task 1-2: プロジェクトセットアップ
cd medicus_theory
mkdir medicus-api
cd medicus-api
cabal init
```

### Step 3: 段階的実装（Phase 1-3）
- **Week 1-2 (Phase 1)**: Task 1-4（基盤、GraphQL）
- **Week 3-4 (Phase 2)**: Task 5-10（サービス層、リゾルバ）
- **Week 5-6 (Phase 3前半)**: Task 11-16（エラー、ログ、テスト）
- **Week 7-8 (Phase 3後半)**: Task 17-21（ドキュメント、デプロイ）

### Step 4: テスト駆動開発
1. タスクを選択
2. テストを先に書く
3. 実装する
4. テストを通す
5. リファクタリング
6. `tasks.md`をチェック✅

### Step 5: 継続的統合
- コミット前に `cabal test` を実行
- テストカバレッジ80%以上を維持
- Haddockカバレッジ100%を維持

## 📚 関連ドキュメント

### 親プロジェクト
- `.kiro/specs/medicus-engine/` - MEDICUS Engine仕様
- `reports/` - MEDICUS Engine実装レポート
- `reports/MEDICUS_CAPABILITIES.md` - システム能力分析

### 参考資料
- [Yesod Book](https://www.yesodweb.com/book)
- [Morpheus GraphQL Documentation](https://morpheusgraphql.com/)
- [GraphQL Best Practices](https://graphql.org/learn/best-practices/)

## 🔄 ドキュメント管理

### 更新ルール
1. 要件変更 → `requirements.md`を更新
2. 設計変更 → `design.md`を更新
3. タスク完了 → `tasks.md`をチェック✅
4. 重要な設計判断 → ADR（Architecture Decision Record）を作成

### バージョン管理
- 各ドキュメントの末尾に「Last Updated」を記載
- 大きな変更時はバージョン番号を更新
- Git履歴で変更を追跡

## ✅ Next Steps

1. **このREADMEを読む** ← 今ここ
2. **`requirements.md`をレビュー** - Phase 1-3の要件を理解
3. **`design.md`をレビュー** - Phase 1-3のアーキテクチャを理解
4. **`tasks.md`をレビュー** - 実装計画（21タスク）を確認
5. **`future-enhancements.md`を確認** - Phase 4以降の拡張機能を把握（参考）
6. **Task 1から実装開始** - プロジェクトセットアップ

---

**Project Status:** 🟨 Planning Phase (Phase 1-3 Scope Defined)  
**Implementation Scope:** Phase 1-3 (MVP & Core Features)  
**Estimated Effort:** 71-91 hours (7-8 weeks part-time)  
**Last Updated:** 2026-03-07  
**Version:** 0.1.0  
**Branch:** `web_api`
