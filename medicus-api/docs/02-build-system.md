# ビルドシステムガイド

MEDICUS APIのビルドシステム（StackとCabal）の設定について説明します。

## ビルドツールの選択

### Stack vs Cabal

| 特徴 | Stack | Cabal |
|---|---|---|
| 依存解決 | スナップショットベース | 最新版を解決 |
| 再現性 | 高い | 中程度 |
| 学習曲線 | 緩やか | 急 |
| GHC管理 | 自動 | 手動 |

**MEDICUS APIではStackを採用**

理由：
- 依存関係の再現性が高い
- GHCのバージョン管理が容易
- morpheus-graphqlの複雑な依存関係に対応しやすい

## stack.yaml の設定

### 基本構造

```yaml
# GHCバージョンを指定するスナップショット
resolver: nightly-2024-03-10  # GHC 9.8対応

# ビルド対象のパッケージ
packages:
  - .

# スナップショットに含まれない追加依存関係
extra-deps:
  - package-name-version@sha256:hash,size

# システムにインストールされているGHCを使用
system-ghc: true
install-ghc: false
skip-ghc-check: true

# ビルドオプション
ghc-options:
  "$locals": -Wall -Wcompat -fno-warn-orphans
```

### Resolver選択

resolverはGHCバージョンとパッケージセットを決定します：

```yaml
# LTS (Long Term Support)
resolver: lts-22.7  # GHC 9.6.4

# Nightly (最新版)
resolver: nightly-2024-03-10  # GHC 9.8.x

# 特定のGHCバージョン
resolver: ghc-9.8.2
```

**推奨:** GHC 9.8.2がシステムにある場合は`nightly-2024-03-10`

### extra-deps の管理

morpheus-graphql 0.28.4は多くの依存パッケージを必要とします：

```yaml
extra-deps:
  # morpheus-graphql本体
  - morpheus-graphql-0.28.4@sha256:03904ba010ed9d0d83ff7ff1a266b2b483cdb69521a63b75aa1d8855c84abfb2,17792
  - morpheus-graphql-app-0.28.4@sha256:d5896b9b74ffdca8ab58ffd12a93b9de3f3ab2aae193ad9e1ec39743a87b8ef8,9201
  
  # morpheus-graphqlの依存関係
  - morpheus-graphql-code-gen-0.28.4@sha256:0d8b2a64794fa57595e1f771475178c0594bc82ed34211ed437bfabe82198bb7,2757
  - morpheus-graphql-core-0.28.4@sha256:7ee1d1cc3e35d3c286a48023d85ada0e980bc4d78653f582deab3eb0fc2b8561,14208
  - morpheus-graphql-server-0.28.4@sha256:449dc664f08d8a7c09e2b4f10332512d4252ca9ac072d9d9e3e60a700f08d17d,24589
  - morpheus-graphql-client-0.28.4@sha256:60115e026b4c291cd35db9124922caeded5803d9b4e58a8e5dd4b6f23a9fc242,5334
  - morpheus-graphql-code-gen-utils-0.28.4@sha256:a9fe54791958a40c2956bff431fea189ef4acdb35632f8338a29eae87b8aaf8b,1570
  - morpheus-graphql-subscriptions-0.28.4@sha256:9d60a54d9a1889cc39dee59ab825536576594a90333ab1fddebfabf39e0455df,1783
```

### 依存関係の見つけ方

Stackが足りない依存関係を教えてくれます：

```bash
$ stack build
Error: [S-4804]
       In the dependencies for medicus-api-0.1.0.0:
         * morpheus-graphql must match >=0.27, but no version is in the Stack configuration
       
       Recommended action: try adding the following to your extra-deps:
       - morpheus-graphql-0.28.4@sha256:...,17792
```

このメッセージに従って`extra-deps`に追加していきます。

## medicus-api.cabal の設定

### library stanza

```cabal
library
  exposed-modules:
      -- Foundation
      Foundation
      Settings
      Import
      Application
      
      -- GraphQL
      GraphQL.Schema
      GraphQL.Resolvers
      
      -- GraphQL Types
      GraphQL.Types.Space
      GraphQL.Types.Optimization
      GraphQL.Types.Error
      GraphQL.Types.Common
      
      -- Handlers
      Handler.GraphQL
      Handler.Health
      Handler.Playground

  hs-source-dirs:
      src
  
  default-extensions:
      OverloadedStrings
      RecordWildCards
      DeriveGeneric
      DeriveAnyClass
      TypeFamilies
      FlexibleContexts
      GADTs
      MultiParamTypeClasses
      QuasiQuotes
      TemplateHaskell
      TypeApplications
```

### 重要な拡張機能

