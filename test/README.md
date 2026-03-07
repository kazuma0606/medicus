# MEDICUS Engine Test Suite

## 概要

MEDICUS空間理論の数学的性質を検証するためのプロパティベーステストスイート。

## テスト構成

### Test.MEDICUS.Generators

QuickCheckのためのジェネレーター：

- `genDimension` - 有効な次元（1-10）
- `genSmallDimension` - テスト用小次元（1-5）
- `genDomainBounds` - ドメイン境界の生成
- `genDomainInBounds` - 境界内のドメインポイント生成
- `genNormWeights` - 正値ノルム重みの生成
- `genSimpleMedicusSpace` - 簡易MEDICUS空間の生成
- `genConstantFunction` - 定数関数
- `genLinearFunction` - 線形関数
- `genQuadraticFunction` - 二次関数

### Test.MEDICUS.Properties

数学的性質の検証：

#### Property 1: MEDICUS空間構築

*任意のパラメータ領域Ωと制約集合Cに対して、システムは有効なMEDICUS関数空間M(Ω,C)を構築する*

検証項目：
- ✅ 次元の保存
- ✅ ドメイン境界の保存
- ✅ ノルム重みの保存
- ✅ 許容誤差の保存
- ✅ 制約の保存
- ✅ デフォルト空間の検証

**要件: 1.1**

#### Property 2: 空間所属判定

*任意の関数fに対して、所属判定は制約満足度とノルム有限性を正しく検証する*

検証項目：
- ✅ 定数関数の所属
- ✅ 線形関数の所属
- ✅ 二次関数の所属

**要件: 1.2**

#### Property 3: 線形空間操作

*任意の関数f₁, f₂とスカラーαに対して、演算f₁ + f₂とα·f₁はMEDICUS空間内に留まる*

検証項目：
- ✅ 関数加算の可換性
- ✅ スカラー倍の分配性
- ✅ ゼロスカラーでゼロ関数
- ✅ 単位スカラーで関数保存
- ✅ 和が空間内
- ✅ スカラー倍が空間内

**要件: 1.3**

#### 基本的な数学的性質

- ✅ 完備性検証
- ✅ 連続埋め込み検証
- ✅ 密性検証
- ✅ ノルムの非負性
- ✅ 距離の対称性
- ✅ 自己距離ゼロ

### Test.MEDICUS.Space

空間操作の単体テスト：

- 単体テスト
  - デフォルト空間作成
  - デフォルトノルム重み
  - 関数評価

- プロパティテスト
  - 次元の正値性
  - 境界の保存

- ヘルパー関数テスト
  - `domainZero`
  - `domainFromList`
  - `domainDimension`
  - `inDomainBounds`

### Test.MEDICUS.Norm

ノルム計算のテスト（プレースホルダー）

### Test.MEDICUS.Constraints

医療制約のテスト

## テスト実行

```bash
# ライブラリのビルド（常に成功）
cabal build lib:medicus-engine

# テストの実行（Windows環境では依存関係の問題あり）
cabal test

# 個別モジュールのテスト
cabal repl test:medicus-engine-test
```

## Windows環境での制限

現在、Windows環境ではtastyテストフレームワークの依存関係（`time`パッケージ）に問題があります。
ライブラリ自体は完全に動作し、テストコードもコンパイル可能です。

代替案：
1. WSL/Linux環境でテスト実行
2. より軽量なテストフレームワークへの移行
3. ghciでのインタラクティブテスト

## プロパティベーステストの利点

1. **網羅性**: QuickCheckが自動的に多様なテストケースを生成
2. **数学的厳密性**: 性質を直接検証
3. **リグレッション検出**: コード変更時の問題を即座に発見
4. **ドキュメント**: テストが仕様となる

## 今後の拡張

- [ ] Constraint満足度の詳細テスト
- [ ] ノルム計算の精度テスト
- [ ] 収束性の数値検証
- [ ] パフォーマンステスト
