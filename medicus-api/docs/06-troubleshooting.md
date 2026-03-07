# トラブルシューティング ガイド

よくある問題と解決方法のクイックリファレンスです。

## 🚨 ビルドエラー

### "No version is in the Stack configuration"

**症状:**
```
Error: [S-4804]
       morpheus-graphql must match >=0.27, but no version is in the Stack configuration
```

**解決策:**
```yaml
# stack.yamlのextra-depsに追加
extra-deps:
  - morpheus-graphql-0.28.4@sha256:03904ba...,17792
```

Stackが推奨する形式をそのままコピペしてください。

---

### "Could not find module"

**症状:**
```
Could not load module 'Data.Conduit'.
It is a member of the hidden package 'conduit-1.3.5'.
```

**解決策:**
```cabal
# medicus-api.cabalのbuild-dependsに追加
build-depends:
    , conduit >= 1.3
```

---

### "Module graph contains a cycle"

**症状:**
```
Module graph contains a cycle:
      module 'Handler.Playground' imports 'Import'
which imports 'Foundation'
which imports 'Handler.Playground'
```

**解決策:**
`mkYesodData`と`mkYesodDispatch`を分離：

```haskell
-- Foundation.hs
mkYesodData "App" $(parseRoutesFile "config/routes.txt")

-- Application.hs  
import Handler.Health
import Handler.GraphQL
mkYesodDispatch "App" resourcesApp
```

---

### "can't find source for"

**症状:**
```
Error: can't find source for GraphQL\Query\Space
```

**解決策:**
`.cabal`ファイルの`exposed-modules`から存在しないモジュールを削除：

```bash
# 実際に存在するファイルを確認
ls medicus-api/src/**/*.hs

# .cabalファイルを実際のファイルに合わせて更新
```

---

## 🔧 型エラー

### "Couldn't match type 'IO' with 'Resolver'"

**症状:**
```
Couldn't match type 'IO' with 'Resolver QUERY () IO'
Expected: Query (Resolver QUERY () IO)
  Actual: Query IO
```

**解決策:**
```haskell
import Data.Morpheus.Types (lift)

-- ❌ 間違い
resolveQuery = Query
    { health = resolveHealth  -- IO HealthStatus
    }

-- ✅ 正しい
resolveQuery = Query
    { health = lift resolveHealth  -- Resolver QUERY () IO HealthStatus
    }
```

---

### "Illegal term-level use of 'Undefined'"

**症状:**
```
Illegal term-level use of the type constructor or class 'Undefined'
Perhaps use variable 'undefined'
```

**解決策:**
```haskell
-- ❌ 間違い（大文字）
subscriptionResolver = Undefined

-- ✅ 正しい（小文字）
subscriptionResolver = undefined
```

---

### "No instance for 'GQLType'"

**症状:**
```
No instance for 'GQLType MyType' arising from a use of 'GQLType'
```

**解決策:**
```haskell
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

import GHC.Generics (Generic)
import Data.Morpheus.Types (GQLType)

data MyType = MyType { field :: Text }
    deriving (Generic, GQLType)  -- 両方必要
```

---

## 🌐 ランタイムエラー

### サーバーが起動しない

**チェックリスト:**

1. **ポートが使用中か確認**
   ```bash
   # Windows
   netstat -ano | findstr :3000
   
   # macOS/Linux
   lsof -i :3000
   ```

2. **設定ファイルが存在するか**
   ```bash
   ls config/settings.yml
   ```

3. **環境変数を確認**
   ```bash
   echo $YESOD_ENV
   ```

---

### "Connection refused"

**症状:**
```
curl: (7) Failed to connect to localhost port 3000: Connection refused
```

**解決策:**

1. サーバーが起動しているか確認
   ```bash
   ps aux | grep medicus-api
   ```

2. ログを確認
   ```bash
   tail -f server.log
   ```

3. ファイアウォール設定を確認

---

### GraphQLクエリが失敗する

**症状:**
```json
{
  "errors": [
    {
      "message": "Syntax Error: Expected Name, found }"
    }
  ]
}
```

**解決策:**

1. **Prettifyボタンで構文チェック**
2. **DOCSパネルで正しいフィールド名を確認**
3. **サーバーログでエラー詳細を確認**

