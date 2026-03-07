# YesodとGraphQLの統合ガイド

YesodウェブフレームワークとMorpheus GraphQLの統合方法を説明します。

## アーキテクチャ概要

```
Browser/Client
    ↓ HTTP POST
Yesod Handler (postGraphQLR)
    ↓ ByteString
Morpheus Interpreter (interpreter rootResolver)
    ↓ Execute
GraphQL Resolvers
    ↓ IO actions
Business Logic / Database
```

## Foundation の設定

### App型の定義

```haskell
{-# LANGUAGE TypeFamilies #-}

import Yesod.Core
import System.Log.FastLogger (LoggerSet)
import Settings

data App = App
    { appSettings :: AppSettings
    , appLogger :: LoggerSet
    }
```

**重要なポイント:**
- `appLogger`は`LoggerSet`型（`Logger`ではない）
- 最小限の構成で始める

### ルート定義

`config/routes.txt`:

```
-- GraphQL endpoint
/graphql GraphQLR POST

-- GraphQL Playground
/playground PlaygroundR GET

-- Health check
/health HealthR GET
```

### mkYesod の使用

```haskell
-- Foundation.hs
mkYesodData "App" $(parseRoutesFile "config/routes.txt")

instance Yesod App where
    approot = ApprootRequest $ \app req ->
        case appRoot (appSettings app) of
            Nothing -> getApprootText guessApproot app req
            Just root -> root
    
    defaultLayout widget = do
        pc <- widgetToPageContent widget
        withUrlRenderer [hamlet|
            $doctype 5
            <html>
                <head>
                    <title>#{pageTitle pc}
                    ^{pageHead pc}
                <body>
                    ^{pageBody pc}
        |]
    
    errorHandler NotFound = selectRep $ do
        provideRep $ return $ object
            [ "error" .= ("Not Found" :: Text)
            , "status" .= (404 :: Int)
            ]
        provideRep $ return $ toHtml ("Not Found" :: Text)
    
    errorHandler (BadMethod method) = selectRep $ do
        provideRep $ return $ object
            [ "error" .= ("Method Not Allowed" :: Text)
            , "method" .= decodeUtf8 method
            , "status" .= (405 :: Int)
            ]
        provideRep $ return $ toHtml ("Method not allowed: " <> decodeUtf8 method :: Text)
```

### mkYesodDispatch の使用

```haskell
-- Application.hs
import Foundation
import Handler.Health
import Handler.GraphQL
import Handler.Playground

-- ルート処理の生成
mkYesodDispatch "App" resourcesApp
```

**注意:** 循環インポートを避けるため、`mkYesodData`と`mkYesodDispatch`を分離します。

## GraphQLハンドラの実装

### POSTハンドラ

```haskell
{-# LANGUAGE OverloadedStrings #-}

module Handler.GraphQL (postGraphQLR) where

import Import
import Data.Morpheus (interpreter)
import qualified Data.ByteString.Lazy as LBS
import qualified Data.Aeson as A
import Data.Conduit (($$))
import qualified Data.Conduit.List as CL
import GraphQL.Resolvers (rootResolver)

postGraphQLR :: Handler Value
postGraphQLR = do
    -- CORS対応
    app <- getYesod
    let cors = appCORS (appSettings app)
    when (corsEnabled cors) $ do
        addHeader "Access-Control-Allow-Origin" "*"
        addHeader "Access-Control-Allow-Methods" "GET, POST, OPTIONS"
        addHeader "Access-Control-Allow-Headers" "Content-Type"
    
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

### 重要なポイント

1. **rawRequestBodyの取得**
   ```haskell
   -- ❌ 間違い（型が合わない）
   body <- fmap LBS.fromStrict rawRequestBody
   
   -- ✅ 正しい（Conduitを使用）
   bodyChunks <- rawRequestBody $$ CL.consume
   let body = LBS.fromChunks bodyChunks
   ```

2. **interpreterの使用**
   ```haskell
   -- interpreterはByteString -> IO ByteStringの関数
   result <- liftIO $ interpreter rootResolver body
   ```

3. **CORS対応**
   ```haskell
   addHeader "Access-Control-Allow-Origin" "*"
   ```

## Application初期化

### makeFoundation

```haskell
import Yesod.Core
import System.Log.FastLogger
    ( defaultBufSize
    , newStdoutLoggerSet
    , LoggerSet
    )

makeFoundation :: AppSettings -> IO App
makeFoundation settings = do
    -- ロガーの作成
    loggerSet <- newStdoutLoggerSet defaultBufSize
    
    return App
        { appSettings = settings
        , appLogger = loggerSet
        }
```

**注意:** `LoggerSet`を直接使用します（`Logger`型ではない）。

### makeApplication

```haskell
import Network.Wai (Middleware, Application)

-- YesodDispatchの生成（上で定義）
mkYesodDispatch "App" resourcesApp

makeApplication :: App -> IO Application
makeApplication foundation = do
    logWare <- makeLogWare foundation
    appPlain <- toWaiAppPlain foundation
    return $ logWare $ appPlain
