# MEDICUS空間理論 拡張版：介入代数の深化と関数解析的基盤

> **このファイルについて（2026-03-10）**
> `report_v3_math.md`（arXiv math.FA 投稿想定の核心版）を保存した上で、
> 以下の議論から浮上した拡張アイデアを織り込んだバージョン。
>
> **主な変更・追加点：**
> - Layer 1 に半群論・圏論・因果圏を追加
> - Layer 2 を Sobolev 空間・変分法・最適輸送で増強
> - セキュリティ×効率の不確定性原理（旧 Layer 3）を削除——核心の焦点化
> - フレシェ微分・ガトー微分の区別を明示
> - 各拡張の「難易度と MEDICUS への接続しやすさ」を Remark に記載
>
> **論文への採用方針：**
> §2〜§4（Layer 1・2 コア）は v3 と同様に arXiv math.FA の核心。
> §5 以降は将来論文または付録候補。無理に一本に詰め込まない。

---

## Abstract

医療介入の集合は合成演算のもとで**非可換モノイド**を形成する。
本稿はこの観察を出発点として、離散的な介入代数を連続関数空間へ厳密に埋め込む
MEDICUS（Medical-Enhanced Data Integrity Constraint Unified Space）空間理論を展開する。

まず医療介入集合 $(\mathcal{E}, \circ)$ がモノイド公理を満たすことを示し、
半群論的手法によって「交換可能な介入ペア」の代数的特徴づけを与える。
次に圏論的視点から介入を射（morphism）として再定式化し、
患者状態変換の構造的記述を与える。

MEDICUS 最小空間を $C^1(\Omega)$ の部分空間として定義し Banach 空間であることを証明する（定理 1）。
このノルムが Sobolev 空間 $W^{1,\infty}$ と一致することを示し、
埋め込み定理を通じて豊富な解析的道具を援用可能にする。

さらに Friedrichs Mollifier を医療制約に特化して拡張し、
任意の $L^1$ 関数が MEDICUS 空間内で $C^\infty$ 関数列により近似できることを示す（定理 2）。
この連続化により離散介入パラメータの**フレシェ微分**が定義可能となり、
連鎖律が保証されることで勾配ベース最適化の数学的正当性が確立される。

**Mathematics Subject Classification:** 46E35, 46B25, 47H99, 18A99

**Keywords:** 非可換モノイド、関数解析、Banach空間、Sobolev空間、Mollifier、圏論、フレシェ微分、変分法

---

## 1. Introduction

### 1.1 問題の背景

離散的な操作列の最適化は、医療・制御・計算機科学において中心的な問題である。
医療においては投薬・手術・放射線といった介入が患者に適用される順序が
治療成績を決定的に左右する \[Murphy, 2003\]。
この順序依存性の数学的構造は、従来の因果推論の枠組み \[Pearl, 2000\] では
介入効果の記述は可能であるが、**微分可能な最適化問題への接続が欠如している**。

本稿はこのギャップを以下の三つの数学的道具によって埋める：
(i) 非可換モノイドによる介入の代数的構造化、
(ii) Sobolev 空間としての MEDICUS 空間の定式化、
(iii) Mollifier によるフレシェ微分可能な $C^\infty$ 近似。

### 1.2 本稿の構成と主要結果

**Layer 1（介入代数）：** §2 において、医療介入集合の非可換モノイド構造を示す。
半群論・圏論による深化を §2.3〜§2.4 に置く。

**Layer 2（MEDICUS 空間）：** §3 において、
MEDICUS 最小空間が $W^{1,\infty}(\Omega)$ と一致する Banach 空間であることを示す。
変分法による連続時間拡張・最適輸送への展望を §3.4〜§3.5 に置く。

**Layer 3（Mollifier と微分可能化）：** §4 において、
フレシェ微分可能性を保証する Mollifier 定理を示し（定理 2）、
数値計算（自動微分）との接続を与える。

**§5 以降は将来の拡張候補** であり、現時点では概念的スケッチにとどめる。

---

## 2. 介入代数の深化

### 2.1 基本設定（v3 より）

**定義 1（患者状態空間）：**
患者の状態空間を $\mathcal{P}$ とする。

