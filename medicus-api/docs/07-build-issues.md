# ビルド問題の詳細と解決プロセス

MEDICUS API開発中に遭遇したビルド問題と、その解決プロセスを詳細に記録します。

## 概要

**開発日:** 2026-03-07  
**解決に要した時間:** 約2時間  
**解決した問題数:** 10+個の型エラー、依存関係エラー

## 問題1: Cabal 3.10.3.0の互換性問題

### エラーメッセージ

```
Error:
    Problem with module re-exports:
      - The module 'Distribution.Compat.Typeable'
        is not exported by any suitable package.
    In the stanza 'library'
    In the package 'Cabal-3.10.3.0'
```

### 原因

Cabal 3.10.3.0自体にバグがあり、内部モジュールの再エクスポートが壊れている。

### 試行した解決策（失敗）

1. **cabal.projectでの制約追加**
   ```cabal
   constraints: Cabal < 3.10
   ```
   → 依存関係の競合で解決できず

2. **allow-newerの調整**
   ```cabal
   allow-newer: all
   ```
   → 効果なし

### 最終的な解決策

**Cabalを諦めてStackに切り替え**

理由：
- Stackは独自のパッケージスナップショットを使用
- Cabal 3.10.3.0の問題を回避できる
- 依存関係の再現性が高い

## 問題2: morpheus-graphqlの依存関係

### エラーメッセージ

```
Error: [S-4804]
       Stack failed to construct a build plan.
       
       In the dependencies for medicus-api-0.1.0.0:
         * morpheus-graphql must match >=0.27, but no version is in the Stack configuration
```

### 原因

morpheus-graphql 0.28.4がスナップショットに含まれていない。

### 解決プロセス

#### ステップ1: 基本パッケージの追加

```yaml
extra-deps:
  - morpheus-graphql-0.28.4@sha256:...,17792
  - morpheus-graphql-app-0.28.4@sha256:...,9201
```

→ 次のエラー

#### ステップ2: 追加の依存関係

```
Error: morpheus-graphql-core must match >=0.28.0 && <0.29.0
```

追加：
```yaml
  - morpheus-graphql-core-0.28.4@sha256:...,14208
  - morpheus-graphql-server-0.28.4@sha256:...,24589
  - morpheus-graphql-code-gen-0.28.4@sha256:...,2757
```

#### ステップ3: さらなる依存関係

```
Error: morpheus-graphql-client must match >=0.28.0 && <0.29.0
```

追加：
```yaml
  - morpheus-graphql-client-0.28.4@sha256:...,5334
  - morpheus-graphql-code-gen-utils-0.28.4@sha256:...,1570
  - morpheus-graphql-subscriptions-0.28.4@sha256:...,1783
```

### 最終的な設定

```yaml
# stack.yaml
extra-deps:
  - morpheus-graphql-0.28.4@sha256:03904ba010ed9d0d83ff7ff1a266b2b483cdb69521a63b75aa1d8855c84abfb2,17792
  - morpheus-graphql-app-0.28.4@sha256:d5896b9b74ffdca8ab58ffd12a93b9de3f3ab2aae193ad9e1ec39743a87b8ef8,9201
  - morpheus-graphql-code-gen-0.28.4@sha256:0d8b2a64794fa57595e1f771475178c0594bc82ed34211ed437bfabe82198bb7,2757
  - morpheus-graphql-core-0.28.4@sha256:7ee1d1cc3e35d3c286a48023d85ada0e980bc4d78653f582deab3eb0fc2b8561,14208
  - morpheus-graphql-server-0.28.4@sha256:449dc664f08d8a7c09e2b4f10332512d4252ca9ac072d9d9e3e60a700f08d17d,24589
  - morpheus-graphql-client-0.28.4@sha256:60115e026b4c291cd35db9124922caeded5803d9b4e58a8e5dd4b6f23a9fc242,5334
  - morpheus-graphql-code-gen-utils-0.28.4@sha256:a9fe54791958a40c2956bff431fea189ef4acdb35632f8338a29eae87b8aaf8b,1570
  - morpheus-graphql-subscriptions-0.28.4@sha256:9d60a54d9a1889cc39dee59ab825536576594a90333ab1fddebfabf39e0455df,1783
```

## 問題3: GHCディスク容量エラー

### エラーメッセージ

```
Error: [S-2905]
       Problem while decompressing
       C:\...\ghc-9.6.4.tar.xz
       
ERROR: Cannot set length for output file : ディスクに十分な空き領域がありません
```

### 原因

Stack が新しいGHCをダウンロードしようとしたが、ディスク容量不足。

### 解決策

システムにインストール済みのGHC 9.8.2を使用：

```yaml
# stack.yaml
system-ghc: true
install-ghc: false
skip-ghc-check: true
```

