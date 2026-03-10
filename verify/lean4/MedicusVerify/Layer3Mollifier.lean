/-
  MedicusVerify.Layer3Mollifier
  ==============================
  Layer 3: Mollifier proofs for the MEDICUS minimal space.

  Theorems:
  - mollifier_smooth       (Task 4.1) ContDiff ℝ ⊤ (mollify f ε)
  - mollifier_frechet_diff (Task 4.3) HasFDerivAt（4.1 の系）
  - mollifier_converges    (Task 4.2) 点ごと収束（一様収束は sorry; 証明戦略はコメント参照）

  Ref: verify/PROOF_SPEC.md section 3
-/

import Mathlib.Analysis.Calculus.BumpFunction.Basic
import Mathlib.Analysis.Calculus.ContDiff.Convolution
import Mathlib.Analysis.Calculus.BumpFunction.Convolution
import MedicusVerify.Layer2Banach

open scoped Convolution
open ContinuousLinearMap Filter MeasureTheory Topology

noncomputable section

namespace MedicusMin

-- ============================================================
-- 前準備：Mollifier の定義
-- ============================================================

/-- φ_ε : 半径 ε の C∞ バンプ関数（ContDiffBump の具体例）。
    support ⊆ ball(0, ε) を満たし，ball(0, ε/2) 上で恒等的に 1。 -/
private def mkBump (ε : ℝ) (hε : 0 < ε) : ContDiffBump (0 : ℝ) where
  rIn     := ε / 2
  rOut    := ε
  rIn_pos := half_pos hε
  rIn_lt_rOut := half_lt_self hε

/-- f の ε-Mollification: f_ε = (f ⋆ φ_ε)(x) = ∫ y, f(y) · φ_ε(x - y) dy。
    畳み込みは `MeasureTheory.convolution` (記法 ⋆[L, μ]) を用いる。 -/
def mollify (f : MedicusMin) (ε : ℝ) (hε : 0 < ε) : ℝ → ℝ :=
  (f : ℝ → ℝ) ⋆[lsmul ℝ ℝ, volume] ⇑(mkBump ε hε)

-- ============================================================
-- Task 4.1: C∞ 性
-- φ_ε ∈ C∞（コンパクト台）∧ f ∈ L¹_loc → f ⋆ φ_ε ∈ C∞
-- ============================================================

/-- Mollification は C∞（任意の ε > 0 に対して）。

    証明概略:
    - `mkBump ε hε` は ContDiffBump なので `⇑(mkBump ε hε) ∈ C∞` かつコンパクト台をもつ
    - f ∈ M_0 ⊆ C¹ ⊆ C ⊆ L¹_loc（連続関数は局所可積分）
    - `HasCompactSupport.contDiff_convolution_right` を適用 -/
theorem mollifier_smooth (f : MedicusMin) (ε : ℝ) (hε : 0 < ε) :
    ContDiff ℝ (⊤ : ℕ∞) (mollify f ε hε) := by
  unfold mollify
  -- HasCompactSupport.contDiff_convolution_right は n : ℕ∞ に対して成立
  -- n = (⊤ : ℕ∞) を選ぶと結果は ContDiff ℝ (↑(⊤ : ℕ∞)) = ContDiff ℝ (⊤ : ℕ∞) (C∞ レベル)
  exact HasCompactSupport.contDiff_convolution_right (lsmul ℝ ℝ)
    (mkBump ε hε).hasCompactSupport
    f.2.1.continuous.locallyIntegrable
    (mkBump ε hε).contDiff

-- ============================================================
-- Task 4.3: Fréchet 微分可能性（4.1 の系）
-- ============================================================

/-- Mollification は各点でフレシェ微分可能。
    mollifier_smooth の直接的な系: C∞ → 微分可能 → HasFDerivAt。 -/
theorem mollifier_frechet_diff (f : MedicusMin) (ε : ℝ) (hε : 0 < ε) (x : ℝ) :
    HasFDerivAt (mollify f ε hε) (fderiv ℝ (mollify f ε hε) x) x :=
  ((mollifier_smooth f ε hε).differentiable (by simp [ENat.top_ne_zero])).differentiableAt.hasFDerivAt