---

## 🔍 デバッグ方法

### ログレベルの変更

```yaml
# config/settings.yml
logging:
  level: "DEBUG"  # INFO, WARN, ERROR, DEBUG
  format: "json"
```

サーバー再起動後、詳細なログが出力されます。

---

### GHCiでの対話的デバッグ

```bash
# GHCiでモジュールをロード
stack ghci medicus-api:lib

# 関数をテスト
ghci> import GraphQL.Resolvers
ghci> resolveHealth
HealthStatus {status = "healthy", ...}

# 型を確認
ghci> :type resolveHealth
resolveHealth :: IO HealthStatus
```

---

### ユニットテストの実行

```bash
# すべてのテストを実行
stack test

# 特定のテストのみ
stack test --test-arguments "--match 'GraphQL'"

# 詳細出力
stack test --test-arguments "--verbose"
```

---

## 🐛 よくある実装ミス

### 1. OverloadedStringsの不足

**症状:**
```
Couldn't match type '[Char]' with 'Text'
```

**解決策:**
```haskell
{-# LANGUAGE OverloadedStrings #-}
```

---

### 2. ByteString vs Text

**症状:**
```
Couldn't match type 'ByteString' with 'Text'
```

**解決策:**
```haskell
import Data.Text.Encoding (decodeUtf8, encodeUtf8)

-- ByteString -> Text
let text = decodeUtf8 byteString

-- Text -> ByteString
let bs = encodeUtf8 text
```

---

### 3. Maybeの扱い

**症状:**
```
Couldn't match type 'Maybe a' with 'a'
```

**解決策:**
```haskell
-- パターンマッチ
case maybeValue of
    Just v -> ...
    Nothing -> ...

-- または
maybe defaultValue processValue maybeValue
```

---

### 4. リストの空チェック

**症状:**
```
Exception: Prelude.head: empty list
```

**解決策:**
```haskell
-- ❌ 危険
let first = head list

-- ✅ 安全
case list of
    (x:xs) -> x
    [] -> defaultValue

-- または
import Data.List.NonEmpty (NonEmpty((:|)))
```

---

## 🔌 ネットワーク問題

### CORS エラー

**症状（ブラウザコンソール）:**
```
Access to fetch at 'http://localhost:3000/graphql' from origin 'http://localhost:8080'
has been blocked by CORS policy
```

**解決策:**
```yaml
# config/settings.yml
cors:
  enabled: true
  origins:
    - "*"  # 開発環境
    # - "http://localhost:8080"  # 本番環境は特定のオリジンのみ
```

---

### OPTIONS リクエストの失敗

**症状:**
```
Method OPTIONS not allowed
```

**解決策:**
```
# config/routes.txt
/graphql GraphQLR POST OPTIONS
```

```haskell
-- Handler/GraphQL.hs
optionsGraphQLR :: Handler ()
optionsGraphQLR = do
    addHeader "Access-Control-Allow-Origin" "*"
    addHeader "Access-Control-Allow-Methods" "POST, OPTIONS"
    addHeader "Access-Control-Allow-Headers" "Content-Type"
    return ()
```

---

## 📦 依存関係の問題

### Hackage インデックスの更新

**症状:**
```
No package index found, updating
```

**解決策:**
```bash
stack update
```

初回は時間がかかります（5-10分）。

---

### キャッシュの破損

**症状:**
```
Error: [S-2905]
       Verification error: Invalid hash
```

**解決策:**
```bash
# キャッシュをクリア
stack purge

# インデックス更新
stack update

# 再ビルド
stack build
```

---

### バージョン競合

**症状:**
```
Error: Dependency conflict for package xyz
```

**解決策:**

1. **allow-newerの使用（慎重に）**
   ```yaml
   # stack.yaml
   allow-newer: true
   ```

2. **resolverの変更**
   ```yaml
   # より新しいスナップショットを試す
   resolver: nightly-2024-03-15
   ```

3. **パッケージバージョンの固定**
   ```yaml
   extra-deps:
     - package-name-1.2.3@sha256:...
   ```

---

## 🎯 パフォーマンス問題

### ビルドが遅い

**解決策:**