## 問題4: 型エラー - Resolver型の不一致

### エラーメッセージ

```
Couldn't match type 'IO'
                 with 'Resolver QUERY () IO'
  Expected: Query (Resolver QUERY () IO)
    Actual: Query IO
```

### 原因

`Query m`の`m`は`Resolver`モナド変換子を期待しているが、単なる`IO`を渡していた。

### 試行1: `return`でラップ（失敗）

```haskell
rootResolver = RootResolver
    { queryResolver = return Query {...}  -- ❌
    }
```

エラー: 型が一致しない

### 試行2: カスタム型の定義（失敗）

```haskell
data EmptySubscription (m :: * -> *) = EmptySubscription
```

エラー: kindが一致しない

### 最終的な解決策: `lift`の使用

```haskell
import Data.Morpheus.Types (lift)

rootResolver = RootResolver
    { queryResolver = Query
        { validateSpace = \args -> lift $ resolveValidateSpace args
        , listAvailableConstraints = lift resolveListConstraints
        , health = lift resolveHealth
        }
    , mutationResolver = Mutation {...}
    , subscriptionResolver = undefined
    }
```

**キーポイント:**
- IO actionを`lift`で`Resolver`モナドにリフト
- 引数はラムダ関数で受け取る
- Subscriptionsは`undefined`でOK

## 問題5: Logger型の不一致

### エラーメッセージ

```
Couldn't match expected type 'Logger'
              with actual type 'LoggerSet'
```

### 試行錯誤

#### 試行1: `makeYesodLogger`の使用（失敗）

```haskell
logger <- newStdoutLoggerSet defaultBufSize >>= makeYesodLogger
```

エラー: `makeYesodLogger`は`Yesod.Core.Types`に存在しない

#### 試行2: `Logger`コンストラクタの使用（失敗）

```haskell
let logger = Logger loggerSet
```

エラー: `Logger`はnewtypeで、異なる型を期待

#### 試行3: `pushLogStrLn`の使用（失敗）

```haskell
let logger = pushLogStrLn loggerSet
```

エラー: 型が`LogStr -> IO ()`になり、`Logger`と不一致

### 最終的な解決策: LoggerSetを直接使用

```haskell
-- Foundation.hs
data App = App
    { appSettings :: AppSettings
    , appLogger :: LoggerSet  -- Logger型ではなくLoggerSet
    }

-- Application.hs
makeFoundation :: AppSettings -> IO App
makeFoundation settings = do
    loggerSet <- newStdoutLoggerSet defaultBufSize
    return App
        { appSettings = settings
        , appLogger = loggerSet  -- そのまま使用
        }
```

## 問題6: 循環インポート

### エラーメッセージ

```
Module graph contains a cycle:
      module 'Handler.Playground' (src\Handler\Playground.hs)
      imports module 'Import' (src\Import.hs)
which imports module 'Foundation' (src\Foundation.hs)
which imports module 'Handler.Playground' (src\Handler\Playground.hs)
```

### 原因

```
Foundation.hs → Handler.Playground.hs
     ↑                    ↓
     Import.hs ←──────────┘
```

### 解決策: mkYesodDataとmkYesodDispatchの分離

```haskell
-- Foundation.hs（型定義のみ）
mkYesodData "App" $(parseRoutesFile "config/routes.txt")

-- Application.hs（ディスパッチ）
import Handler.Health
import Handler.GraphQL
import Handler.Playground

mkYesodDispatch "App" resourcesApp
```

## 問題7: rawRequestBodyの使用

### エラーメッセージ

```
Couldn't match type: HandlerFor App StrictByteString
              with: ConduitT i0 ByteString m0 ()
```

### 原因

`rawRequestBody`はConduitを返すが、ByteStringとして扱おうとした。

### 解決策

```haskell
import Data.Conduit (($$))
import qualified Data.Conduit.List as CL
import qualified Data.ByteString.Lazy as LBS

postGraphQLR :: Handler Value
postGraphQLR = do
    -- Conduitを消費してByteStringに変換
    bodyChunks <- rawRequestBody $$ CL.consume
    let body = LBS.fromChunks bodyChunks
    
    result <- liftIO $ interpreter rootResolver body
    ...
```

## 問題8: 存在しないモジュールの参照

### エラーメッセージ

```
Error: Cabal-simple_*.exe: can't find source for GraphQL\Query\Space
```

### 原因

`.cabal`ファイルの`exposed-modules`に存在しないモジュールが記載されていた。

### 解決策

実際に存在するモジュールのみを記載：

```cabal
exposed-modules:
    Foundation
    Settings
    GraphQL.Schema
    GraphQL.Resolvers
    GraphQL.Types.Common
    -- GraphQL.Query.Space  ❌ 存在しない
    -- Service.Space        ❌ まだ実装していない
```

