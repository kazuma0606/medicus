# MEDICUS 論文化タスク一覧（改訂版）

> **方針（2026-03-11 改訂）**
> - 旧タスクは `_tasks.md` に凍結済み（Layer 1–3 形式証明はすべて sorry ゼロで完了）
> - 本ファイルは「論文投稿」を最終ゴールとした残タスクのみを管理
> - **Future work ゼロ**を目標とする（形式証明・数値実証・論文記述をすべて完結させる）
> - 不確定性原理は第二論文。本タスクリストには「準備のみ」を記載

---

## 完了済み（参照用）

```
✅ Layer 1: 非可換モノイド証明（noncomm_exists, no_inverse）
✅ Layer 2: Banach 空間証明（ノルム公理 + 完備性、sorry ゼロ）
✅ Layer 3: Mollifier C∞性・Fréchet 微分可能性・収束（sorry ゼロ）
⚠️  mollifier_converges: W^{2,∞} 仮定を明示（→ タスク A1 で解消 or B3 で記述）
```

---

## A. Lean 4：残証明タスク

### A1. 部分積分（convolution と deriv の交換）の形式証明

> **目的:** `mollifier_converges` の W^{2,∞} 仮定を除去し、M₀ = W^{1,∞} のまま収束を証明する。

- [ ] A1.1 `HasDerivAt_convolution_right_integral` — 積分記号下微分
  - `hasFDerivAt_integral_of_dominated_loc_of_lip` を適用
  - 前提: `φ_ε` コンパクト台 + `f` 微分可能 + domination 条件
  - ファイル: `MedicusVerify/Layer3Mollifier.lean`

- [ ] A1.2 `convolution_deriv_comm` — 交換公式の定理化
  ```lean
  theorem convolution_deriv_comm (f : MedicusMin) (φ : ContDiffBump (0 : ℝ)) (x : ℝ) :
      HasDerivAt (f.val ⋆[lsmul ℝ ℝ, volume] ⇑φ)
                 ((fun y => deriv f.val y) ⋆[lsmul ℝ ℝ, volume] ⇑φ) x x
  ```
  - A1.1 の系として導出

- [ ] A1.3 `mollifier_converges` の改訂
  - `Kdf` と `hdf_lip` 仮定を削除
  - 第 2 項を `(φ_n ⋆ deriv f)` → `deriv (φ_n ⋆ f)` に戻す
  - A1.2 を内部で使って証明

  > A1 が難しい場合の代替案（A1': 仮定の明示化）
  > - W^{2,∞} 仮定を明示したまま論文 §4 の定理文に「f ∈ W^{2,∞}」と追記
  > - Lean 4 コードはそのまま。論文で「この条件は臨床的パラメータで自然に成立」と動機づけ
  > - A1 ができれば差し替え、できなければ A1' で論文を完成させる

---

## B. 論文（SUBMISSION_CANDIDATE_report_v3_math.md）の改訂タスク

### B1. §2（介入代数）の更新

- [ ] B1.1 Lean 4 検証済みバッジを定理に付与
  - 定理 (Monoid Instance), 定理 (noncomm_exists), 定理 (no_inverse) に
    "*(Lean 4 verified)*" を追記
  - 公理 `state_dependent_intervention`・`irreversible_intervention` の
    数学的動機（臨床的根拠）を1段落追加

- [ ] B1.2 §2.2 の非可換性定理を明確化
  - 現行の証明スケッチを、Lean 4 コードへの参照（Appendix A）に置き換え

### B2. §3（MEDICUS 関数空間）の更新

- [ ] B2.1 定理 1（Banach 空間）に "*(Lean 4 verified)*" を追記
  - 完備性の証明概略（Cauchy 列 → 一様収束 → 微分交換）を整理
  - 仕様書 `PROOF_SPEC.md §2` と整合させる

- [ ] B2.2 §3.3（拡張ノルムの問題）を削除または縮小
  - エントロピーを目的関数に移した設計判断を1文で説明し、§3.3 は削除
  - これで "unresolved issue" 扱いをやめる

### B3. §4（Mollifier）の更新

- [ ] B3.1 定理 2（C∞性・収束）に "*(Lean 4 verified)*" を追記
  - A1 完了時: W^{1,∞} のまま収束定理を記述
  - A1' の場合: 「f ∈ W^{2,∞} のとき」と仮定を明示。臨床的動機を付記

- [ ] B3.2 §4.2 の「MEDICUS 空間への適用」を Lean 4 実装と整合させる
  - `mollify` 定義・`mollifier_smooth`・`mollifier_frechet_diff` の Lean コード断片を掲載

### B4. §6（今後の課題）の廃止・再構成

> 目標: §6 を完全削除し、論文を完結した主張のみで構成する。