```yaml
# stack.yaml
build:
  jobs: 4  # CPU コア数

ghc-options:
  "$everything": -j4  # 並列コンパイル
```

---

### メモリ不足

**症状:**
```
GHC internal error: ...
```

**解決策:**

```yaml
ghc-options:
  "$everything": +RTS -M4G -RTS  # 最大4GBに制限
```

---

### 実行時のパフォーマンス問題

**対処法:**

1. **最適化ビルド**
   ```bash
   stack build --ghc-options="-O2"
   ```

2. **プロファイリング**
   ```bash
   stack build --profile
   stack exec -- medicus-api +RTS -p
   ```

---

## 🛠️ 開発ツール

### 推奨エディタ設定

#### VSCode / Cursor

```json
{
  "haskell.manageHLS": "GHCup",
  "haskell.serverExecutablePath": "haskell-language-server",
  "[haskell]": {
    "editor.formatOnSave": true,
    "editor.tabSize": 4
  }
}
```

#### HLS（Haskell Language Server）

```bash
# インストール
stack install haskell-language-server

# プロジェクトで有効化
stack exec -- haskell-language-server
```

---

### 便利なStackコマンド

```bash
# 依存関係のツリー表示
stack ls dependencies

# パッケージ情報
stack path

# GHCの確認
stack exec -- ghc --version

# プロジェクト情報
stack query

# クリーンアップ
stack clean --full
```

---

## 📞 サポート

### 情報収集

問題が解決しない場合、以下の情報を収集：

```bash
# 1. 環境情報
stack --version
ghc --version
cabal --version

# 2. ビルドログ（詳細）
stack build --verbose > build-verbose.log 2>&1

# 3. 依存関係情報
stack ls dependencies > dependencies.txt

# 4. プロジェクト情報
stack query > project-info.txt
```

### 参照すべきリソース

1. **本ドキュメント:**
   - [07-build-issues.md](./07-build-issues.md) - 実際に解決した問題の詳細

