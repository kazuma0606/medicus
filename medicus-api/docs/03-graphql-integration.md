# morpheus-graphql統合ガイド

Morpheus GraphQLをYesodアプリケーションに統合する方法を説明します。

## morpheus-graphqlとは

Morpheus GraphQLは、Haskellの型システムを活用したtype-safeなGraphQLライブラリです。

### 主な特徴

- **Type-safe:** HaskellのGeneric derivingでGraphQLスキーマを自動生成
- **Introspection:** GraphQL Introspectionを自動でサポート
- **Validation:** コンパイル時に型チェック
- **Performance:** Haskellのパフォーマンス特性を活用

## 依存関係の設定

### stack.yaml

```yaml
resolver: nightly-2024-03-10  # GHC 9.8対応

packages:
  - .

# morpheus-graphql 0.28.4とその依存関係
extra-deps:
  - morpheus-graphql-0.28.4@sha256:...
  - morpheus-graphql-app-0.28.4@sha256:...
  - morpheus-graphql-code-gen-0.28.4@sha256:...
  - morpheus-graphql-core-0.28.4@sha256:...
  - morpheus-graphql-server-0.28.4@sha256:...
  - morpheus-graphql-client-0.28.4@sha256:...
  - morpheus-graphql-code-gen-utils-0.28.4@sha256:...
  - morpheus-graphql-subscriptions-0.28.4@sha256:...

system-ghc: true
install-ghc: false
skip-ghc-check: true
```

**⚠️ 重要:** morpheus-graphqlは依存関係が多いため、すべて明示的に指定する必要があります。

### medicus-api.cabal

```cabal
library
  build-depends:
      base                  >= 4.7 && < 5
    , morpheus-graphql      >= 0.28 && < 0.29
    , morpheus-graphql-app  >= 0.28 && < 0.29
    , aeson                 >= 2.0
    , text                  >= 1.2
    , bytestring            >= 0.10
```

## GraphQL型の定義

### 基本的なパターン

Morpheus GraphQLでは、Haskellのデータ型からGraphQLスキーマを自動生成します。

```haskell
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

import Data.Morpheus.Types (GQLType)
import GHC.Generics (Generic)

-- GraphQL型として公開される
data User = User
    { userId :: Int
    , userName :: Text
    , userEmail :: Maybe Text  -- Nullable field
    } deriving (Generic, GQLType)
```

### Input型

```haskell
data CreateUserInput = CreateUserInput
    { name :: Text
    , email :: Maybe Text
    } deriving (Generic)

-- 引数として使用
createUser :: CreateUserInput -> m User
```

### Query/Mutation型

```haskell
-- Query root type
data Query m = Query
    { user :: UserArgs -> m User
    , users :: m [User]
    } deriving (Generic, GQLType)

-- Mutation root type  
data Mutation m = Mutation
    { createUser :: CreateUserInput -> m User
    , deleteUser :: DeleteUserArgs -> m Bool
    } deriving (Generic, GQLType)
```

## Resolverの実装

### 基本的なResolver

Morpheus GraphQL 0.28では、`Resolver`モナド変換子を使用します。

```haskell
import Data.Morpheus.Types (RootResolver(..), Undefined(..), lift)

-- Root resolver
rootResolver :: RootResolver IO () Query Mutation Undefined
rootResolver = RootResolver
    { queryResolver = Query
        { user = \args -> lift $ resolveUser args
        , users = lift resolveUsers
        }
    , mutationResolver = Mutation
        { createUser = \input -> lift $ resolveCreateUser input
        , deleteUser = \args -> lift $ resolveDeleteUser args
        }
    , subscriptionResolver = undefined  -- Subscriptions未使用
    }
```

### 重要なポイント

1. **`lift`の使用:** IO actionを`Resolver`モナドにリフトする必要があります
   ```haskell
   resolveUser :: UserArgs -> IO User
   resolveUser args = do
       -- 実際の処理
       return user
   
   -- Resolver内で使用する場合
   user = \args -> lift $ resolveUser args
   ```