- [ ] B4.1 §6.1（Lean 4 形式検証）→ 削除（完了済みのため）
- [ ] B4.2 §6.2（拡張ノルムの問題）→ 削除（B2.2 で解決）
- [ ] B4.3 §6.3（非可換性の定量的評価）→ B5 の数値例セクションに移動
- [ ] B4.4 §6.4（不確定性原理）→ 削除（第二論文として切り離し）
- [ ] B4.5 §6 全体を削除し、§5 を最終セクションとして論文を締める
  - 末尾に "Conclusion" または "Summary" を1段落追加

### B5. 数値例セクションの追加（§5 更新または新 §5.3）

> 「非可換性の定量的評価」（旧 §6.3）を結果として示す。

- [ ] B5.1 Haskell による数値実証の記述
  - `medicus-engine` の `MEDICUS.StatisticalMechanics` または介入合成モジュールを使用
  - 具体例: 「化療(A)→手術(B)」 vs 「手術(B)→化療(A)」の患者状態差 ‖A∘B(p) - B∘A(p)‖

- [ ] B5.2 数値の計算・表示
  - Haskell スクリプトで具体的なパラメータと数値を出力
  - 論文に表または図として掲載（最低1例）

- [ ] B5.3 数値例が "公理の動機" を裏付けることを文章で説明
  - `state_dependent_intervention` 公理が具体的にどう実現されているかを示す

### B6. Appendix A（Lean 4 コード）の追加

- [ ] B6.1 Appendix A の節を論文末尾に追加
  - A.1: Layer 1（非可換モノイド）—— `Layer1Monoid.lean` のコア部分
  - A.2: Layer 2（Banach 空間）—— `Layer2Banach.lean` の主要定理
  - A.3: Layer 3（Mollifier）—— `Layer3Mollifier.lean` の主要定理

- [ ] B6.2 GitHub リポジトリの準備
  - `medicus_theory/verify/lean4/` を公開リポジトリに push
  - Appendix A の冒頭に URL を記載
  - README に `lake build` 手順を追記

- [ ] B6.3 Mathlib バージョンの固定
  - `lean-toolchain` のバージョンを論文に記載
  - `lake-manifest.json` を commit

---

## C. 投稿準備タスク

- [ ] C1. arXiv 投稿
  - カテゴリ: `math.FA`（関数解析）、クロスリスト `math.LO`（数理論理・形式検証）
  - Abstract に "formally verified using Lean 4 / Mathlib" を明記
  - GitHub URL を論文本文に記載

- [ ] C2. 論文タイトル・著者情報の確定
  - 現行タイトル（日本語）を英語に変換
  - 投稿候補: `"MEDICUS: A Formally Verified Non-Commutative Monoid Framework
    for Medical Intervention Optimization"`

---

## D. 第二論文準備（不確定性原理）——最小限の準備のみ

> 本論文には含めない。第二論文のための数学的骨格を整理しておく。

- [ ] D1. 交換子の Lean 4 定義（型のみ、深い証明なし）
  ```lean
  -- MedicalIntervention が加法構造をもつ拡張空間上の交換子
  def commutator (A B : MedicalIntervention P) : P → P :=
    fun p => A (B p) - B (A p)
  -- これが恒等的に 0 でないことが noncomm_exists と同値
  ```
  ファイル: `MedicusVerify/SecondPaper/Commutator.lean`（新規）

- [ ] D2. 不確定性原理の数学的定式化メモ
  - 演算子 $\hat{S}$（症状管理）と $\hat{E}$（治療コスト）の MEDICUS 空間上の定義案
  - Robertson 不等式との対応関係
  - ファイル: `discussion/SECOND_PAPER_UNCERTAINTY.md`（新規）

---

## 優先順と依存関係

```
A1 (IBP証明) ──┐
               ├─→ B3.1 → B4.1 → B4.5
A1' (代替) ───┘

B1.1, B2.1 ────────────────────────→ B6.1 → B6.2 → C1
B5.1, B5.2, B5.3 ──→ B4.3 → B4.5

D1, D2 ─── 独立（いつでも並行可）
```

**最速投稿ルート:**
1. A1' を選択（W^{2,∞} 仮定を論文に明示）
2. B1–B5 の論文改訂
3. B6（Appendix A + GitHub）
4. C（arXiv 投稿）
5. D は並行して少しずつ進める

---

## 完了の定義

| タスク群 | 完了条件 |
|---|---|
| A | `lake build MedicusVerify` が sorry ゼロで通る |
| B | 論文の §6 が削除され、全主要定理に "(Lean 4 verified)" がある |
| B5 | Haskell で数値が出力され、論文に表/図として掲載 |
| B6 | GitHub に push 済み、Appendix A が論文に存在 |
| C | arXiv 投稿完了（プレプリント URL 取得） |
| D | `SECOND_PAPER_UNCERTAINTY.md` が存在し、Lean 4 ファイルがビルドを通る |