2. **公式ドキュメント:**
   - [Morpheus GraphQL](https://morpheusgraphql.com/)
   - [Yesod](https://www.yesodweb.com/)
   - [Stack](https://docs.haskellstack.org/)

3. **コミュニティ:**
   - [Morpheus GraphQL Slack](https://morpheus-graphql-slack.herokuapp.com/)
   - [Haskell Discourse](https://discourse.haskell.org/)
   - [Stack Overflow](https://stackoverflow.com/questions/tagged/haskell+graphql)

---

## 🔍 診断フローチャート

### ビルドが失敗する場合

```
ビルドエラー？
├─ 依存関係の問題？
│  ├─ Yes → stack.yamlのextra-depsを確認
│  └─ No → 次へ
├─ 型エラー？
│  ├─ Yes → 07-build-issues.mdの型エラーセクションを参照
│  └─ No → 次へ
├─ モジュールが見つからない？
│  ├─ Yes → .cabalのbuild-dependsに追加
│  └─ No → 次へ
└─ その他？
   └─ stack clean && stack build --verbose
```

### サーバーが起動しない場合

```
起動エラー？
├─ 設定ファイルの問題？
│  ├─ Yes → config/settings.ymlを確認
│  └─ No → 次へ
├─ ポートの競合？
│  ├─ Yes → netstatで確認、settings.ymlのport変更
│  └─ No → 次へ
└─ ログを確認
   └─ stack exec medicus-api 2>&1 | tee server.log
```

### GraphQLクエリが失敗する場合

```
クエリエラー？
├─ 構文エラー？
│  ├─ Yes → Prettifyボタンで整形
│  └─ No → 次へ
├─ フィールドが存在しない？
│  ├─ Yes → DOCSパネルで確認
│  └─ No → 次へ
├─ 型が合わない？
│  ├─ Yes → Introspectionで型定義を確認
│  └─ No → 次へ
└─ サーバー側のエラー？
   └─ サーバーログを確認
```

---

## 🚀 クイックフィックス集

### ビルドのクリーンアップ

```bash
# 軽度のクリーンアップ
stack clean

# 完全なクリーンアップ
stack purge

# キャッシュを保持してクリーン
stack clean --full
```

---

### 依存関係のリセット

```bash
# 依存関係を再計算
rm -rf .stack-work
stack build
```

---

### 設定の確認

```bash
# 現在の設定を表示
stack config env

# パスを確認
stack path

# 使用中のGHCを確認
stack exec -- which ghc
stack exec -- ghc --version
```

---

### サーバーの再起動

```bash
# プロセスを探す
ps aux | grep medicus-api

# プロセスを終了（Windows）
taskkill /F /IM medicus-api.exe

# プロセスを終了（macOS/Linux）
pkill medicus-api

# 再起動
stack exec medicus-api
```

---

## 📊 パフォーマンスチェック

### メモリ使用量

```bash
# Windowsの場合
tasklist | findstr medicus-api

# Linux/macOSの場合
ps aux | grep medicus-api
top -p $(pgrep medicus-api)
```

---

### レスポンス時間

```bash
# curlでレスポンス時間を測定
time curl -X POST http://localhost:3000/graphql \
  -H "Content-Type: application/json" \
  -d '{"query": "{ health { status } }"}'
```

---

## 🔐 セキュリティチェック

### 本番環境設定の確認

```yaml
# config/settings-prod.yml

# ❌ 本番環境で有効にしてはいけない
graphql:
  playground-enabled: true

cors:
  origins:
    - "*"

logging:
  level: "DEBUG"

# ✅ 本番環境の正しい設定
graphql:
  playground-enabled: false

cors:
  origins:
    - "https://your-domain.com"

logging:
  level: "INFO"
```

---

## 📝 チェックリスト

### 開発環境のセットアップ確認

- [ ] Stack インストール済み（`stack --version`）
- [ ] GHC 使用可能（`ghc --version`）
- [ ] `stack build`成功
- [ ] `stack exec medicus-api`起動成功
- [ ] http://localhost:3000/health アクセス可能
- [ ] http://localhost:3000/playground アクセス可能

### デプロイ前の確認

- [ ] すべてのテストがパス（`stack test`）
- [ ] 本番環境設定の確認（`config/settings-prod.yml`）
- [ ] Playgroundが無効化されている
- [ ] CORS設定が適切
- [ ] ログレベルがINFO以上
- [ ] 最適化ビルド（`stack build`、`--fast`なし）

---

## 💡 予防策

### 1. 定期的なビルド

```bash
# CI/CDで自動ビルド
# または1日1回ビルドして問題を早期発見
```

### 2. 依存関係のロック

```bash
# stack.yaml.lockをgit管理
git add stack.yaml.lock
```

### 3. テストの充実

```haskell
-- すべての重要な機能にテストを追加
spec :: Spec
spec = describe "GraphQL" $ do
    it "resolves health query" $ ...
```

### 4. ドキュメントの更新

新しい問題に遭遇したら、このドキュメントに追加：

```markdown
### 新しい問題

**症状:**
...

**解決策:**
...
```

---

## 📚 さらに詳しく

- [07-build-issues.md](./07-build-issues.md) - ビルド問題の詳細な解決プロセス
- [03-graphql-integration.md](./03-graphql-integration.md) - GraphQL統合の詳細
- [04-yesod-graphql.md](./04-yesod-graphql.md) - Yesod統合の詳細

---

## ⚡ 緊急時の対応

### サーバーがクラッシュする

1. **ログを確認**
   ```bash
   tail -n 100 server.log
   ```

2. **スタックトレース**
   ```bash
   stack exec medicus-api -- +RTS -xc
   ```

3. **デバッグビルドで再実行**
   ```bash
   stack build --profile
   stack exec medicus-api
   ```

### データが壊れている疑い

```bash
# 一時データをクリア（将来DBを使用する場合）
rm -rf data/

# キャッシュをクリア
stack clean --full
```

### 完全なリセット

```bash
# すべてをリセット
rm -rf .stack-work/
stack purge
stack build
```

**⚠️ 注意:** 再ビルドに30-60分かかります。

---

## 問題が解決しない場合

1. [07-build-issues.md](./07-build-issues.md)を詳しく読む
2. Stackの詳細ログを取得（`--verbose`）
3. GHCiで型を確認
4. 最小限の再現例を作成
5. コミュニティに質問（Stack Overflow、Discourseなど）

---

**最終更新:** 2026-03-07  
**次回レビュー:** 新しい問題が発生したら随時更新