| 拡張機能 | 用途 |
|---|---|
| `DeriveGeneric` | Generic derivingに必要 |
| `DeriveAnyClass` | GQLType derivingに必要 |
| `OverloadedStrings` | Text型の文字列リテラル |
| `TypeFamilies` | Yesodに必要 |
| `TemplateHaskell` | Yesodのルート生成に必要 |

### executable stanza

```cabal
executable medicus-api
  main-is: Main.hs
  hs-source-dirs: app
  
  ghc-options:
      -threaded
      -rtsopts
      -with-rtsopts=-N
      -Wall
  
  build-depends:
      base
    , medicus-api
    , yesod
    , yesod-core
    , wai
    , warp
    , text
    , bytestring
    , yaml
```

**注意:** executableも必要な依存関係を明示的に記述します。

## ビルドコマンド

### 基本コマンド

```bash
# クリーンビルド
stack clean
stack build

# 高速ビルド（最適化なし）
stack build --fast

# 詳細ログ付き
stack build --verbose

# 特定のターゲットのみ
stack build medicus-api:lib
stack build medicus-api:exe:medicus-api
```

### ビルドプロセスの段階

1. **依存関係の解決** - `stack.yaml`の`extra-deps`を確認
2. **パッケージのダウンロード** - Hackageから取得
3. **依存パッケージのコンパイル** - 144個のパッケージをコンパイル（初回）
4. **プロジェクトのコンパイル** - medicus-apiのビルド
5. **実行可能ファイルの生成** - `.stack-work/install/`に配置

### 初回ビルドの時間

| フェーズ | 時間 | 備考 |
|---|---|---|
| パッケージダウンロード | 5-10分 | ネットワーク速度依存 |
| 依存パッケージコンパイル | 20-40分 | CPU性能依存 |
| プロジェクトコンパイル | 1-3分 | - |
| **合計** | **30-60分** | 初回のみ |

2回目以降は変更部分のみコンパイルされるため、数秒〜数分で完了します。

## ビルドの最適化

### 並列コンパイル

```yaml
# stack.yaml
build:
  jobs: 4  # CPUコア数に応じて調整
```

または

```bash
stack build -j4
```

### キャッシュの活用

```bash
# グローバルキャッシュの確認
stack path --global-pkg-db

# プロジェクトキャッシュの確認
stack path --local-pkg-db
```

### メモリ使用量の制限

GHCはメモリを大量に使用します：

```yaml
# stack.yaml
ghc-options:
  "$everything": -j +RTS -A128m -n2m -RTS
```

## cabal.project の設定

`medicus-api/`直下に配置：

```cabal
packages:
  .

-- 将来的にmedicus-engineを追加
-- packages:
--   .
--   ../medicus-engine

-- Cabal 3.10.3.0の問題を回避
constraints: Cabal <3.10.3 || >=3.12

-- 互換性のための許容
allow-newer: all

-- ビルドオプション
package medicus-api
  ghc-options: -Wall -Wcompat -fno-warn-orphans
```

## 依存関係のトラブルシューティング

### "No version is in the Stack configuration"

**対処法:** `extra-deps`に追加

```bash
$ stack build
Error: morpheus-graphql-core must match >=0.28.0 && <0.29.0

# extra-depsに以下を追加：
- morpheus-graphql-core-0.28.4@sha256:...,14208
```

### ハッシュ検証エラー

```bash
Error: [S-2905]
       Verification error: Invalid hash for <repo>/snapshot.json
```

**対処法:**
```bash
# キャッシュをクリア
stack purge

# Hackageインデックスを更新
stack update

# 再ビルド
stack build
```

### ディスク容量不足

```bash
Error: Cannot set length for output file
```

**対処法:**
- 5GB以上の空き容量を確保
- または`system-ghc: true`でシステムのGHCを使用

## ベストプラクティス

### 1. resolverの固定

本番環境では特定のresolverを使用：

```yaml
resolver: lts-22.7  # 変更しない
```

### 2. extra-depsのバージョン固定

SHA256ハッシュとサイズを含める：

```yaml
extra-deps:
  - morpheus-graphql-0.28.4@sha256:03904ba...,17792
  #                          ^^^^^^^^^^^^^^^^    ^^^^^
  #                          ハッシュ              サイズ
```

### 3. ローカル依存関係の管理

```yaml
# monorepo構造の場合
packages:
  - medicus-api
  - medicus-engine
```

### 4. ビルドログの保存

```bash
# ビルドログを保存
stack build 2>&1 | tee build.log
```

## 次のステップ

- [03-graphql-integration.md](./03-graphql-integration.md) - GraphQL統合の詳細
- [07-build-issues.md](./07-build-issues.md) - 実際に遭遇した問題と解決法