## 問題9: yesod-staticの依存問題

### エラーメッセージ

```
Error: While building package language-javascript-0.7.1.0:
       happy.exe: src\Language\JavaScript\Parser\Grammar7.y: 
       hGetContents: invalid argument (cannot decode byte sequence)
```

### 原因

`yesod-static`が依存する`language-javascript`のビルドが文字エンコーディング問題で失敗。

### 解決策

静的ファイル配信機能を一時的に無効化：

```haskell
-- Foundation.hs
-- import Yesod.Static (Static, static)  ❌ コメントアウト

data App = App
    { appSettings :: AppSettings
    , appLogger :: LoggerSet
    -- , appStatic :: Static  ❌ 削除
    }
```

```
# config/routes.txt
-- /static StaticR Static appStatic  ❌ コメントアウト
```

**注意:** 将来、静的ファイルが必要になったら再度有効化します。

## 問題10: Undefined型の使用

### エラーメッセージ

```
Illegal term-level use of the type constructor or class 'Undefined'
Perhaps use variable 'undefined' (imported from Prelude)
```

### 原因

`Undefined`は型コンストラクタだが、値として使おうとした。

### 解決策

```haskell
-- ❌ 間違い
subscriptionResolver = Undefined

-- ✅ 正しい
subscriptionResolver = undefined  -- 小文字のundefined
```

## 問題11: 文字エンコーディングエラー

### エラーメッセージ

```
<stderr>: commitAndReleaseBuffer: invalid argument (cannot encode character '\8226')
```

### 原因

PowerShellのデフォルトエンコーディングが日本語環境でShift-JISになっている。

### 解決策

UTF-8エンコーディングを明示的に設定：

```powershell
$OutputEncoding = [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8
stack build
```

または、ビルドスクリプトに追加：

```powershell
# build.ps1
$OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
[Console]::InputEncoding = [System.Text.Encoding]::UTF8

stack build --fast
```

## 問題12: 隠されたパッケージ

### エラーメッセージ

```
Could not load module 'Data.Conduit'.
It is a member of the hidden package 'conduit-1.3.5'.
Perhaps you need to add 'conduit' to the build-depends in your .cabal file.
```

### 原因

使用しているモジュールのパッケージが`build-depends`に記載されていない。

### 解決策

必要なパッケージを`.cabal`に追加：

```cabal
library
  build-depends:
      base
    , conduit          -- 追加
    , shakespeare      -- 追加
    , http-types       -- 追加
    , data-default     -- 追加
```

## 解決プロセスの全体像

### フェーズ1: 依存関係の解決（30分）

1. ✅ Stackのセットアップ
2. ✅ パッケージインデックスの更新（195,000+ cabalファイル）
3. ✅ morpheus-graphql依存関係の追加（8個）
4. ✅ 144個の依存パッケージのコンパイル

### フェーズ2: 型エラーの修正（60分）

1. ✅ Resolver型の理解とliftの使用
2. ✅ Logger型の正しい使用
3. ✅ Undefined vs undefinedの区別
4. ✅ rawRequestBodyのConduit処理
5. ✅ 循環インポートの解消

### フェーズ3: ビルドエラーの修正（30分）

1. ✅ 存在しないモジュールの削除
2. ✅ 隠されたパッケージの明示的追加
3. ✅ yesod-staticの無効化
4. ✅ 文字エンコーディングの修正
5. ✅ executableの依存関係追加

## 学んだ教訓

### 1. Stackを最初から使うべきだった

**理由:**
- Cabalの問題はシステム全体に影響する
- Stackは独立した環境を構築できる
- morpheus-graphqlのような複雑な依存関係に強い

### 2. extra-depsは段階的に追加

Stackがエラーメッセージで推奨してくれる形式をそのまま使用：

```yaml
# Stackが出力した推奨設定をコピペ
- morpheus-graphql-core-0.28.4@sha256:7ee1d...,14208
```

### 3. 型エラーは公式ドキュメントを参照

morpheus-graphqlの公式サイト（https://morpheusgraphql.com/）の例を見ることで、正しいパターンがわかった：

```haskell
-- 公式の例
rootResolver :: RootResolver IO () Query Undefined Undefined
rootResolver =
  RootResolver
    { queryResolver = Query {deity}
    , mutationResolver = Undefined
    , subscriptionResolver = Undefined
    }
  where
    deity DeityArgs {name} = pure Deity {...}
```

### 4. 最小構成から始める

一度にすべての機能を追加せず、段階的に：

1. ✅ 基本的なYesod Foundationのみ
2. ✅ GraphQL型定義のみ
3. ✅ スタブリゾルバ
4. ⬜ 実装リゾルバ（後で）

### 5. ログとエラーメッセージを注意深く読む

