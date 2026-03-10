"""
uncertainty.py
==============
不確定性原理の視覚化

ΔS · ΔE ≥ ½|⟨[Ŝ, Ê]⟩|

- セキュリティ（S）と効率（E）の不確定性の境界
- 「完璧な統治は不可能」という数学的限界の景観
- 最小不確定性状態（最良のバランス点）の可視化
"""

import numpy as np
import matplotlib.pyplot as plt
import japanize_matplotlib
from pathlib import Path

IMG_DIR = Path(__file__).parent / "img"
IMG_DIR.mkdir(exist_ok=True)


# ── 図1：不確定性境界と実現可能領域 ──────────────────────────────────────────

def plot_uncertainty_boundary():
    """
    横軸：ΔS（セキュリティの不確定性）
    縦軸：ΔE（効率の不確定性）
    境界曲線：ΔS · ΔE = K（達成不可能な境界）
    """
    K = 0.05  # 不確定性下限（仮の値、要導出）

    delta_S = np.linspace(0.01, 1.0, 500)
    boundary = K / delta_S  # ΔE = K / ΔS

    fig, ax = plt.subplots(figsize=(8, 7))

    # 禁止領域（境界より下）
    ax.fill_between(delta_S, 0, boundary,
                    where=(boundary <= 1.0),
                    alpha=0.15, color="#F44336",
                    label="禁止領域：数学的に達成不可能")

    # 実現可能領域（境界より上）
    ax.fill_between(delta_S, np.minimum(boundary, 1.0), 1.0,
                    alpha=0.08, color="#2196F3",
                    label="実現可能領域")

    # 境界曲線
    mask = boundary <= 1.2
    ax.plot(delta_S[mask], boundary[mask], "-",
            color="#F44336", linewidth=3,
            label=r"不確定性境界：$\Delta S \cdot \Delta E = K$")

    # 最小不確定性状態（境界上で ΔS = ΔE = √K）
    min_unc = np.sqrt(K)
    ax.plot(min_unc, min_unc, "*", color="#FF6F00",
            markersize=18, zorder=5,
            label=f"最小不確定性状態\n(ΔS = ΔE = √K ≈ {min_unc:.3f})")
    ax.annotate(
        f"最良のバランス点\nΔS = ΔE = {min_unc:.3f}",
        xy=(min_unc, min_unc),
        xytext=(min_unc + 0.15, min_unc + 0.12),
        arrowprops=dict(arrowstyle="->", color="#FF6F00", lw=1.5),
        fontsize=10, color="#FF6F00"
    )

    # いくつかの「実際の運用点」を例示
    operating_points = [
        (0.1, 0.8,  "高セキュリティ\n低効率"),
        (0.7, 0.15, "低セキュリティ\n高効率"),
        (0.35, 0.35, "バランス型"),
    ]
    for ds, de, label in operating_points:
        ax.scatter(ds, de, s=120, zorder=5, color="#4CAF50")
        ax.annotate(label, xy=(ds, de), xytext=(ds + 0.04, de + 0.04),
                    fontsize=8.5, color="#2E7D32")

    ax.set_xlim(0, 0.8)
    ax.set_ylim(0, 0.8)
    ax.set_xlabel("ΔS（セキュリティの不確定性）", fontsize=12)
    ax.set_ylabel("ΔE（効率の不確定性）", fontsize=12)
    ax.set_title(
        "MEDICUS 不確定性原理\n"
        r"$\Delta S \cdot \Delta E \geq \frac{1}{2}|\langle[\hat{S},\hat{E}]\rangle| = K$",
        fontsize=13
    )
    ax.legend(fontsize=9, loc="upper right")
    ax.grid(True, alpha=0.3)

    # 物理的直感の注釈
    ax.text(0.42, 0.55,
            "どれだけ努力しても\nこの境界は越えられない",
            fontsize=10, color="#C62828",
            bbox=dict(boxstyle="round,pad=0.4", facecolor="#FFEBEE", alpha=0.8))

    plt.tight_layout()
    out = IMG_DIR / "07_uncertainty_boundary.png"
    plt.savefig(out, dpi=200, bbox_inches="tight")
    plt.close()
    print(f"保存: {out}")


