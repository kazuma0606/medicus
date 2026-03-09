# MEDICUS — 医療介入の非可換性に基づく数学的ガバナンス基盤

**MEDICUS（Medical-Enhanced Data Integrity Constraint Unified Space）**は、
医療ドメインの実務知見と関数解析・代数学を統合した理論的フレームワークと、その実装ライブラリです。

---

## 核心的な問い

> 投薬を先行してから手術するのと、手術後に投薬するのでは、なぜ結果が違うのか？

医療介入は**順序を入れ替えると結果が変わる（非可換）**。
この直感を数学的に定式化し、実装として具体化することが本プロジェクトの目的です。

$$E_a \circ E_b(p) \neq E_b \circ E_a(p)$$

詳細は [`discussion/CORE_CLAIM.md`](discussion/CORE_CLAIM.md) を参照。

---

## リポジトリ構成

```
src/MEDICUS/          Haskell実装（medicus-engine）
medicus-api/          Web API（Yesod + GraphQL）
report/               論文ドラフトと公開済みプレプリント
discussion/           理論ドキュメント
verify/               検証ロードマップ（Lean 4）
```

---

## 理論の概要

### 数学的基盤

**MEDICUS関数空間**を Banach 空間として定義し、医療制約を組み込んだノルムを導入します。

$$\|f\|_{\mathcal{M}} := \|f\|_\infty + \|\nabla f\|_\infty + \lambda V_{\mathcal{C}}(f) + \mu S_{\text{entropy}}(f) + \nu E_{\text{thermal}}(f)$$

**モルリファイア（Mollifier）**により離散的な医療パラメータを連続場へ変換し、微分積分の道具を適用可能にします。

**ニュートン法**による二次収束で、制約付き最適化問題を高速に解きます。

### 非可換性と不確定性

医療介入の合成は**非可換モノイド**を形成します。
この非可換性は「セキュリティと効率を同時に最大化できない」という
不確定性関係 $\Delta S \cdot \Delta E \ge K$ の代数的根拠でもあります。

---

## 実装モジュール（medicus-engine）

| モジュール | 役割 |
|---|---|
| `MEDICUS.Space.Core` / `Types` | MEDICUS空間の定義と操作 |
| `MEDICUS.Norm` | MEDICUSノルム計算 |
| `MEDICUS.Constraints` | 医療制約システム |
| `MEDICUS.Optimization.Newton` | ニュートン法最適化 |
| `MEDICUS.Mollifier` | 離散-連続変換 |
| `MEDICUS.StatisticalMechanics` | 統計力学フレームワーク |
| `MEDICUS.UncertaintyPrinciple` | 不確定性原理 |
| `MEDICUS.EntropyManagement` | エントロピー管理 |
| `MEDICUS.PropertyVerification` | 数学的性質の検証 |

---

## ビルドと実行

```bash
# エンジンのビルド
cabal build

# テスト実行（190個以上のプロパティテスト）
cabal test

# API サーバー起動
cd medicus-api && cabal run
```

---

## ドキュメント

| ドキュメント | 内容 |
|---|---|
| [`discussion/CORE_CLAIM.md`](discussion/CORE_CLAIM.md) | 理論の核心命題（最重要） |
| [`report/report.md`](report/report.md) | 論文ドラフト |
| [`verify/ROADMAP.md`](verify/ROADMAP.md) | Lean 4 検証ロードマップ |
| [`medicus-api/README.md`](medicus-api/README.md) | API ドキュメント |

---

## 技術スタック

- **言語：** Haskell（GHC 9.8.2）
- **ビルド：** Cabal 3.0
- **Web API：** Yesod + GraphQL
- **将来：** Lean 4 による形式検証
- **ライセンス：** BSD-3-Clause

---

## 参考文献

- Friedrichs, K. O. (1944). The identity of weak and strong extensions of differential operators.
- Sobolev, S. L. (1938). On a theorem of functional analysis.
- Robertson, H. P. (1929). The uncertainty principle.
- Clarke, F. (2013). Functional analysis, calculus of variations and optimal control.