```
Error: [S-4804]
       ...
       Recommended action: try adding the following to your extra-deps:
       - package-name-version@sha256:hash,size
```

→ この推奨に従えば解決することが多い

## ベストプラクティス

### 1. ビルド前のチェックリスト

- [ ] `stack.yaml`のresolverが適切か
- [ ] `extra-deps`が完全か
- [ ] `.cabal`の`exposed-modules`が実際のファイルと一致しているか
- [ ] `build-depends`にすべての使用パッケージが含まれているか

### 2. エラーが出たら

1. **エラーメッセージを全文読む**（特に"Recommended action"）
2. **一つずつ修正する**（複数の問題を同時に修正しない）
3. **変更後に必ずビルド**
4. **成功したらgit commit**

### 3. ビルドキャッシュの管理

```bash
# 依存関係の問題の場合
stack clean

# 完全にクリーンアップ
stack purge

# 特定のパッケージのみ再ビルド
stack build --force-dirty medicus-api
```

### 4. ビルドログの保存

```bash
# ログファイルに保存
stack build --fast 2>&1 | tee build-$(date +%Y%m%d-%H%M%S).log
```

## デバッグテクニック

### 1. 詳細ログの有効化

```bash
stack build --verbose 2>&1 | tee verbose-build.log
```

### 2. 特定のモジュールのみコンパイル

```bash
# ライブラリのみ
stack build medicus-api:lib

# 実行可能ファイルのみ
stack build medicus-api:exe:medicus-api
```

### 3. GHCオプションの追加

```yaml
# stack.yaml
ghc-options:
  "$locals": 
    - -Wall              # すべての警告
    - -Wcompat           # 互換性警告
    - -fprint-expanded-synonyms  # 型シノニムを展開して表示
    - -fprint-explicit-kinds     # Kind を明示的に表示
```

### 4. 型ホールの使用

```haskell
-- 型がわからない場合
rootResolver = RootResolver
    { queryResolver = _  -- 型ホール
    , mutationResolver = _
    , subscriptionResolver = _
    }
```

GHCが期待される型を教えてくれます：

```
Found type wildcard '_' standing for
    'Query (Resolver QUERY () IO)'
```

## 再現性の確保

### stack.yaml.lockの使用

```bash
# 依存関係をロック
stack build

# stack.yaml.lockが生成される
git add stack.yaml.lock
git commit -m "Lock dependency versions"
```

### 環境情報の記録

```bash
# ビルド環境情報
stack exec -- ghc --version > build-env.txt
stack --version >> build-env.txt
cabal --version >> build-env.txt

# システム情報
uname -a >> build-env.txt  # Linux/macOS
systeminfo >> build-env.txt  # Windows
```

## チームでの作業

### 1. ビルド手順の共有

`BUILD.md`を作成：

```markdown
# ビルド手順

1. Stack インストール
2. `stack build`実行
3. 問題が発生したら`docs/07-build-issues.md`を参照
```

### 2. 既知の問題の文書化

このドキュメントのように、遭遇した問題を記録：

- 問題の症状
- エラーメッセージ
- 試行錯誤のプロセス
- 最終的な解決策

### 3. CI/CDでの自動化

```yaml
# .github/workflows/build.yml
name: Build
on: [push, pull_request]
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v2
      - uses: haskell/actions/setup@v2
        with:
          ghc-version: '9.8.2'
          enable-stack: true
      - run: stack build --test --no-run-tests
```

## まとめ

### 成功のカギ

1. ✅ **Stackを使用**（Cabalの問題を回避）
2. ✅ **公式ドキュメントを参照**（morpheus-graphql.com）
3. ✅ **段階的な実装**（最小構成から始める）
4. ✅ **エラーメッセージに従う**（Stackの推奨に従う）
5. ✅ **型システムを理解**（Resolver, lift, モナド変換子）

### 最終的な成果

- ✅ すべての依存関係の解決
- ✅ 型エラーの完全な解消
- ✅ ビルド成功（Exit code: 0）
- ✅ サーバー起動成功
- ✅ GraphQL Playground動作確認

**所要時間:** 約2時間  
**解決した問題:** 10+個

## 参考資料

- [Stack公式ドキュメント](https://docs.haskellstack.org/)
- [Morpheus GraphQL公式サイト](https://morpheusgraphql.com/)
- [Yesod Book](https://www.yesodweb.com/book)
- [GHC User's Guide](https://downloads.haskell.org/~ghc/latest/docs/html/users_guide/)

## 次のステップ

- [06-troubleshooting.md](./06-troubleshooting.md) - よくある問題のクイックリファレンス
- [03-graphql-integration.md](./03-graphql-integration.md) - GraphQL統合の詳細
- [04-yesod-graphql.md](./04-yesod-graphql.md) - Yesod統合の詳細
