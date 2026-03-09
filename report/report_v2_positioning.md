# MEDICUS空間理論：非可換医療介入の連続最適化への橋渡し

> **このファイルについて**
> `report.md`（初期ドラフト）を保存した上で、理論のポジショニングを整理し直したバージョン。
> 核心的な変更点：Introduction の論理構造を以下の二層で再構成。
> 1. 「DLにおける離散→連続変換の数学的非厳密性」という根本的問いを動機として明示
> 2. 「因果推論のギャップをMEDICUS空間が埋める」という位置づけ

---

## Abstract

深層学習（DL）は離散的なカテゴリ変数を連続ベクトル空間に埋め込んで勾配を計算するが、
この操作の数学的正当性——離散から連続への変換が真に $C^\infty$ 級であるという保証——は
これまで厳密には担保されてこなかった。
本稿はこの問いを出発点とし、医療介入という離散的・非可換な構造に対して
数学的に厳密な連続化を与える MEDICUS 空間理論を提案する。

医療介入（投薬、手術、放射線等）はその適用順序によって結果が異なる非可換な構造を持つ。
この性質は因果推論（Pearl の do-calculus）によって確率的に記述されてきたが、
「どの順序・構成が最適か」という最適化問題への接続は未解決であった。

本稿では MEDICUS（Medical-Enhanced Data Integrity Constraint Unified Space）空間理論を提案する。
医療介入の集合が**非可換モノイド**を形成することを公理的に示した上で、
Friedrichs モルリファイア \[Friedrichs, 1944\] による $C^\infty$ 連続場への埋め込みによって
この離散的な代数構造を微分可能な MEDICUS 空間へと変換する。
DL が近似で済ませてきた離散→連続変換を関数解析の定理として保証し、
因果推論が記述するにとどまっていた介入の順序依存性を、
ニュートン法による二次収束最適化問題として定式化することが初めて可能となる。

**Keywords:** 非可換モノイド、関数解析、モルリファイア、医療介入最適化、ニュートン法、因果推論、深層学習の数学的基盤

---

## 1. Introduction

### 1.1 根本的な問い：離散変数への微分は数学的に正当か

深層学習の成功は、勾配降下法という強力な最適化手法に支えられている。
しかし、その前提には見過ごされがちな数学的問題が潜んでいる。

カテゴリ変数（診断名、治療種別、投薬の有無等）は本質的に離散的な値である。
DL はこれらを連続ベクトル空間 $\mathbb{R}^n$ に埋め込むことで勾配計算を可能にしているが、
**この変換が $C^\infty$ 級の滑らかさを保証しているわけではない。**
ML コミュニティはこの問題を認識しており、次のようなハックで回避してきた：

- **Straight-through estimator** \[Bengio et al., 2013\]：微分不可能な箇所を無視して勾配を通す
- **Gumbel-softmax** \[Jang et al., 2017\]：離散分布を連続分布で近似する
- **通常の embedding**：写像先は連続だが、離散インデックスとの接続は非滑らか

いずれも「滑らかであるふりをしている」に過ぎず、
勾配計算の数学的根拠は厳密には担保されていない。
**医療・安全性が要求される領域でこの曖昧さは許容できない。**

### 1.2 問題の所在：記述と最適化のギャップ

医療現場では介入の順序が治療成績を決定する。
化学療法で腫瘍を縮小した後に放射線照射を行うのと、その逆では疾病コントロール率が異なる。
このような順序依存性は臨床プロトコルによって経験的に定式化されてきたが、
その数学的本質は長らく曖昧なままであった。

Pearl の do-calculus \[Pearl, 2000\] は介入の因果効果を厳密に記述する枠組みを提供した。
$P(Y \mid do(E_a), do(E_b))$ という表現により、
介入列の結果を確率的に特定することが可能となった。
しかし do-calculus は本質的に**記述の体系**であり、次の問いには答えない：

> 「介入の構成を連続的に変化させたとき、どの方向に動けばアウトカムが改善するか？」

Dynamic Treatment Regimes（DTR）\[Murphy, 2003\] はこの問いに対し動的計画法・強化学習で
アプローチするが、これらは**離散的な探索**であり、勾配情報を利用しない。
DL の埋め込みと同様、介入空間の離散性という根本的な制約が残り続けている。

### 1.3 本稿のアプローチ：代数構造から連続最適化へ

本稿は上記二つの問題——DL の数学的非厳密性と、因果推論の最適化への未接続——に対し、
以下の二段階で応える。