**定義 2（医療介入）：**
医療介入とは写像 $E: \mathcal{P} \to \mathcal{P}$ であり、全体を $\mathcal{E}$ と書く。

**定義 3（介入の合成）：**
$(E_a \circ E_b)(p) := E_a(E_b(p))$。

**定理 M（非可換モノイド）：**
$(\mathcal{E}, \circ)$ は非可換モノイドを形成する（v3 §2.2 の証明を参照）。

**命題 1（群ではないこと）：**
医療介入の不可逆性から逆元が存在しないため、$(\mathcal{E}, \circ)$ は群ではない。

---

### 2.2 半群論による Layer 1 の深化

非可換モノイドの内部構造をさらに分析するために半群論の道具を導入する。

**定義 4（交換可能ペア）：**
$E_a, E_b \in \mathcal{E}$ が**交換可能**であるとは $E_a \circ E_b = E_b \circ E_a$ が成立することをいう。

**定義 5（中心化部分モノイド）：**
$\mathcal{E}$ の**中心** $Z(\mathcal{E}) := \{E \in \mathcal{E} \mid \forall E' \in \mathcal{E},\ E \circ E' = E' \circ E\}$。

**命題 2（臨床的意味）：**
$E_a, E_b$ が交換可能 $\Leftrightarrow$ 「$E_a$ の効果が $E_b$ の事前適用に依存しない」かつ逆も然り。
$Z(\mathcal{E})$ の要素は「どの段階でも安全に適用できる介入」に対応する。

**Remark 3（Green の関係と将来課題）：**
半群論の Green の関係 $\mathcal{R}, \mathcal{L}, \mathcal{J}$ を $\mathcal{E}$ に適用することで、
「同等のアウトカムを達成する介入列の同値類」を代数的に記述できる。
例えば $E_a \mathcal{R} E_b \Leftrightarrow E_a \circ \mathcal{E} = E_b \circ \mathcal{E}$（右イデアルの一致）は
「$E_a$ と $E_b$ を先頭に置いた場合に到達可能な状態集合が等しい」ことを意味し、
臨床的に同値なプロトコルのクラスタリングに使える。形式化は今後の課題とする。

---

### 2.3 圏論的定式化

**定義 6（介入圏 $\mathbf{Med}$）：**
以下のデータからなる圏 $\mathbf{Med}$ を定義する：
- **対象：** 患者状態空間の部分集合（病期・年齢層・臓器機能クラス等で層別）
- **射：** $A \xrightarrow{E} B$：状態クラス $A$ の患者に介入 $E$ を適用すると状態クラス $B$ に移行する
- **合成：** 写像の合成
- **恒等射：** 恒等写像（介入なし）

**命題 3（モノイドと圏の対応）：**
対象が 1 つの場合、$\mathbf{Med}$ は非可換モノイド $(\mathcal{E}, \circ)$ と一致する。
圏論的定式化は対象（患者層）を複数に増やすことで**一般化**を与える。

**定義 7（プロトコル関手）：**
2 つの治療プロトコル体系 $\mathbf{Med}_1, \mathbf{Med}_2$ の間の**関手**（functor）
$F: \mathbf{Med}_1 \to \mathbf{Med}_2$ は介入の「翻訳」または「近似」を表す。

**Remark 4（圏論の利点）：**
圏論的定式化により次が可能になる：
(i) 異なる治療体系の比較（関手の存在）、
(ii) 「本質的に同じ」プロトコルの同定（自然変換による同値）、
(iii) 図式的表現——介入の合成を「配線図」として視覚化でき、論文中の図解に使える。

---

### 2.4 因果圏との接続（将来展望）

Coecke \& Kissinger \[2017\] が量子情報向けに開発した**プロセス理論**（因果圏）は、
「入力 → プロセス → 出力」をコンパクトな図式で表現する枠組みである。

MEDICUS への応用として：
- 介入を「入力状態の確率分布 → 出力状態の確率分布」のプロセスとして定式化
- Pearl の do-calculus の操作（介入分布 $P(Y \mid do(X))$）をプロセス圏の射として表現
- 非可換性 $E_a \circ E_b \neq E_b \circ E_a$ が図式の**配線の非交換性**として視覚的に現れる

**この方向が重要な理由：**
Pearl の do-calculus は「介入効果の予測」には強力だが、
「どの介入列を選ぶか」という最適化問題に直接は接続できない。
MEDICUS 空間上でのフレシェ微分可能化（§4）と因果圏を組み合わせることで、
因果推論から最適化への橋渡しが構造的に与えられる可能性がある。
本稿ではこれを将来課題として位置づける。

---

## 3. MEDICUS 関数空間の深化

### 3.1 最小 MEDICUS 空間と Sobolev 空間の同一性

**定義 8（最小 MEDICUS 空間・v3 より）：**
$$\mathcal{M}_0(\Omega) := C^1(\overline{\Omega}), \quad \|f\|_{\mathcal{M}_0} := \|f\|_\infty + \|\nabla f\|_\infty$$

**命題 4（Sobolev 空間との一致）：**
$$\mathcal{M}_0(\Omega) \cong W^{1,\infty}(\Omega) \cap C(\overline{\Omega})$$

すなわち MEDICUS 最小ノルムは Sobolev ノルム $W^{1,\infty}$ と等価である。

**この同定が重要な理由：**
$W^{1,\infty}$ に対しては次の豊富な定理群が即座に利用可能になる：
- **Sobolev 埋め込み定理：** $W^{1,\infty}(\Omega) \hookrightarrow C^{0,1}(\overline{\Omega})$（Lipschitz 連続性）
- **Rellich-Kondrachov の定理：** コンパクト埋め込みの存在
- **Morrey の不等式：** $\|f\|_{C^{0,\alpha}} \leq C \|f\|_{W^{1,p}}$（Hölder 正則性）

**定理 1（Banach 空間）：**
$(\mathcal{M}_0(\Omega), \|\cdot\|_{\mathcal{M}_0})$ は Banach 空間である（v3 §3.2 の証明参照）。

---

### 3.2 高階 Sobolev 空間への拡張

**定義 9（高階 MEDICUS 空間）：**
$k \geq 1$ に対し：
$$\mathcal{M}_k(\Omega) := W^{k,\infty}(\Omega) = \{f \in L^\infty \mid D^\alpha f \in L^\infty,\ |\alpha| \leq k\}$$
$$\|f\|_{\mathcal{M}_k} := \sum_{|\alpha| \leq k} \|D^\alpha f\|_\infty$$

**命題 5（包含関係）：**
$$\mathcal{M}_0 \supset \mathcal{M}_1 \supset \mathcal{M}_2 \supset \cdots \supset C^\infty(\overline{\Omega})$$

**Remark 5（高階微分の臨床的意味）：**
$k = 1$：介入量の変化率が制御される（急激な用量変更がない）。
$k = 2$：変化率の変化率が制御される（治療強度の加速・減速が滑らか）。
高次の Sobolev 空間で最適化することは、治療プロトコルの**変動の激しさそのものに制約を課す**ことに対応する。
テイラー展開の高階項は C∞ 空間では理論的に定義されるが、
Mollifier が「コンパクトサポート・非解析的」であるおかげで
遠方の状態への根拠のない外挿が防がれる——これは臨床的安全性の数学的表現でもある。

---

### 3.3 ノルムの拡張（未解決事項・v3 より継承）

**注意（Shannon エントロピーのノルム問題）：**
$S(f) = -\sum_i p_i \ln p_i$ は凹関数であり三角不等式を一般に満たさない。
制約違反ペナルティ・エントロピー項は目的関数 $J(\theta)$ に置く（§5 参照）。

---

### 3.4 変分法による連続時間拡張（将来展望）

現状の MEDICUS 空間は「パラメータ空間上の関数」を扱う。
これを時間連続な治療計画へ拡張するには変分法の枠組みが自然である。

**問題設定（スケッチ）：**
時刻 $t \in [0, T]$ における介入強度 $\theta(t)$ を経路として最適化する：

$$\theta^* = \arg\min_{\theta \in \mathcal{M}_0([0,T])} J[\theta] = \int_0^T L(\theta(t), \dot\theta(t), t)\, dt$$

ここで $L$ はラグランジアン（アウトカムコスト + 正則化）。

**Euler-Lagrange 方程式：**
$$\frac{\partial L}{\partial \theta} - \frac{d}{dt}\frac{\partial L}{\partial \dot\theta} = 0$$

がアウトカム最適な治療経路の必要条件となる。
Mollifier により $\theta$ が $C^\infty$ に近似されていれば、
$\dot\theta$ が存在し Euler-Lagrange 方程式の導出が正当化される。

---

### 3.5 最適輸送理論との接続（将来展望）

個別患者ではなく**患者集団**を対象にする場合、
状態を確率測度 $\mu \in \mathcal{P}(\mathcal{P})$ として扱うのが自然である。

- 介入 $E$ は測度の押し出し $E_\# \mu$（push-forward）として定式化
- 治療前後の状態分布の「近さ」を **Wasserstein 距離** $W_2(\mu, \nu)$ で定量化
- 最適な集団レベル介入 = 輸送コスト最小化問題

**MEDICUS との接続点：**
Wasserstein 空間 $(\mathcal{P}_2(\mathcal{P}), W_2)$ は Riemannian 構造を持ち、
「勾配流（gradient flow）」として最適輸送問題が解ける。
Mollifier による C∞ 化がここでも活きる——滑らかな確率密度への近似が
Wasserstein 勾配流の解析を可能にするからである。

---

## 4. Mollifier とフレシェ微分可能化

### 4.1 フレシェ微分 vs ガトー微分（本稿での位置づけ）

**定義 10（ガトー微分）：**
方向 $v$ を固定して：
$$dF(x)[v] = \lim_{t \to 0} \frac{F(x + tv) - F(x)}{t}$$

**定義 11（フレシェ微分）：**
有界線形作用素 $A: X \to Y$ が存在して：
$$\lim_{\|h\| \to 0} \frac{\|F(x+h) - F(x) - A(h)\|}{\|h\|} = 0$$

**命題 6（包含関係）：**
フレシェ微分可能 $\Rightarrow$ ガトー微分可能（逆は一般に成立しない）。

**Remark 6（連鎖律の成立条件）：**
偏微分（ガトー） vs 全微分（フレシェ）の関係に完全に対応する。
ガトー微分のみ存在しても連鎖律が成立しない反例が存在する。
**Newton 法の二次収束証明は連鎖律に依存するため、フレシェ微分可能性の保証が必須。**
これが Mollifier を「単なる平滑化」ではなく「最適化の正当化」として位置づける根拠である。

---

### 4.2 MEDICUS 空間での Mollifier 定理（v3 より）

**定義 12（標準 Mollifier \[Friedrichs, 1944\]）：**
$$\phi_\varepsilon(x) = \varepsilon^{-n}\phi(x/\varepsilon), \quad \phi(x) = \begin{cases} C\exp\!\left(-\dfrac{1}{1-\|x\|^2}\right) & \|x\| < 1 \\ 0 & \|x\| \geq 1 \end{cases}$$

$\phi_\varepsilon$ はコンパクトサポートを持つ $C^\infty$ 関数であり、かつ**非解析的**である
（テイラー級数が $\|x\| \geq 1$ まで到達しない）。

**定理 2（MEDICUS 空間内の $C^\infty$ 近似）：**
$f \in \mathcal{M}_0(\Omega)$ に対し $f_\varepsilon := f * \phi_\varepsilon^{\mathcal{C}}$ は：
1. $f_\varepsilon \in C^\infty(\Omega_{\mathcal{C}})$
2. $\|f_\varepsilon - f\|_{\mathcal{M}_0} \to 0$ as $\varepsilon \to 0$

**系 2（フレシェ微分可能性）：**
定理 2 より $f_\varepsilon \in C^\infty$ であるから $f_\varepsilon$ はフレシェ微分可能であり、
連鎖律が成立する。したがって勾配ベース最適化（Newton 法・Adam 等）の
適用が数学的に正当化される。

---

### 4.3 計算実装：自動微分との接続

コンピュータ上での微分には三種類ある：

| 種別 | 方法 | 精度 | MEDICUS での位置づけ |
|---|---|---|---|
| 数値微分 | $(f(x+h)-f(x))/h$ | 近似（$O(h)$ 誤差） | 検証用のみ |
| 自動微分（AD） | 連鎖律を計算グラフで実装 | 機械精度（誤差なし） | **実装の主手段** |
| 記号微分 | 式の代数的操作 | 厳密 | Lean 4 形式化に対応 |

**Haskell での実装（`ad` パッケージ）：**
```haskell
import Numeric.AD

-- f_ε の勾配（フレシェ微分の有限次元近似）
gradient f_eps [theta1, theta2, ..., thetaN]
-- → [∂f_ε/∂θ₁, ..., ∂f_ε/∂θₙ]（機械精度で正確）
```

$f_\varepsilon$ が $C^\infty$（定理 2）であることにより、
AD が計算する連鎖律の各ステップが数学的に正当であることが保証される。
これは「Mollifier がなぜ必要か」の実装レベルでの答えでもある。

---

## 5. 最適化フレームワーク

### 5.1 最適化問題の定式化

$$\theta^* = \arg\min_{\theta \in \mathcal{M}_0(\Omega)} J(\theta), \quad J(\theta) := L(\theta) + \lambda V_{\mathcal{C}}(\theta) + \mu S(\theta)$$

制約・エントロピー項はノルムではなく目的関数の一部として扱う（§3.3 の問題を回避）。

### 5.2 二段階最適化

**Phase 1（大域探索）：Adam / AdaGrad**
- 運動量項によりランダム性を持ちつつ局所解を脱出
- $C^\infty$ 保証によりすべてのステップで勾配が存在

**Phase 2（精密収束）：Newton 法**
- 系 2 のフレシェ微分可能性により $\nabla^2 J$ が存在
- 二次収束：$\|\theta_{k+1} - \theta^*\| \leq \frac{L}{2\mu}\|\theta_k - \theta^*\|^2$

**Remark 7（Sobolev 空間による収束評価の精密化）：**
$\mathcal{M}_0 = W^{1,\infty}$ の認識により、
Newton 法の収束定数 $L/2\mu$ を Sobolev 埋め込み定数を通じて
介入パラメータの具体的な値から評価できる。これは v3 からの改善点である。

---

## 6. 今後の課題

### 優先度：高（論文核心）

1. **Lean 4 形式化：**
   `instance : Monoid MedicalIntervention` → `theorem noncomm_exists` →
   `theorem medicus_norm_is_norm` → `theorem medicus_space_banach`

2. **非可換性の定量的評価：**
   $\|E_a \circ E_b - E_b \circ E_a\|_{\mathcal{M}_0}$ の下限を導出

3. **Sobolev 埋め込みの明示的利用：**
   収束定数の具体的評価

### 優先度：中（拡張論文候補）

4. **半群論：Green の関係による介入の同値類分類**
5. **圏論：介入圏 $\mathbf{Med}$ の公理的定式化と関手の構成**
6. **変分法：連続時間治療計画の Euler-Lagrange 方程式**

### 優先度：低（将来方向）

7. **最適輸送：患者集団レベルへの拡張（Wasserstein 勾配流）**
8. **因果圏：Pearl の do-calculus との圏論的接続**
9. **生理学的モデルとの統合：PK/PD モデルを介入関数 $E$ に組み込む**

---

## References

\[Coecke & Kissinger, 2017\] Coecke, B., & Kissinger, A. *Picturing Quantum Processes*. Cambridge University Press.

\[Evans, 2010\] Evans, L. C. *Partial Differential Equations* (2nd ed.). American Mathematical Society.

\[Friedrichs, 1944\] Friedrichs, K. O. The identity of weak and strong extensions of differential operators. *Trans. Amer. Math. Soc.*, 55(1), 132–151.

\[Murphy, 2003\] Murphy, S. A. Optimal dynamic treatment regimes. *J. Roy. Statist. Soc. Ser. B*, 65(2), 331–355.

\[Nocedal & Wright, 2006\] Nocedal, J., & Wright, S. J. *Numerical Optimization* (2nd ed.). Springer.

\[Pearl, 2000\] Pearl, J. *Causality: Models, Reasoning, and Inference*. Cambridge University Press.

\[Sobolev, 1938\] Sobolev, S. L. On a theorem of functional analysis. *Mat. Sbornik*, 4(3), 471–497.

\[Villani, 2009\] Villani, C. *Optimal Transport: Old and New*. Springer.
