# CLAUDE.md — MEDICUSプロジェクト コンテキストガイド

このファイルはAIアシスタントが次のセッションで即座に文脈を把握するためのガイドです。

---

## プロジェクトの本質

**MEDICUS（Medical-Enhanced Data Integrity Constraint Unified Space）**

医療ドメインの実務家が、臨床知見と数学・物理の対話から構築した理論。
核心は「医療介入の順序依存性を数学的に定式化する」こと。

---

## 核心命題（ここから始めること）

> 医療介入の合成は非可換モノイドを形成する。
>
> $$E_a \circ E_b(p) \neq E_b \circ E_a(p)$$

- **臨床的根拠：** 治療プロトコルが順序を厳格に定めている事実そのものが証拠
- **数学的構造：** 群（Group）ではなく**モノイド**（逆元なし＝不可逆性）
- **詳細：** `discussion/CORE_CLAIM.md`

---

## 現状の一言サマリー

「離散的な医療介入を $C^\infty$ 空間に厳密に埋め込み、非可換な順序依存性を現代的な勾配最適化で解く枠組みを作った。核心は動いている。次は非可換性の数値実証と Adam の実装。」
→ 詳細は `discussion/STATUS.md`

## 文書の地図

```
CLAUDE.md                    ← このファイル
README.md                    ← プロジェクト概要（開発者向け）

report/
├── report.md                ← 論文ドラフト（§2-§4が核心、§5以降は将来構想）
└── preprints202505.1927.v1.pdf  ← 公開済みプレプリント（アイデア段階）

discussion/
├── CORE_CLAIM.md            ← 理論の憲法（最重要）
├── MEDICUS_THEORY_ALGEBRAIC_INTEGRATION.md  ← 群論・圏論補足
└── archive/                 ← 過去の探索記録（参照用）

verify/
└── ROADMAP.md               ← Haskell + Lean 4 検証ロードマップ

src/MEDICUS/                 ← Haskell実装（medicus-engine）
medicus-api/                 ← Web API（Yesod + GraphQL）
reports/                     ← 実装ログ（AIが生成した作業記録）
```

---

## 理論の現在地と課題

### 整合性が高い（solid）
- MEDICUS空間の定義・ノルム（`report.md` §2）
- ニュートン法による収束性（`report.md` §4）
- 非可換モノイド構造の主張（`CORE_CLAIM.md`）

### 仮説・要検証
- 不確定性関係 $\Delta S \cdot \Delta E \ge K$（$K$ の導出が未完成）
- `ℏ_medical` 等の記法（仮置き）

### 将来構想（現時点では切り離す）
- ブロックチェーン統合（`report.md` §5）
- 非可換幾何学（NCG）・スペクトル三重組
- FINICUS・INDUSTICUS等への横展開

---

## 技術スタック

- **言語：** Haskell（GHC 9.8.2）、Cabal
- **Web API：** Yesod + GraphQL（`medicus-api/`）
- **将来：** Lean 4 による形式検証（未着手）
- **ビルド：** `cabal build` / `cabal test`

---

## 次にやること（優先順）

1. **非可換性の数値実証** — `Ea∘Eb ≠ Eb∘Ea` を具体的なパラメータでHaskell実装
2. **二段階最適化の実験** — Adam warm-start + ニュートン法の収束比較（Haskell）
3. **不確定性定数 $K$ の導出** — 具体的な定義から導く
4. **Lean 4 形式検証** — モノイド公理・ノルム公理の証明

---

## オーナーの立場

数学者ではなく、医療ドメインの実務家。
AIとの対話を通じて理論を構築してきた経緯がある。
「主張できることだけを主張し、境界線を明示する」姿勢を重視している。