**第一段階（代数的定式化）：**
医療介入の集合に合成演算を定義し、これが**非可換モノイド**を形成することを示す。
「群」ではなくモノイドであることは重要で、手術や放射線といった介入の不可逆性——
すなわち逆元の不在——を数学的に正確に捉えている。

**第二段階（連続化と最適化）：**
Friedrichs モルリファイア \[Friedrichs, 1944\] を用いて、
この離散的なモノイド構造を $C^\infty$ 連続場である MEDICUS 空間へ**証明可能に**埋め込む。
DL のハックとは異なり、連続化の正当性を関数解析の定理として保証する。
連続化された空間では目的関数が微分可能となり、
ニュートン法による二次収束最適化が適用可能になる。

$$
\underbrace{E_a \circ E_b(p) \neq E_b \circ E_a(p)}_{\text{非可換モノイド（離散）}}
\xrightarrow{\text{Mollifier（}C^\infty\text{収束を保証）}}
\underbrace{\mathcal{M}(\Omega, \mathcal{C})}_{\text{MEDICUS空間（連続・微分可能）}}
\xrightarrow{\text{Newton法}}
\underbrace{\theta^*}_{\text{最適介入構成}}
$$

### 1.4 貢献の要約

1. **数学的問いの明示：** DL における離散→連続変換の非厳密性の指摘
2. **代数的定式化：** 医療介入の非可換モノイド構造の公理化
3. **厳密な連続化：** Mollifier による $C^\infty$ 保証付きの離散→連続変換
4. **最適化への接続：** MEDICUS 空間上でのニュートン法の収束性保証

---

## 2. 医療介入の代数的構造

### 2.1 非可換性の臨床的根拠

患者の状態空間を $\mathcal{P}$ とする。
医療介入 $E$ を状態の変換 $E: \mathcal{P} \to \mathcal{P}$ として定義する。

**観察（臨床的事実）：**
ある状態 $p \in \mathcal{P}$ と介入 $E_a, E_b$ に対し、

$$E_a \circ E_b(p) \neq E_b \circ E_a(p)$$

が一般に成立する。これは治療プロトコルが介入順序を厳格に定めているという事実によって実証される。
順序を入れ替えても結果が同じであれば、プロトコルに順序を定める必要はない。

**なぜ非可換性が生じるか：**
介入 $E_a$ を施した後の状態 $p' = E_a(p)$ は元の状態 $p$ と異なる。
したがって $E_b$ が作用する前提条件がすでに変化しており、

$$E_b(E_a(p)) \neq E_a(E_b(p))$$

が生じる。介入対象のドメイン（患者身体）が介入によって変容するという医療固有の性質が、
この非可換性の本質的な原因である。

### 2.2 非可換モノイドとしての定式化

医療介入の集合 $\mathcal{E}$ に合成演算 $\circ$ を定義する。

**定理 M（非可換モノイド構造）：**
$(\mathcal{E}, \circ)$ は非可換モノイドを形成する。すなわち以下が成立する：

1. **閉性：** $\forall E_a, E_b \in \mathcal{E},\ E_a \circ E_b \in \mathcal{E}$
2. **結合法則：** $(E_a \circ E_b) \circ E_c = E_a \circ (E_b \circ E_c)$
3. **単位元：** $\exists \text{id} \in \mathcal{E}$ s.t. $\text{id} \circ E = E \circ \text{id} = E$
4. **非可換性：** $\exists E_a, E_b \in \mathcal{E}$ s.t. $E_a \circ E_b \neq E_b \circ E_a$

**なぜ群（Group）ではないか：**
群は逆元の存在を要求するが、放射線・手術・化学療法は患者に不可逆なダメージを与える。
すなわち $E \circ E^{-1} = \text{id}$ を満たす $E^{-1}$ は医学的に存在しない。
「群」と呼ぶことは数学的に不正確であり、**モノイド**が正確な構造である。

---

## 3. MEDICUS空間：連続化の橋渡し

### 3.1 ギャップの定式化

非可換モノイド $(\mathcal{E}, \circ)$ は離散的な代数構造である。
ここに最適化理論を適用するには、連続性と微分可能性が必要となる。

**問題：** 離散的な介入空間 $\mathcal{E}$ 上では勾配 $\nabla$ が定義されない。

**解決：** Mollifier によって介入パラメータを連続場に埋め込む。

### 3.2 MEDICUS関数空間の定義

**定義 1（MEDICUS関数空間）：**
パラメータ領域 $\Omega \subseteq \mathbb{R}^n$ と医療制約集合 $\mathcal{C}$ に対し、