# ── 図2：非可換性と不確定性の関係 ────────────────────────────────────────────

def plot_commutator_uncertainty():
    """
    交換子 [Ŝ, Ê] の大きさと不確定性下限の関係を示す。
    非可換性が強いほど不確定性も大きい。
    """
    # 交換子の強さをパラメータ化
    commutator_strength = np.linspace(0, 1.0, 100)
    K_values = commutator_strength / 2  # K = ½|⟨[Ŝ,Ê]⟩|

    # 異なる「運用方針」での不確定性
    high_security_delta_S = 0.1  # セキュリティを固定（厳格な監視）
    high_efficiency_delta_E = 0.1  # 効率を固定（徹底的な最適化）

    delta_E_given_S = K_values / high_security_delta_S
    delta_S_given_E = K_values / high_efficiency_delta_E

    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(13, 6))

    # 左：セキュリティを固定したときの効率の不確定性
    ax1.plot(commutator_strength, delta_E_given_S,
             "-", color="#E53935", linewidth=2.5,
             label=f"ΔS = {high_security_delta_S}（高セキュリティ固定）")
    ax1.fill_between(commutator_strength, delta_E_given_S,
                     alpha=0.15, color="#E53935")
    ax1.axhline(1.0, color="gray", linestyle="--", linewidth=1, label="ΔE = 1（完全不確定）")
    ax1.set_xlabel("交換子の強さ |⟨[Ŝ, Ê]⟩|", fontsize=11)
    ax1.set_ylabel("ΔE（効率の不確定性）", fontsize=11)
    ax1.set_title(
        "セキュリティを固定したとき\n非可換性が強いほど効率が不安定になる",
        fontsize=11
    )
    ax1.legend(fontsize=9)
    ax1.grid(True, alpha=0.3)
    ax1.set_ylim(0, 1.2)

    # 右：効率を固定したときのセキュリティの不確定性
    ax2.plot(commutator_strength, delta_S_given_E,
             "-", color="#1565C0", linewidth=2.5,
             label=f"ΔE = {high_efficiency_delta_E}（高効率固定）")
    ax2.fill_between(commutator_strength, delta_S_given_E,
                     alpha=0.15, color="#1565C0")
    ax2.axhline(1.0, color="gray", linestyle="--", linewidth=1, label="ΔS = 1（完全不確定）")
    ax2.set_xlabel("交換子の強さ |⟨[Ŝ, Ê]⟩|", fontsize=11)
    ax2.set_ylabel("ΔS（セキュリティの不確定性）", fontsize=11)
    ax2.set_title(
        "効率を固定したとき\n非可換性が強いほどセキュリティが不安定になる",
        fontsize=11
    )
    ax2.legend(fontsize=9)
    ax2.grid(True, alpha=0.3)
    ax2.set_ylim(0, 1.2)

    fig.suptitle(
        r"$[\hat{S}, \hat{E}] \neq 0$（非可換性）が不確定性の根拠"
        "\n§2の代数的構造と§5の最適化限界の接続",
        fontsize=12, y=1.02
    )

    plt.tight_layout()
    out = IMG_DIR / "08_commutator_uncertainty.png"
    plt.savefig(out, dpi=200, bbox_inches="tight")
    plt.close()
    print(f"保存: {out}")


# ── 図3：最適化景観と不確定性の壁 ────────────────────────────────────────────