-- ============================================================
-- Task 4.2: 収束性 (点ごと収束の証明; M_0 ノルム収束は sorry)
-- ============================================================

/-
  証明戦略 (M_0 ノルム収束 ‖f_ε - f‖_M0 → 0):

  (a) 値の点ごと収束 (mollify f ε hε) x → f x as ε → 0:
      ContDiffBump.convolution_tendsto_right_of_continuous を使う。
      f ∈ M_0 は C¹ なので連続。正規化バンプ φ.normed μ に対して成立。

  (b) ‖f_ε - f‖∞ → 0 (一様収束):
      f は gradNorm(f) を Lipschitz 定数とする Lipschitz 関数
      → 一様連続。一様連続関数の mollification は一様収束する。
      (要: Lipschitz→UniformContinuous + 一様連続関数の mollification 補題)

  (c) ‖(f_ε)' - f'‖∞ → 0:
      (f ⋆ φ_ε)' = f ⋆ φ_ε' (積分記号下微分, φ_ε ∈ C∞)
      f' も有界なので同様の議論が適用可。ただし f' の一様連続性は
      M_0 の定義から直接は保証されない（追加仮定 or sorry が必要）。

  完全な形式化に必要な Mathlib 補題:
  - ContDiffBump.convolution_tendsto_right_of_continuous (点ごと収束)
  - Lipschitz → 一様収束の mollification 定理（Mathlib 未整備の可能性あり）
  - HasDerivAt を使った積分記号下微分（UniformLimitsDeriv 的なアプローチ）
-/

/-- 正規化バンプ関数族 φ_n (rOut → 0) に対する点ごと収束の証明。
    f ∈ M_0 は連続なので `convolution_tendsto_right_of_continuous` が直接適用できる。 -/
theorem mollifier_pointwise_converges
    (f : MedicusMin) (x₀ : ℝ)
    (φs : ℕ → ContDiffBump (0 : ℝ))
    (hφ : Filter.Tendsto (fun n => (φs n).rOut) atTop (nhds 0)) :
    Filter.Tendsto
      (fun n => ((φs n).normed volume ⋆[lsmul ℝ ℝ, volume] (f : ℝ → ℝ)) x₀)
      atTop (nhds (f x₀)) :=
  ContDiffBump.convolution_tendsto_right_of_continuous hφ f.2.1.continuous x₀

/-- (sorry) M_0 ノルム収束 ‖f_ε - f‖_M0 → 0。
    上記の証明戦略 (a)-(c) に従えば示せるが，完全な形式化は将来の課題。 -/
theorem mollifier_converges
    (f : MedicusMin)
    (φs : ℕ → ContDiffBump (0 : ℝ))
    (hφ : Filter.Tendsto (fun n => (φs n).rOut) atTop (nhds 0)) :
    Filter.Tendsto
      (fun n =>
        sSup (Set.range fun x =>
          |(((φs n).normed volume ⋆[lsmul ℝ ℝ, volume] (f : ℝ → ℝ)) x - f x)|) +
        sSup (Set.range fun x =>
          |deriv ((φs n).normed volume ⋆[lsmul ℝ ℝ, volume] (f : ℝ → ℝ)) x - deriv f x|))
      atTop (nhds 0) := by
  sorry
  /-
    証明スケッチ:
    Step 1: 値部分
      have hunif : TendstoUniformly
            (fun n x => ((φs n).normed volume ⋆[lsmul ℝ ℝ, volume] (f : ℝ → ℝ)) x)
            (f : ℝ → ℝ) atTop := ...
      -- f is Lipschitz with constant gradNorm f (mean value theorem)
      -- Lipschitz → UniformContinuous
      -- UniformContinuous → mollification converges uniformly
    Step 2: 導関数部分
      have hderiv_comm : ∀ n x, deriv (...) x = (... ⋆[lsmul ℝ ℝ, volume] deriv f) x := ...
      -- differentiation commutes with convolution when φ ∈ C∞ with compact support
      -- (deriv f) is bounded and measurable, same argument applies
    Step 3: Sum ≤ ε/2 + ε/2 = ε
  -/

end MedicusMin

end