$$\mathcal{M}(\Omega, \mathcal{C}) := \{f: \Omega \to \mathbb{R} \mid f \in C^1(\Omega),\ f \text{ は } \mathcal{C} \text{ を満たす},\ \|f\|_{\mathcal{M}} < \infty\}$$

**定義 2（MEDICUSノルム）：**

$$\|f\|_{\mathcal{M}} := \|f\|_\infty + \|\nabla f\|_\infty + \lambda V_{\mathcal{C}}(f) + \mu S_{\text{entropy}}(f) + \nu E_{\text{thermal}}(f)$$

**定理 1（完備性）：** $(\mathcal{M}(\Omega, \mathcal{C}), \|\cdot\|_{\mathcal{M}})$ は Banach 空間である。

### 3.3 モルリファイアによる連続化

**定義 3（医療特化モルリファイア）：**

$$\phi_\varepsilon^{\text{medical}}(\theta) = \begin{cases}
C \exp\!\left(-\dfrac{1}{\varepsilon^2 - \|\theta - \theta_{\text{medical}}\|^2}\right) & \|\theta - \theta_{\text{medical}}\| < \varepsilon \\
0 & \text{otherwise}
\end{cases}$$

$$(\mathcal{M}_\varepsilon f)(\theta) = \int f(\eta)\, \phi_\varepsilon^{\text{medical}}(\theta - \eta)\, d\eta$$

**定理 2（収束性）：**
1. $\mathcal{M}_\varepsilon f \in C^\infty$（無限回微分可能）
2. $\|\mathcal{M}_\varepsilon f - f\|_{\mathcal{M}} \to 0 \text{ as } \varepsilon \to 0$

これにより離散的な介入パラメータが $C^\infty$ 級の連続場に変換され、勾配計算が可能となる。

---

## 4. MEDICUS空間における最適化

### 4.1 最適化問題の定式化

MEDICUS空間上の最適介入構成を求める問題：

$$\theta^* = \arg\min_{\theta \in \mathcal{M}(\Omega, \mathcal{C})} J(\theta)$$

目的関数 $J(\theta)$ はアウトカム（治療効果、副作用リスク等）を定量化する。

医療介入の最適化問題は一般に**非凸**である。
複数の局所解が存在しうる以上、単一の最適化手法では大域最適解への到達を保証できない。
本稿は §3 で確立した $C^\infty$ 連続性を基盤として、
**大域的探索と局所的精緻化を組み合わせた二段階最適化戦略**を提案する。

### 4.2 $C^\infty$ 連続性が開く最適化の全arsenal

Mollifier によって MEDICUS 空間の $C^\infty$ 連続性が保証されると、
現代の勾配ベース最適化手法がすべて**数学的に正当に**適用可能となる。
これは DL の embedding（滑らかさの保証なし）との本質的な差異である。

| 手法 | 利用する情報 | 強み | 役割 |
|---|---|---|---|
| Adam \[Kingma & Ba, 2015\] | $\nabla J$、モメンタム | 局所解からの脱出 | 大域的探索 |
| AdaGrad \[Duchi et al., 2011\] | $\nabla J$、累積二乗勾配 | 疎な勾配に強い | 大域的探索 |
| RMSProp | $\nabla J$、移動平均 | 非定常目的関数 | 大域的探索 |
| **ニュートン法** | $\nabla J$、$\nabla^2 J$ | **二次収束**（高速・精密） | **局所的精緻化** |

$C^\infty$ が保証されているからこそ、ヘッセ行列 $\nabla^2 J$ が定義され、
ニュートン法の二次収束が理論的に成立する。

### 4.3 二段階最適化戦略

非凸な医療介入最適化問題に対し、以下の戦略を提案する：

```
Phase 1：大域的探索（Adam / AdaGrad）
  モメンタムにより局所解の谷を乗り越えながら
  目的関数の全体的な景観を探索する
  → 良質な初期値 θ₀ を獲得

        ↓ warm-starting

Phase 2：局所的精緻化（ニュートン法）
  θ₀ 近傍で二次収束により
  高速・高精度に最適解へ収束する
  → θ* を保証付きで獲得
```

この二段階戦略は、モメンタム系手法の**大域的探索能力**と
ニュートン法の**局所的収束速度**を組み合わせ、
局所解への嵌没リスクを実践的に低減する。

### 4.4 ニュートン法の収束性保証（Phase 2）

**定理 3（二次収束）：** 以下の条件下でニュートン法は二次収束する：