2. **引数の扱い:** 引数はラムダ関数で受け取ります
   ```haskell
   -- ❌ 間違い
   user = resolveUser
   
   -- ✅ 正しい
   user = \args -> lift $ resolveUser args
   ```

3. **Subscriptionsの扱い:** 使用しない場合は`undefined`
   ```haskell
   subscriptionResolver = undefined
   ```

## インタープリターの設定

### GraphQLハンドラ

```haskell
import Data.Morpheus (interpreter)
import qualified Data.ByteString.Lazy as LBS

postGraphQLR :: Handler Value
postGraphQLR = do
    -- リクエストボディの取得
    bodyChunks <- rawRequestBody $$ CL.consume
    let body = LBS.fromChunks bodyChunks
    
    -- GraphQLクエリの実行
    result <- liftIO $ interpreter rootResolver body
    
    -- 結果のパース
    case A.eitherDecode result of
        Left err -> sendResponseStatus status400 $ object
            [ "errors" .= [object ["message" .= err]]
            ]
        Right value -> return value
```

## 型システムの注意点

### Resolver型の理解

```haskell
-- Query mのmは Resolver モナド変換子を期待している
data Query m = Query
    { validateSpace :: ValidateSpaceArgs -> m ValidationResult
    --                                       ^
    --                                       これは Resolver QUERY () IO
    }
```

実際の型は：
```haskell
type ResolverQ e ctx = Resolver QUERY e ctx
type ResolverM e ctx = Resolver MUTATION e ctx

-- したがって
validateSpace :: ValidateSpaceArgs -> Resolver QUERY () IO ValidationResult
```

### liftの必要性

```haskell
-- IO actionをResolverにリフト
resolveHealth :: IO HealthStatus
resolveHealth = do
    now <- getCurrentTime
    return $ HealthStatus "healthy" "medicus-api" "0.1.0" now

-- Resolver内で使用
health = lift resolveHealth
-- または
health = lift $ resolveHealth
```

## デバッグとテスト

### Introspectionクエリ

GraphQLスキーマを確認：

```graphql
query IntrospectionQuery {
  __schema {
    types {
      name
      kind
      description
    }
  }
}
```

### 型定義の確認

```graphql
query {
  __type(name: "Query") {
    name
    fields {
      name
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
```

## よくある問題

### 1. "Couldn't match type 'IO' with 'Resolver QUERY () IO'"

**原因:** IOアクションを直接使用している

**解決策:** `lift`を使用
```haskell
-- ❌ 
health = resolveHealth

-- ✅
health = lift resolveHealth
```

### 2. "Undefined Field"エラー

**原因:** GraphQLのフィールド名とHaskellのレコードフィールド名が一致していない

**解決策:** フィールド名を確認
```haskell
-- GraphQLでは "userName" だが Haskellでは "name" になっている
data User = User
    { name :: Text  -- ❌ GraphQLでは "name"
    }

data User = User
    { userName :: Text  -- ✅ GraphQLでも "userName"
    }
```

### 3. "No instance for GQLType"

**原因:** `Generic`または`GQLType`のderivingが不足

**解決策:** 
```haskell
{-# LANGUAGE DeriveGeneric #-}
{-# LANGUAGE DeriveAnyClass #-}

data MyType = MyType { field :: Text }
    deriving (Generic, GQLType)  -- 両方必要
```

## 参考リンク

- [Morpheus GraphQL 公式サイト](https://morpheusgraphql.com/)
- [Morpheus GraphQL GitHub](https://github.com/morpheusgraphql/morpheus-graphql)
- [Hackage: morpheus-graphql](https://hackage.haskell.org/package/morpheus-graphql)

## 次のステップ

- [04-yesod-graphql.md](./04-yesod-graphql.md) - YesodとGraphQLの統合
- [05-graphql-playground.md](./05-graphql-playground.md) - Playgroundの使い方
- [06-troubleshooting.md](./06-troubleshooting.md) - トラブルシューティング
