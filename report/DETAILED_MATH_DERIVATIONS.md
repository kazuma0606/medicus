# MEDICUS 理論：詳細数式展開ノート

> **目的：** 投稿用ではなく、自分で理解・整理するための詳細ノート。
> 式変形を一歩一歩追い、各仮定がなぜ必要かを丁寧に説明する。
> Lean 4 の形式証明（`MedicusVerify`）と対応させながら記述する。

---

## 目次

1. [Layer 1：非可換モノイド](#layer-1)
2. [Layer 2：MEDICUS 最小空間（Banach 空間）](#layer-2)
3. [Layer 3：Mollifier による平滑化と収束](#layer-3)
4. [各層の仮定まとめと今後の課題](#まとめ)

---

<a name="layer-1"></a>
## 1. Layer 1：非可換モノイド

### 1.1 型の定義

**医療介入** を患者状態空間 $P$ 上の自己写像として定義する：

$$E : P \to P$$

これを Lean 4 では `MedicalIntervention P := P → P` と表す。

$P$ は抽象的な型（具体的な構造を仮定しない）。臨床的には、患者の検査値・症状・既往歴などを含む高次元ベクトルのようなものを想像すればよいが、理論の成立には $P$ の具体的な形は不要。

### 1.2 合成と単位元

合成は「$b$ を先に適用してから $a$ を適用する」：

$$E_a \circ E_b : p \mapsto E_a(E_b(p))$$

単位元は恒等写像：

$$\mathrm{id} : p \mapsto p$$

### 1.3 なぜ群（Group）ではなくモノイド（Monoid）か

**群の定義：** モノイド ＋ 全元に対して逆元が存在。

**臨床的反例：** 外科切除 $E_\mathrm{surg}$ を適用した後に「切除を取り消す」介入は存在しない。放射線治療も同様（組織は変質する）。

形式化では：

> **公理 2（不可逆性）：** $\exists\, E_a$，$\forall\, E_b$，$\exists\, p$，$E_b(E_a(p)) \neq p$

これは「$E_a$ の任意の右逆元候補 $E_b$ に対して、少なくとも 1 つの患者状態 $p$ では元に戻せない」ことを意味する。

よってモノイドの公理（結合律 + 単位元）は成立するが、群の公理（逆元）は一般には成立しない。

### 1.4 モノイド公理の確認

Lean 4 では `instance : Monoid (MedicalIntervention P)` として定義される。

**(i) 結合律** $E_a \circ (E_b \circ E_c) = (E_a \circ E_b) \circ E_c$：

$$[E_a \circ (E_b \circ E_c)](p) = E_a(E_b(E_c(p))) = [(E_a \circ E_b) \circ E_c](p)$$

関数の等価性なので、これは定義から自明（`funext` で確認）。

**(ii) 左単位律** $\mathrm{id} \circ E_a = E_a$：

$$[\mathrm{id} \circ E_a](p) = \mathrm{id}(E_a(p)) = E_a(p)$$

**(iii) 右単位律** $E_a \circ \mathrm{id} = E_a$：

$$[E_a \circ \mathrm{id}](p) = E_a(\mathrm{id}(p)) = E_a(p)$$

以上 3 つはいずれも `rfl`（定義上明らか）で証明できる。

### 1.5 非可換性定理：`noncomm_exists`

**定理：** $\exists\, E_a, E_b : P \to P$，$E_a \circ E_b \neq E_b \circ E_a$

**証明：**

> **公理 1（状態依存性）：** $\forall\, P$，$\exists\, E_a, E_b : P \to P$，$\exists\, p : P$，$E_a(E_b(p)) \neq E_b(E_a(p))$

公理 1 より、ある $E_a, E_b, p$ が存在して $E_a(E_b(p)) \neq E_b(E_a(p))$ が成立する。

仮に $E_a \circ E_b = E_b \circ E_a$ と仮定すると、関数の等価性から $\forall\, x$，$(E_a \circ E_b)(x) = (E_b \circ E_a)(x)$ が成立し、特に $x = p$ で $(E_a \circ E_b)(p) = (E_b \circ E_a)(p)$、つまり $E_a(E_b(p)) = E_b(E_a(p))$ が成立する。これは公理 1 の結論と矛盾。

よって $E_a \circ E_b \neq E_b \circ E_a$。$\square$

Lean 4 での証明：
```lean
theorem noncomm_exists :
    ∃ (a b : MedicalIntervention P), a * b ≠ b * a := by
  obtain ⟨a, b, p, h⟩ := state_dependent P
  exact ⟨a, b, fun heq => h (congr_fun heq p)⟩
```

`congr_fun heq p` が「関数等式 `heq : a * b = b * a` から点ごとの等式 `(a * b) p = (b * a) p`」を導く。

### 1.6 公理 1 の臨床的根拠

「化学療法（A）→手術（B）」と「手術（B）→化学療法（A）」では患者状態が異なることは、実際の治療プロトコルが順序を厳格に定めていること自体が証拠である。たとえば：

- 化学療法は免疫機能を抑制する → その後の手術の回復速度・感染リスクが変わる
- 手術の組織侵襲 → 化学療法の吸収・副作用プロファイルが変わる

この順序依存性を $E_a(E_b(p)) \neq E_b(E_a(p))$ として数学化したのが公理 1。

---

<a name="layer-2"></a>
## 2. Layer 2：MEDICUS 最小空間（Banach 空間）

### 2.1 なぜ $W^{1,\infty}(\mathbb{R})$ を選ぶか

MEDICUS 最小空間 $M_0$ は次のように定義される：

$$M_0 = W^{1,\infty}(\mathbb{R}) = \left\{ f : \mathbb{R} \to \mathbb{R} \;\middle|\; f \text{ は微分可能},\; \|f\|_\infty < \infty,\; \|f'\|_\infty < \infty \right\}$$

**なぜこの選択か：**

1. **Mollifier の適用可能性：** 滑らかな核関数との畳み込みが定義でき、値と微分の両方について収束性を論じられる（Layer 3 の主題）。
2. **Banach 空間になる（証明可能）：** $L^\infty$ や $W^{k,\infty}$ はノルム空間として完備であることが知られている。Shannon エントロピーをノルムに含めると完備性の証明が困難になるため、まず最小版で形式証明を完成させる。
3. **臨床パラメータの自然な界：** 患者状態の測定値（血圧、体温など）は有界であり、その変化率（時間微分）も有界と考えられる。

**Shannon エントロピーをノルムに含めない理由：**
エントロピー $H(f) = -\int f \log f$ は $f$ が確率分布でないと定義が難しい。また $H$ が三角不等式を満たすかどうか、完備性を保つかどうかの証明が現時点では未完成。そのため、第一論文ではエントロピーを目的関数（最適化対象）として扱い、ノルムには含めない。

### 2.2 ノルムの定義

```
supNorm f  = sSup { |f(x)| | x ∈ ℝ }   （値の無限遠ノルム）
gradNorm f = sSup { |f'(x)| | x ∈ ℝ }  （微分の無限遠ノルム）
medicusNorm f = supNorm f + gradNorm f   （MEDICUS ノルム）
```

これは $W^{1,\infty}$ の標準ノルム $\|f\|_{W^{1,\infty}} = \|f\|_{L^\infty} + \|f'\|_{L^\infty}$ に一致する。

**$\mathrm{sSup}$ について：** Lean の `sSup S` は集合 $S$ の上限（supremum）を返す。$S$ が空集合または上に非有界の場合の挙動はデフォルト値（0）になるが、$M_0$ の定義には `BddAbove` 条件が含まれているため、実際には有限の上限が保証されている。

### 2.3 ノルム公理 1：正値性（Positive definiteness）

**主張：** $\|f\|_{M_0} = 0 \Rightarrow f \equiv 0$

**証明：**

$\|f\|_{M_0} = 0$ とする。ノルムの定義より：

$$\mathrm{supNorm}(f) + \mathrm{gradNorm}(f) = 0$$

両項はどちらも非負（後述）なので：

$$\mathrm{supNorm}(f) = 0 \quad \text{かつ} \quad \mathrm{gradNorm}(f) = 0$$

**非負性の証明：** 任意の $x$ に対して $|f(x)| \geq 0$ であり、集合 $\{|f(x)| \mid x \in \mathbb{R}\}$ は空でない（$0$ を代入）ので：

$$\mathrm{supNorm}(f) = \sup_{x} |f(x)| \geq |f(0)| \geq 0$$

$\mathrm{gradNorm}(f) \geq 0$ も同様。

**$f \equiv 0$ の導出：** 任意の $x \in \mathbb{R}$ に対して：

$$|f(x)| \leq \sup_{y} |f(y)| = \mathrm{supNorm}(f) = 0$$

$|f(x)| \leq 0$ かつ $|f(x)| \geq 0$ より $|f(x)| = 0$、したがって $f(x) = 0$。$\square$

Lean 4 での鍵となる補題：
- `le_csSup f.2.2.1 (mem_range x)` : $|f(x)| \leq \mathrm{supNorm}(f)$
- `abs_nonpos_iff.mp` : $|f(x)| \leq 0 \Rightarrow f(x) = 0$

### 2.4 ノルム公理 2：同次性（Homogeneity）

**主張：** $\|c \cdot f\|_{M_0} = |c| \cdot \|f\|_{M_0}$

ここで $c \cdot f$ は $g(x) = c \cdot f(x)$ で定義されるスカラー倍を指す。

**証明の鍵：** 集合のスカラー倍について次の等式を示す：

$$\sup_{x} |c \cdot f(x)| = |c| \cdot \sup_{x} |f(x)|$$

まず集合として：

$$\{|c \cdot f(x)| \mid x \in \mathbb{R}\} = \{|c| \cdot |f(x)| \mid x \in \mathbb{R}\} = |c| \cdot \{|f(x)| \mid x \in \mathbb{R}\}$$

最後の等式は「集合のスカラー倍」（$|c| \cdot S = \{|c| \cdot s \mid s \in S\}$）の定義。

次に `Real.sSup_smul_of_nonneg`（Mathlib の補題）：$c \geq 0$ のとき $\sup(c \cdot S) = c \cdot \sup S$。

$|c| \geq 0$ なのでこれが適用でき：

$$\sup_{x} |c \cdot f(x)| = |c| \cdot \sup_{x} |f(x)| = |c| \cdot \mathrm{supNorm}(f)$$

微分に対しても $\frac{d}{dx}(c \cdot f(x)) = c \cdot f'(x)$ なので同様：

$$\mathrm{gradNorm}(c \cdot f) = |c| \cdot \mathrm{gradNorm}(f)$$

合わせて：

$$\mathrm{medicusNorm}(c \cdot f) = |c| \cdot \mathrm{supNorm}(f) + |c| \cdot \mathrm{gradNorm}(f) = |c| \cdot \mathrm{medicusNorm}(f) \quad \square$$

### 2.5 ノルム公理 3：三角不等式（Triangle inequality）

**主張：** $\|f + g\|_{M_0} \leq \|f\|_{M_0} + \|g\|_{M_0}$

**証明：**

まず値部分：

$$\mathrm{supNorm}(f + g) = \sup_{x} |f(x) + g(x)|$$

任意の $x$ に対して絶対値の三角不等式：

$$|f(x) + g(x)| \leq |f(x)| + |g(x)| \leq \mathrm{supNorm}(f) + \mathrm{supNorm}(g)$$

$\mathrm{supNorm}(f) + \mathrm{supNorm}(g)$ は $\{|f(x)+g(x)|\}$ の上界なので、上限はそれ以下：

$$\mathrm{supNorm}(f + g) \leq \mathrm{supNorm}(f) + \mathrm{supNorm}(g)$$

微分部分も $(f+g)'(x) = f'(x) + g'(x)$（微分の線形性）から同様に：

$$\mathrm{gradNorm}(f + g) \leq \mathrm{gradNorm}(f) + \mathrm{gradNorm}(g)$$

両辺を足すと：

$$\mathrm{medicusNorm}(f + g) \leq \mathrm{medicusNorm}(f) + \mathrm{medicusNorm}(g) \quad \square$$

Lean 4 での証明ではこのパターンを `csSup_le` + `le_csSup` で形式化している。
`csSup_le` は「全元に対して上界 $B$ を示せば $\sup S \leq B$」を意味する。

### 2.6 完備性の証明（Completeness）

これが最も技術的に精緻な部分。以下の 5 ステップで構成される。

#### 2.6.1 設定

$M_0$ 上の Cauchy 列 $\{f_n\}$ が与えられたとする：

$$\forall\, \varepsilon > 0,\; \exists N,\; \forall m,n \geq N : \|f_m - f_n\|_{M_0} < \varepsilon$$

すなわち：

$$\sup_x |f_m(x) - f_n(x)| + \sup_x |f_m'(x) - f_n'(x)| < \varepsilon$$

#### 2.6.2 Step A：値が各点で Cauchy → 点ごとの極限が存在

まず値成分について Cauchy 条件を分離する。$\mathrm{gradNorm}$ 項は非負なので：

$$\sup_x |f_m(x) - f_n(x)| < \varepsilon$$

（$\mathrm{gradNorm}$ 項を落としても不等式は成立）

任意の $x \in \mathbb{R}$ に対して：

$$|f_m(x) - f_n(x)| \leq \sup_y |f_m(y) - f_n(y)| < \varepsilon$$

よって数列 $\{f_n(x)\}$ は $\mathbb{R}$ の Cauchy 列。$\mathbb{R}$ の完備性（これは Mathlib の `cauchySeq_tendsto_of_complete`）より、各 $x$ で極限 $f_*(x)$ が存在：

$$f_*(x) = \lim_{n \to \infty} f_n(x)$$

#### 2.6.3 Step B：微分も各点で Cauchy → 極限微分が存在

同様に微分成分を分離（今度は $\mathrm{supNorm}$ 項を落とす）：

$$\sup_x |f_m'(x) - f_n'(x)| < \varepsilon$$

各 $x$ で $\{f_n'(x)\}$ は Cauchy 列 → 極限 $g_*(x) = \lim_{n\to\infty} f_n'(x)$ が存在。

#### 2.6.4 Step C：一様収束の証明

**値の一様収束** $f_n \xrightarrow{\text{unif}} f_*$：

固定した $n \geq N$ と任意の $x$ に対して、極限操作 $m \to \infty$ を行う：

$$|f_n(x) - f_m(x)| \leq \sup_y |f_n(y) - f_m(y)| < \varepsilon/2 \quad (\forall m \geq N)$$

$m \to \infty$ の極限で $f_m(x) \to f_*(x)$ なので（連続性と極限の可換性）：

$$|f_n(x) - f_*(x)| \leq \varepsilon/2$$

これが全 $x$ で成立するので、$n \geq N$ で $\sup_x |f_n(x) - f_*(x)| \leq \varepsilon/2 < \varepsilon$。

**微分の一様収束** $f_n' \xrightarrow{\text{unif}} g_*$：同様の議論。

Lean 4 では `Metric.tendstoUniformly_iff` を使って一様収束を特徴づける：

```lean
∀ ε > 0, ∀ᶠ n in atTop, ∀ x, dist (limFn x) (seq n x) < ε
```

証明の核心は Cauchy 条件から `le_of_tendsto` で極限の性質を導くこと。

#### 2.6.5 Step D：$f_*$ が微分可能かつ $f_*' = g_*$

これが最も深い部分。$f_n'$ が $g_*$ に一様収束し、各 $f_n$ が微分可能ならば、極限関数 $f_*$ も微分可能で $f_*' = g_*$。

Lean 4 では Mathlib の `hasDerivAt_of_tendstoUniformly` を使用：

```lean
theorem hasDerivAt_of_tendstoUniformly :
  TendstoUniformly (fun n x => deriv (seq n) x) limDeriv atTop →
  (∀ᶠ n in atTop, ∀ y, HasDerivAt (seq n) (deriv (seq n) y) y) →
  (∀ x, Tendsto (fun n => seq n x) atTop (nhds (limFn x))) →
  HasDerivAt limFn (limDeriv x) x
```

これが成立する直感的な理由：

微分の定義は差分商の極限 $f'(x) = \lim_{h\to 0} \frac{f(x+h)-f(x)}{h}$ だが、$n \to \infty$ と $h \to 0$ の二重極限の順序交換が問題になる。一様収束がある（$f_n'$ が一様に $g_*$ に収束する）ことが、この順序交換を正当化する条件になっている。

一様収束なしで点収束だけでは $f_*' = \lim f_n'$ が成立しない反例がある（Weierstrass 函数族など）。これが「一様収束が必要な理由」。

#### 2.6.6 Step E：$f_* \in M_0$ の確認

$f_*$ が $M_0$ のメンバーであるためには以下が必要：

**(i) 微分可能性：** Step D で示した。

**(ii) 値の有界性：** $n_0 \geq N$ を一つ固定する。一様収束より $\varepsilon = 1$ として $\exists n_0$，$\sup_x |f_{n_0}(x) - f_*(x)| < 1$。三角不等式より：

$$|f_*(x)| \leq |f_*(x) - f_{n_0}(x)| + |f_{n_0}(x)| < 1 + \mathrm{supNorm}(f_{n_0})$$

右辺は $x$ に依存しない定数なので $f_*$ は有界。

**(iii) 微分の有界性：** 同様に $f_*' = g_*$ の有界性を示す。$g_*$ は微分列 $\{f_n'\}$ の一様極限なので、$\sup_x |g_*(x)| \leq \sup_x |g_*(x) - f_{n_0}'(x)| + |f_{n_0}'(x)| < 1 + \mathrm{gradNorm}(f_{n_0})$。

#### 2.6.7 Step E：$M_0$ ノルムでの収束

最後に $\|f_n - f_*\|_{M_0} \to 0$ を示す：

$$\|f_n - f_*\|_{M_0} = \sup_x |f_n(x) - f_*(x)| + \sup_x |f_n'(x) - f_*'(x)|$$

Step C より両項ともに $\varepsilon/3$ 以下（$n \geq N$ で）：

$$\|f_n - f_*\|_{M_0} \leq \varepsilon/3 + \varepsilon/3 = 2\varepsilon/3 < \varepsilon \quad \square$$

---

<a name="layer-3"></a>
## 3. Layer 3：Mollifier による平滑化と収束

### 3.1 Mollifier の定義

**バンプ関数（Bump function）** $\varphi : \mathbb{R} \to \mathbb{R}$ の条件：
- $\varphi \in C^\infty$（無限回微分可能）
- $\varphi \geq 0$
- $\mathrm{supp}(\varphi) \subset B(0, \varepsilon)$（コンパクト台）
- $\int_{\mathbb{R}} \varphi(x) \, dx = 1$（正規化）

Lean では `ContDiffBump` として実装されており、内側半径 $r_\mathrm{in} = \varepsilon/2$、外側半径 $r_\mathrm{out} = \varepsilon$ で定義される。

**$\varepsilon$-Mollification** は畳み込み：

$$f_\varepsilon(x) = (f \ast \varphi_\varepsilon)(x) = \int_{\mathbb{R}} f(y) \, \varphi_\varepsilon(x - y) \, dy$$

ここで $\varphi_\varepsilon(x) = \varphi(x/\varepsilon) / \varepsilon^d$（$d = 1$ の場合）は正規化バンプ関数。

### 3.2 定理 1：Mollification は $C^\infty$

**主張：** $f \in M_0$（$\Leftrightarrow f \in W^{1,\infty}$）ならば、$f_\varepsilon = f \ast \varphi_\varepsilon \in C^\infty$。

**証明の概略：**

畳み込みの微分は、正規化された畳み込みで台がコンパクトな項を微分するものとして表せる：

$$\frac{d^k}{dx^k}(f \ast \varphi_\varepsilon)(x) = \int_{\mathbb{R}} f(y) \cdot \varphi_\varepsilon^{(k)}(x - y) \, dy = (f \ast \varphi_\varepsilon^{(k)})(x)$$

$\varphi_\varepsilon^{(k)}$ はコンパクト台を持つ $C^\infty$ 関数なので、$f$ が $L^1_\mathrm{loc}$（局所可積分）であれば畳み込みは $k$ 回微分可能。

**$f \in L^1_\mathrm{loc}$ の確認：** $f \in M_0$ は $f$ が有界連続（連続かつ $\|f\|_\infty < \infty$）を意味し、有界連続関数は局所可積分。

Lean での適用：
```lean
HasCompactSupport.contDiff_convolution_right (lsmul ℝ ℝ)
  (mkBump ε hε).hasCompactSupport
  f.2.1.continuous.locallyIntegrable  -- f が局所可積分
  (mkBump ε hε).contDiff               -- φ_ε が C∞
```

この補題が成立するために必要な条件：
1. 畳み込みの右側（$\varphi_\varepsilon$）がコンパクト台を持つ ✓（ContDiffBump の定義より）
2. 左側（$f$）が局所可積分 ✓（連続かつ有界 → 局所可積分）
3. 右側が $C^\infty$ ✓（ContDiffBump の定義より）

### 3.3 定理 2：Fréchet 微分可能性

$C^\infty$ ならば Fréchet 微分可能性（任意の点で Fréchet 微分が存在する）は自明な系：

$$C^\infty \Rightarrow \text{微分可能} \Rightarrow \text{Fréchet 微分可能}$$

Lean：
```lean
((mollifier_smooth f ε hε).differentiable (by simp)).differentiableAt.hasFDerivAt
```

### 3.4 定理 3：値の収束 $\sup_x |f_\varepsilon(x) - f(x)| \to 0$（$\varepsilon \to 0$）

これが Mollifier の本質的な性質。以下で厳密に証明する。

#### 3.4.1 前提条件と鍵となる補題

**前提：** $f \in M_0$、つまり：
- $f$ は微分可能
- $\sup_x |f(x)| < \infty$（有界）
- $\sup_x |f'(x)| \leq C_f$（微分が有界）← これを使う

**鍵となる補題：** Lipschitz 連続性

$|f'(x)| \leq C_f$ ならば、平均値定理より：

$$|f(z) - f(x)| \leq C_f \cdot |z - x| \quad \forall z, x \in \mathbb{R}$$

**証明：** $z > x$ とする。$f$ は $[x, z]$ 上で微分可能（$M_0$ の仮定）なので、平均値定理より $\exists c \in (x, z)$：

$$f(z) - f(x) = f'(c) \cdot (z - x)$$

$$|f(z) - f(x)| = |f'(c)| \cdot |z - x| \leq C_f \cdot |z - x|$$

この $C_f$ は $\mathrm{gradNorm}(f) = \sup_x |f'(x)|$ で取れる。

Lean では `lipschitzWith_of_nnnorm_deriv_le` を使用：
```lean
-- f.2.1 : Differentiable ℝ f.val
-- ∀ x, ‖deriv f.val x‖₊ ≤ (gradNorm f).toNNReal （定義から）
have hf_lip : LipschitzWith (gradNorm f).toNNReal f.val :=
  lipschitzWith_of_nnnorm_deriv_le f.2.1 (fun x => ...)
```

#### 3.4.2 値の $\sup$ 収束の証明

**補題（`dist_normed_convolution_le`）：** $g$ が $B(x_0, \varepsilon)$ 上で Lipschitz 定数 $L$ を持つとき：

$$|((\varphi_\varepsilon \ast g)(x_0)) - g(x_0)| \leq L \cdot \varepsilon$$

**証明の概略：**

$$(\varphi_\varepsilon \ast g)(x_0) - g(x_0) = \int_{\mathbb{R}} \varphi_\varepsilon(x_0 - y) g(y) \, dy - g(x_0)$$

$$= \int_{\mathbb{R}} \varphi_\varepsilon(x_0 - y) g(y) \, dy - g(x_0) \cdot \underbrace{\int_{\mathbb{R}} \varphi_\varepsilon(x_0 - y) \, dy}_{=1}$$

$$= \int_{\mathbb{R}} \varphi_\varepsilon(x_0 - y) [g(y) - g(x_0)] \, dy$$

絶対値を取り：

$$|(\varphi_\varepsilon \ast g)(x_0) - g(x_0)| \leq \int_{\mathbb{R}} \varphi_\varepsilon(x_0 - y) |g(y) - g(x_0)| \, dy$$

$\varphi_\varepsilon(x_0 - y) \neq 0$ となるのは $|x_0 - y| < \varepsilon$（台の条件）のときのみ。この領域で Lipschitz 条件 $|g(y) - g(x_0)| \leq L \cdot |y - x_0| \leq L \cdot \varepsilon$ を使うと：

$$\leq \int_{\mathbb{R}} \varphi_\varepsilon(x_0 - y) \cdot L \cdot \varepsilon \, dy = L \cdot \varepsilon \cdot \underbrace{\int_{\mathbb{R}} \varphi_\varepsilon(x_0 - y) \, dy}_{=1} = L \cdot \varepsilon$$

これが Lean の `ContDiffBump.dist_normed_convolution_le`：

```lean
(φs n).dist_normed_convolution_le
  f.2.1.continuous.aestronglyMeasurable  -- f が可測
  (fun z hz => ...)                       -- z ∈ ball(x, rOut) での Lipschitz 評価
```

#### 3.4.3 $\sup$ 収束の完成

任意の $x$ に対して上の補題より：

$$|f_{\varepsilon_n}(x) - f(x)| \leq C_f \cdot \varepsilon_n$$

これが全 $x$ に対して均一に成立するので：

$$\sup_x |f_{\varepsilon_n}(x) - f(x)| \leq C_f \cdot \varepsilon_n$$

$\varepsilon_n \to 0$ より（これが $n \to \infty$ の意味）右辺 $\to 0$、よって $\sup_x |f_{\varepsilon_n}(x) - f(x)| \to 0$。

Lean での証明は `squeeze_zero` タクティク：

```lean
apply squeeze_zero
· intro n  -- 非負性: 0 ≤ sSup |f_n - f|
· intro n  -- 上界: sSup |f_n - f| ≤ gradNorm f * rOut_n
· simpa [mul_zero] using tendsto_const_nhds.mul hφ  -- 上界 → 0
```

### 3.5 定理 4：微分の収束と W^{2,∞} 仮定

#### 3.5.1 問題の設定

第 2 ノルム項を収束させるには $\sup_x |f_\varepsilon'(x) - f'(x)| \to 0$ が必要。

自然な証明戦略：

$$f_\varepsilon'(x) = \frac{d}{dx}(f \ast \varphi_\varepsilon)(x) \overset{?}{=} (f' \ast \varphi_\varepsilon)(x)$$

もし微分と畳み込みが交換できれば（「積分記号下微分」または「部分積分」）、$f'$ に対して値の収束と同じ議論が使えて $\sup_x |(f' \ast \varphi_\varepsilon)(x) - f'(x)| \to 0$ が示せる。

#### 3.5.2 部分積分（IBP）の問題点

$f' \ast \varphi_\varepsilon = (f \ast \varphi_\varepsilon)'$ を証明するには、積分記号下で微分できることを示す必要がある：

$$\frac{d}{dx} \int f(y) \varphi_\varepsilon(x - y) \, dy = \int f(y) \frac{\partial}{\partial x} \varphi_\varepsilon(x - y) \, dy$$

この交換が正当化される条件として Mathlib には `hasFDerivAt_integral_of_dominated_loc_of_lip` があるが、この適用は技術的に複雑（優収束条件の確認が必要）。

**現在の状況：** この証明は Lean 4 の形式化でまだ完成していない（タスク A1）。

#### 3.5.3 現在の回避策：W^{2,∞} 仮定

代わりに、$M_0$ ノルムの第 2 項を次のように定式化する：

$$\text{第 2 項} = \sup_x \left| (\varphi_n \ast f')(x) - f'(x) \right|$$

（$f_\varepsilon' = \frac{d}{dx}(f \ast \varphi)$ の代わりに $\varphi \ast f'$ を使う）

これは数学的に同じ（交換が成立すれば等しい）だが、形式化では直接扱いやすい。

この第 2 項に対して値の収束と同じ議論を適用するには、$f'$ が Lipschitz である必要がある：

$$|f'(z) - f'(x)| \leq K_{f'} \cdot |z - x|$$

$f'$ が Lipschitz ⟺ $f'' \in L^\infty$ ⟺ $f \in W^{2,\infty}$。

よって現在の定理には追加の仮定が必要：

```lean
(Kdf : ℝ≥0)
(hdf_lip : LipschitzWith Kdf (fun x => deriv f.val x))  -- W^{2,∞} 仮定
```

#### 3.5.4 W^{2,∞} 仮定の臨床的解釈

$f'' \in L^\infty$ とは「微分（変化率）の変化率が有界」を意味する。臨床的には：

- $f$ = 患者状態の値 → $f'$ = 状態の変化率（e.g., 体温上昇速度）
- $f''$ = 変化率の変化率（e.g., 体温上昇の加速度）

実際の臨床パラメータでは急激な加速度的変化は起きにくいため、この仮定は「臨床的に自然」と主張できる。

ただし、$M_0 = W^{1,\infty}$ の範囲ではこの条件を一般に保証できず、Lean 4 の定理は $W^{2,\infty}$ の関数についての定理になっている。

#### 3.5.5 最終的な `mollifier_converges` 定理の構造

```lean
theorem mollifier_converges (f : MedicusMin) (φs : ℕ → ContDiffBump (0 : ℝ))
    (hφ : rOut(φs n) → 0)
    (Kdf : ℝ≥0)
    (hdf_lip : LipschitzWith Kdf (deriv f.val)) :
    (第1項: sup |f_n - f|) + (第2項: sup |(φ_n ⋆ f') - f'|) → 0
```

証明の骨格：

```
hf_lip : f は Lipschitz（M₀ 仮定 + MVT）
         |f(z) - f(x)| ≤ gradNorm(f) · |z - x|

hdf_lip : f' は Lipschitz（W^{2,∞} 仮定）
         |f'(z) - f'(x)| ≤ Kdf · |z - x|

hbdd_val : BddAbove で sup |f_n - f| ≤ gradNorm(f) · rOut_n
hbdd_deriv : BddAbove で sup |(φ_n ⋆ f') - f'| ≤ Kdf · rOut_n

hval : squeeze_zero で sup |f_n - f| → 0
hderiv : squeeze_zero で sup |(φ_n ⋆ f') - f'| → 0

simpa using hval.add hderiv  -- 合算して 0 に収束
```

#### 3.5.6 なぜ `squeeze_zero` が使えるか

`squeeze_zero` の型：

```
squeeze_zero : (∀ t, 0 ≤ f t) → (∀ t, f t ≤ g t) → Tendsto g atTop (nhds 0)
               → Tendsto f atTop (nhds 0)
```

これは「0 以上の量が 0 に収束する量で上から抑えられているなら 0 に収束する」という単純なはさみうちの原理。

**0 以上：** `sSup (Set.range |·|) ≥ 0`（`sSup` は `|f(0)| ≥ 0` で下から抑えられる）

**上界：** `sSup {|f_n(x) - f(x)| | x} ≤ gradNorm(f) · rOut_n`（上で証明）

**上界の収束：** `tendsto_const_nhds.mul hφ` で `gradNorm(f) · rOut_n → gradNorm(f) · 0 = 0`

---

<a name="まとめ"></a>
## 4. 各層の仮定まとめと今後の課題

### 4.1 仮定一覧

| 層 | 使用した仮定 | 仮定の強さ | 除去可能か |
|---|---|---|---|
| Layer 1 | 公理 1（状態依存性）, 公理 2（不可逆性） | 臨床的自明 | 不要（公理として設定） |
| Layer 2 | $f$ 微分可能, $f$ 有界, $f'$ 有界（= $W^{1,\infty}$） | $M_0$ の定義 | 不要（定義による） |
| Layer 3（C∞性） | $f \in L^1_\mathrm{loc}$（$W^{1,\infty}$ から導出） | $M_0$ から導出 | 不要 |
| Layer 3（値収束） | $f' \in L^\infty$（= $M_0$ の定義）→ $f$ は Lipschitz | $M_0$ の定義 | 不要 |
| Layer 3（微分収束） | $f'' \in L^\infty$（= $W^{2,\infty}$）⚠️ | **$M_0$ より強い** | タスク A1 で除去可能 |

### 4.2 W^{2,∞} 仮定の除去（タスク A1）

タスク A1 では次の定理の形式証明を目指す：

```lean
theorem convolution_deriv_comm (f : MedicusMin) (φ : ContDiffBump (0 : ℝ)) (x : ℝ) :
    HasDerivAt (f.val ⋆ ⇑φ) ((fun y => deriv f.val y) ⋆ ⇑φ) x x
```

これが証明できれば、`mollifier_converges` の仮定から `Kdf` と `hdf_lip` を除去できる。

**証明のアプローチ：** `hasFDerivAt_integral_of_dominated_loc_of_lip` を適用する。この補題は「$\int f(y) K(x, y) \, dy$ の $x$ についての Fréchet 微分が $\int f(y) \partial_x K(x, y) \, dy$ に等しい」ことを、Lipschitz 優収束条件の下で保証する。

**難しさ：** $K(x, y) = \varphi_\varepsilon(x - y)$ の $x$ についての Lipschitz 評価を $f$ の積分と合わせて優収束条件に当てはめる作業が技術的に複雑。

### 4.3 現状の評価

```
✅ Layer 1: 非可換モノイド（sorry ゼロ、公理 + 定理）
✅ Layer 2: Banach 空間（sorry ゼロ、3 公理 + 完備性）
✅ Layer 3 (C∞性): Mollification は C∞（sorry ゼロ）
✅ Layer 3 (値収束): M_0 ノルム第 1 項の収束（sorry ゼロ）
⚠️  Layer 3 (微分収束): W^{2,∞} 仮定で sorry ゼロ達成
   → 論文では「f ∈ W^{2,∞} のとき」と明示するか、
     タスク A1 の部分積分証明で仮定を除去するか選択。
```

### 4.4 直感的まとめ

MEDICUS 理論が言いたいことを平易に言い直すと：

1. **医療介入は非可換モノイドを形成する（Layer 1）**
   - 「化療→手術」≠「手術→化療」（順序依存性）
   - 切除は取り消せない（不可逆性）

2. **患者状態の関数空間は Banach 空間になる（Layer 2）**
   - 「有界で微分可能な関数」という自然なクラス $W^{1,\infty}$ を選べば、
     距離の概念（ノルム）が入り、収束・極限が議論できる。

3. **Mollifier によって任意の $W^{1,\infty}$ 関数を $C^\infty$ で近似できる（Layer 3）**
   - 粗い臨床データを滑らかな関数で近似できる
   - 近似の誤差は $\varepsilon$（カーネル幅）に比例し、$\varepsilon \to 0$ で消える
   - 微分まで含めたノルムで収束するためには $f''$ の有界性が現時点では必要（留保）

---

*このノートは Lean 4 形式証明 `MedicusVerify/` の内容と対応している。*
*最終更新: 2026-03-11*