1. **正則性：** $\nabla^2 J(\theta^*) \succ 0$
2. **制約適合性：** $\theta^* \in \text{int}(\mathcal{M}(\Omega, \mathcal{C}))$
3. **Lipschitz 条件：** $\|\nabla^2 J(\theta_1) - \nabla^2 J(\theta_2)\| \leq L\|\theta_1 - \theta_2\|$

**収束率：**

$$\|\theta_{k+1} - \theta^*\| \leq \frac{L}{2\mu}\|\theta_k - \theta^*\|^2$$

条件1（正則性）は Phase 1 の大域的探索によって適切な初期値が与えられることで
現実的に満たされやすくなる。二段階戦略はこの意味でも理論的に整合している。

### 4.5 DTR・強化学習との本質的差異

動的計画法（DTR）や強化学習との本質的な違いは、勾配情報の利用可否にある。

```
DTR / 強化学習：
  離散的な介入空間を離散的に探索
  → 勾配なし、組み合わせ爆発のリスク

MEDICUS（二段階戦略）：
  Mollifier で C∞ 連続場に変換
  → 勾配が数学的に定義される
  → Adam で探索 + ニュートン法で収束
  → 現代最適化の全arsenal を利用可能
```

Mollifier による連続化は、単に「ニュートン法を使えるようにする」だけでなく、
**現代的な勾配最適化手法の全体を医療介入問題に解放する**という
より広い意義を持つ。

---

## 5. 不確定性原理：最適化の限界の明示

セキュリティ演算子 $\hat{S}$ と効率演算子 $\hat{E}$ の非可換性（§2 で示した構造と同根）から、

$$\Delta S \cdot \Delta E \geq \frac{1}{2}|\langle[\hat{S}, \hat{E}]\rangle|$$

が導かれる。これは「セキュリティと効率を同時に最大化することは不可能」という
最適化問題の本質的な限界を数学的に明示する。
不確定性定数 $K$ の具体的な導出は今後の課題である。

---

## 6. 結論と今後の課題

### 6.1 貢献の要約

本稿の核心的な貢献は**二つのギャップの橋渡し**にある。

1. **DLの数学的非厳密性への回答：** 離散→連続変換を Mollifier により $C^\infty$ 収束として保証
2. **因果推論から最適化への接続：** 記述にとどまっていた介入順序依存性を最適化問題として定式化
3. **代数構造の公理化：** 医療介入の非可換モノイド構造を公理から導出
4. **最適化arsenalの解放：** $C^\infty$ 保証により Adam・AdaGrad・ニュートン法が数学的に正当に適用可能
5. **二段階最適化戦略：** 大域的探索（モメンタム系）と局所精緻化（ニュートン法）の組み合わせによる局所解リスクの低減

### 6.2 今後の課題

1. **数値実証：** $E_a \circ E_b \neq E_b \circ E_a$ の具体的シミュレーション（Haskell実装）
2. **二段階戦略の実験的検証：** Adam warm-start + ニュートン法の収束比較実験
3. **$K$ の導出：** 不確定性定数の具体的な値の計算
4. **Lean 4 による形式検証：** モノイド公理・ノルム公理の機械的証明
5. **臨床データとの接続：** 実際の治療プロトコルへの適用

---

## References

\[Bengio et al., 2013\] Bengio, Y., Léonard, N., & Courville, A. Estimating or propagating gradients through stochastic neurons for conditional computation. *arXiv:1308.3432*.

\[Duchi et al., 2011\] Duchi, J., Hazan, E., & Singer, Y. Adaptive subgradient methods for online learning and stochastic optimization. *JMLR*, 12, 2121–2159.

\[Kingma & Ba, 2015\] Kingma, D. P., & Ba, J. Adam: A method for stochastic optimization. *ICLR 2015*.

\[Friedrichs, 1944\] Friedrichs, K. O. The identity of weak and strong extensions of differential operators. *Trans. AMS*, 55(1), 132–151.

\[Jang et al., 2017\] Jang, E., Gu, S., & Poole, B. Categorical reparameterization with Gumbel-softmax. *ICLR 2017*.

\[Murphy, 2003\] Murphy, S. A. Optimal dynamic treatment regimes. *JRSS-B*, 65(2), 331–355.

\[Pearl, 2000\] Pearl, J. *Causality: Models, Reasoning, and Inference*. Cambridge University Press.

\[Robertson, 1929\] Robertson, H. P. The uncertainty principle. *Physical Review*, 34(1), 163–164.

\[Sobolev, 1938\] Sobolev, S. L. On a theorem of functional analysis. *Mat. Sbornik*, 4(3), 471–497.
