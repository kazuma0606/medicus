# MEDICUS API Documentation

MEDICUS APIの技術ドキュメント集です。

## 📚 ドキュメント一覧

### 導入・セットアップ
- [01-setup.md](./01-setup.md) - 環境構築とプロジェクトセットアップ
- [02-build-system.md](./02-build-system.md) - ビルドシステム（Stack/Cabal）の設定

### GraphQL統合
- [03-graphql-integration.md](./03-graphql-integration.md) - morpheus-graphqlの統合方法
- [04-yesod-graphql.md](./04-yesod-graphql.md) - YesodとGraphQLの統合
- [05-graphql-playground.md](./05-graphql-playground.md) - GraphQL Playgroundのセットアップと使い方

### トラブルシューティング
- [06-troubleshooting.md](./06-troubleshooting.md) - よくある問題と解決方法
- [07-build-issues.md](./07-build-issues.md) - ビルド問題の詳細と解決プロセス

### API仕様
- [08-api-reference.md](./08-api-reference.md) - API リファレンス
- [09-graphql-schema.md](./09-graphql-schema.md) - GraphQLスキーマ詳細

## 🚀 クイックスタート

```bash
# 1. リポジトリのクローン
cd medicus-api

# 2. ビルド
stack build

# 3. サーバー起動
stack exec medicus-api

# 4. GraphQL Playground にアクセス
# http://localhost:3000/playground
```

## 📖 推奨読書順序

### 初めての方
1. [01-setup.md](./01-setup.md) - 環境構築
2. [03-graphql-integration.md](./03-graphql-integration.md) - GraphQL基礎
3. [05-graphql-playground.md](./05-graphql-playground.md) - 動作確認

### トラブルに遭遇した方
1. [06-troubleshooting.md](./06-troubleshooting.md) - よくある問題
2. [07-build-issues.md](./07-build-issues.md) - ビルド問題の詳細

### 開発者
1. [04-yesod-graphql.md](./04-yesod-graphql.md) - 統合の詳細
2. [08-api-reference.md](./08-api-reference.md) - API仕様
3. [09-graphql-schema.md](./09-graphql-schema.md) - スキーマ設計

## 🔗 関連リンク

- [Morpheus GraphQL 公式サイト](https://morpheusgraphql.com/)
- [Yesod Web Framework](https://www.yesodweb.com/)
- [Stack Documentation](https://docs.haskellstack.org/)

## 📝 ドキュメント作成日

- 初版: 2026-03-07
- 最終更新: 2026-03-07