```

## Logger の統合

### Fast-loggerとYesod

```haskell
import System.Log.FastLogger (LoggerSet, newStdoutLoggerSet, defaultBufSize)
import Network.Wai.Middleware.RequestLogger (mkRequestLogger, def)

makeLogWare :: App -> IO Middleware
makeLogWare _foundation = do
    mkRequestLogger def
        { outputFormat = Apache FromFallback
        , destination = Callback (\logStr -> putStrLn $ show logStr)
        }
```

## Conduitとの統合

YesodはConduitを使用してストリーミング処理を行います。

### 必要な依存関係

```cabal
build-depends:
    , conduit >= 1.3
```

### rawRequestBodyの消費

```haskell
import Data.Conduit (($$))
import qualified Data.Conduit.List as CL

getBody :: Handler LBS.ByteString
getBody = do
    chunks <- rawRequestBody $$ CL.consume
    return $ LBS.fromChunks chunks
```

## CORS対応

### 設定

`config/settings.yml`:

```yaml
cors:
  enabled: true
  origins:
    - "*"
  max-age: 86400
```

### ハンドラでの実装

```haskell
-- CORS ヘッダーの追加
addHeader "Access-Control-Allow-Origin" "*"
addHeader "Access-Control-Allow-Methods" "GET, POST, OPTIONS"
addHeader "Access-Control-Allow-Headers" "Content-Type"
```

### OPTIONSリクエストの対応

```haskell
-- config/routes.txt に追加
/graphql GraphQLR POST OPTIONS
```

```haskell
-- Handler/GraphQL.hs
optionsGraphQLR :: Handler ()
optionsGraphQLR = do
    addHeader "Access-Control-Allow-Origin" "*"
    addHeader "Access-Control-Allow-Methods" "GET, POST, OPTIONS"
    addHeader "Access-Control-Allow-Headers" "Content-Type"
    return ()
```

## エラーハンドリング

### Yesodのエラーハンドラ

```haskell
instance Yesod App where
    errorHandler NotFound = selectRep $ do
        -- JSON レスポンス
        provideRep $ return $ object
            [ "error" .= ("Not Found" :: Text)
            , "status" .= (404 :: Int)
            ]
        -- HTML レスポンス
        provideRep $ return $ toHtml ("Not Found" :: Text)
    
    errorHandler (BadMethod method) = selectRep $ do
        provideRep $ return $ object
            [ "error" .= ("Method Not Allowed" :: Text)
            , "method" .= decodeUtf8 method  -- ByteString -> Text変換
            , "status" .= (405 :: Int)
            ]
        provideRep $ return $ toHtml ("Method not allowed: " <> decodeUtf8 method :: Text)
```

### GraphQLエラーの処理

```haskell
case A.eitherDecode result of
    Left err -> do
        $logError $ "GraphQL error: " <> T.pack err
        sendResponseStatus status500 $ object
            [ "errors" .= [object
                [ "message" .= err
                , "extensions" .= object ["code" .= ("INTERNAL_ERROR" :: Text)]
                ]
              ]
            ]
    Right value -> return value
```

## テスト

### Yesodのテストヘルパー

```haskell
{-# LANGUAGE OverloadedStrings #-}

import Test.Hspec
import Yesod.Test

spec :: Spec
spec = withApp $ do
    describe "GraphQL endpoint" $ do
        it "responds to health query" $ do
            request $ do
                setMethod "POST"
                setUrl GraphQLR
                setRequestBody "{\"query\": \"{ health { status } }\"}"
            
            statusIs 200
```

## パフォーマンス最適化

### 並列処理

```haskell
import Control.Concurrent.Async (mapConcurrently)

optimizeBatch :: BatchOptimizationArgs -> IO [OptimizationResult]
optimizeBatch args = do
    -- 並列実行
    results <- mapConcurrently optimize (inputs args)
    return results
```

### キャッシング（将来の拡張）

```haskell
-- Data.Cacheなどを使用
import Data.Cache (Cache, newCache, insert, lookup)
```

## 本番環境への展開

### 設定の切り替え

```bash
# 本番環境設定を使用
YESOD_ENV=production stack exec medicus-api
```

`config/settings-prod.yml`:

```yaml
port: 8080
host: "0.0.0.0"
approot: "https://api.medicus.example.com"

graphql:
  playground-enabled: false  # 本番では無効化

cors:
  enabled: true
  origins:
    - "https://app.medicus.example.com"  # 特定のオリジンのみ

logging:
  level: "INFO"  # DEBUGは本番では使わない
```

### Dockerイメージ（将来）

```dockerfile
FROM haskell:9.8.2
WORKDIR /app
COPY . .
RUN stack build --copy-bins
CMD ["medicus-api"]
```

## 次のステップ

- [05-graphql-playground.md](./05-graphql-playground.md) - Playgroundの使い方
- [06-troubleshooting.md](./06-troubleshooting.md) - トラブルシューティング
- [08-api-reference.md](./08-api-reference.md) - API仕様
