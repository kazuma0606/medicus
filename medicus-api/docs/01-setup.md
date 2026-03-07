# セットアップガイド

MEDICUS APIの環境構築手順です。

## 前提条件

### 必須ツール

| ツール | バージョン | 確認コマンド |
|---|---|---|
| Stack | 3.9.1以降 | `stack --version` |
| GHC | 9.8.2 | `ghc --version` |
| Cabal | 3.10.2以降 | `cabal --version` |

### 推奨環境

- OS: Windows 10/11, macOS, Linux
- メモリ: 8GB以上（ビルド時）
- ディスク空き容量: 5GB以上

## インストール手順

### 1. Stackのインストール

#### Windows (PowerShell)
```powershell
# Chocolateyを使用
choco install haskell-stack

# または公式インストーラー
# https://docs.haskellstack.org/en/stable/install_and_upgrade/
```

#### macOS
```bash
brew install haskell-stack
```

#### Linux
```bash
curl -sSL https://get.haskellstack.org/ | sh
```

### 2. プロジェクトのセットアップ

```bash
cd medicus-api

# GHCのインストール（初回のみ、system-ghc: trueの場合は不要）
stack setup

# 依存関係の更新
stack update
```

### 3. ビルド

```bash
# 開発ビルド（高速）
stack build --fast

# 本番ビルド（最適化有効）
stack build
```

**⚠️ 初回ビルドには時間がかかります（30分〜1時間程度）**

- morpheus-graphql関連パッケージ
- Yesod関連パッケージ
- その他144個以上の依存パッケージ

### 4. 設定ファイルの準備

```bash
# .env.exampleをコピー
cp .env.example .env

# 必要に応じて編集
# PORT, HOST, LOG_LEVELなど
```

### 5. サーバーの起動

```bash
# 開発モード
stack exec medicus-api

# 環境変数を指定
YESOD_ENV=development stack exec medicus-api
```

### 6. 動作確認

ブラウザで以下のURLにアクセス：

- **ヘルスチェック:** http://localhost:3000/health
- **GraphQL Playground:** http://localhost:3000/playground

## トラブルシューティング

### ビルドエラーが発生する場合

```bash
# キャッシュをクリア
stack clean
stack purge

# 再ビルド
stack build
```

詳細は [07-build-issues.md](./07-build-issues.md) を参照してください。

### GHCのバージョン問題

`stack.yaml`で`system-ghc: true`を使用している場合：

```bash
# システムにインストールされているGHCのバージョン確認
ghc --version

# stack.yamlで指定されているresolverと互換性があるか確認
stack exec -- ghc --version
```

### ポートが既に使用されている場合

```bash
# Windowsの場合
netstat -ano | findstr :3000

# macOS/Linuxの場合
lsof -i :3000

# config/settings.ymlでポート番号を変更
# port: 3001
```

## 次のステップ

環境構築が完了したら：

1. [03-graphql-integration.md](./03-graphql-integration.md) - GraphQLの基礎を学ぶ
2. [05-graphql-playground.md](./05-graphql-playground.md) - Playgroundで動作確認
3. [08-api-reference.md](./08-api-reference.md) - APIの使い方を学ぶ

## 参考情報

### ディレクトリ構造

```
medicus-api/
├── app/                    # 実行可能ファイル
│   └── Main.hs
├── src/                    # ライブラリソース
│   ├── Application.hs      # アプリケーション初期化
│   ├── Foundation.hs       # Yesod Foundation
│   ├── Settings.hs         # 設定管理
│   ├── GraphQL/           # GraphQL関連
│   └── Handler/           # ルートハンドラ
├── config/                # 設定ファイル
│   ├── settings.yml       # 開発環境設定
│   └── routes.txt         # ルート定義
├── test/                  # テスト
├── stack.yaml            # Stack設定
└── medicus-api.cabal     # パッケージ定義
```

### 重要なファイル

- `stack.yaml` - Stackビルド設定、resolverとextra-deps
- `medicus-api.cabal` - パッケージメタデータと依存関係
- `config/settings.yml` - アプリケーション設定
- `config/routes.txt` - Yesodルート定義