def plot_optimization_landscape():
    """
    2次元パラメータ空間上の目的関数 J(θ₁, θ₂) の景観。
    不確定性の境界が制約として現れる。
    """
    t1 = np.linspace(0, 1, 200)
    t2 = np.linspace(0, 1, 200)
    T1, T2 = np.meshgrid(t1, t2)

    # 目的関数：セキュリティと効率のトレードオフ
    # 複数の局所解を持つ非凸関数
    J = (
        -np.exp(-((T1 - 0.3)**2 + (T2 - 0.7)**2) / 0.02)  # 局所最適1
        - 1.2 * np.exp(-((T1 - 0.7)**2 + (T2 - 0.3)**2) / 0.03)  # 大域最適
        - 0.6 * np.exp(-((T1 - 0.5)**2 + (T2 - 0.5)**2) / 0.04)  # 局所最適2
        + 0.5 * (T1**2 + T2**2)  # 正則化項
    )

    K = 0.05
    forbidden = (T1 * T2) < K  # 不確定性境界

    fig, ax = plt.subplots(figsize=(9, 8))

    # 目的関数の等高線
    levels = np.linspace(J.min(), J.max(), 25)
    cf = ax.contourf(T1, T2, J, levels=levels, cmap="RdYlGn_r", alpha=0.8)
    ax.contour(T1, T2, J, levels=levels[::3], colors="white", alpha=0.3, linewidths=0.5)
    cbar = plt.colorbar(cf, ax=ax)
    cbar.set_label("目的関数 J(θ)（低いほど最適）", fontsize=10)

    # 不確定性の壁
    ax.contour(T1, T2, T1 * T2, levels=[K],
               colors=["#F44336"], linewidths=3)
    ax.contourf(T1, T2, T1 * T2, levels=[0, K],
                colors=["#F44336"], alpha=0.3)
    ax.text(0.02, 0.15, f"禁止領域\n(θ₁·θ₂ < K={K})",
            fontsize=9, color="#C62828",
            bbox=dict(boxstyle="round", facecolor="#FFEBEE", alpha=0.7))

    # 最適点のマーク
    # 大域最適
    ax.plot(0.7, 0.3, "*", color="gold", markersize=16, zorder=5,
            label="大域最適解")
    # 局所最適
    ax.plot(0.3, 0.7, "^", color="white", markersize=10, zorder=5,
            label="局所最適解", markeredgecolor="gray")
    ax.plot(0.5, 0.5, "s", color="white", markersize=9, zorder=5,
            markeredgecolor="gray")

    # Newton法の軌跡（仮想）
    newton_path = np.array([
        [0.55, 0.55], [0.62, 0.42], [0.68, 0.33], [0.70, 0.30]
    ])
    ax.plot(newton_path[:, 0], newton_path[:, 1],
            "w--o", linewidth=2, markersize=6,
            label="Newton法の軌跡（Phase 2）")

    # Adam の探索軌跡（仮想）
    np.random.seed(42)
    adam_path_x = [0.2]
    adam_path_y = [0.8]
    for _ in range(20):
        adam_path_x.append(adam_path_x[-1] + 0.025 + 0.01 * np.random.randn())
        adam_path_y.append(adam_path_y[-1] - 0.025 + 0.01 * np.random.randn())
    ax.plot(adam_path_x, adam_path_y,
            color="cyan", linewidth=1.5, alpha=0.7,
            label="Adam の探索（Phase 1）")

    ax.set_xlabel("θ₁（セキュリティパラメータ）", fontsize=12)
    ax.set_ylabel("θ₂（効率パラメータ）", fontsize=12)
    ax.set_title(
        "MEDICUS 最適化景観\n"
        "不確定性の壁が制約として現れる非凸空間",
        fontsize=12
    )
    ax.set_xlim(0, 1)
    ax.set_ylim(0, 1)
    ax.legend(fontsize=9, loc="upper right",
              facecolor="white", framealpha=0.8)

    plt.tight_layout()
    out = IMG_DIR / "09_optimization_landscape.png"
    plt.savefig(out, dpi=200, bbox_inches="tight")
    plt.close()
    print(f"保存: {out}")


# ── メイン ────────────────────────────────────────────────────────────────────

if __name__ == "__main__":
    print("=== 不確定性原理の視覚化 ===")
    plot_uncertainty_boundary()
    plot_commutator_uncertainty()
    plot_optimization_landscape()
    print("完了。img/ ディレクトリを確認してください。")
