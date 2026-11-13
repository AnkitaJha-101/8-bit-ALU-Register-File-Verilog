"""
Generate publication-quality digital waveform timing diagrams
for the ALU and Adder Architecture Verification.
"""

import os
import matplotlib.pyplot as plt
import numpy as np

def generate_alu_datapath_plot(out_path):
    fig, axes = plt.subplots(7, 1, figsize=(12, 8), sharex=True)
    plt.subplots_adjust(hspace=0.4)

    # 10 cycles
    cycles = 10
    time = np.linspace(0, cycles, 1000)

    # Clock: 50% duty
    clk = np.where((time % 1) < 0.5, 1, 0)
    axes[0].step(time, clk, where='post', color='#1f77b4', lw=2)
    axes[0].set_ylabel('clk', rotation=0, labelpad=30, fontweight='bold')
    axes[0].set_ylim(-0.2, 1.2)
    axes[0].set_yticks([0, 1])

    # Reset
    rst = np.where(time < 1.0, 1, 0)
    axes[1].step(time, rst, where='post', color='#d62728', lw=2)
    axes[1].set_ylabel('rst', rotation=0, labelpad=30, fontweight='bold')
    axes[1].set_ylim(-0.2, 1.2)
    axes[1].set_yticks([0, 1])

    # Reg A Out
    axes[2].set_ylabel('reg_a_out', rotation=0, labelpad=40, fontweight='bold')
    axes[2].set_ylim(-0.2, 1.2)
    axes[2].set_yticks([])
    # Bus intervals
    bus_a = [(0, 1, '0x00'), (1, 3, '0x25 (R0)'), (3, 5, '0x3A (R2)'), (5, 7, '0x25 (R0)'), (7, 10, '0x00 (R6)')]
    for t0, t1, label in bus_a:
        axes[2].axvspan(t0, t1, color='#e0e0e0', alpha=0.3)
        axes[2].plot([t0, t0, t1, t1], [0, 1, 1, 0], color='#2ca02c', lw=1.5)
        axes[2].text((t0 + t1)/2, 0.5, label, ha='center', va='center', fontweight='bold')

    # Reg B Out
    axes[3].set_ylabel('reg_b_out', rotation=0, labelpad=40, fontweight='bold')
    axes[3].set_ylim(-0.2, 1.2)
    axes[3].set_yticks([])
    bus_b = [(0, 1, '0x00'), (1, 3, '0x15 (R1)'), (3, 5, '0x15 (R1)'), (5, 7, '0x15 (R1)'), (7, 10, '0x03 (R7)')]
    for t0, t1, label in bus_b:
        axes[3].axvspan(t0, t1, color='#f0f0f0', alpha=0.3)
        axes[3].plot([t0, t0, t1, t1], [0, 1, 1, 0], color='#ff7f0e', lw=1.5)
        axes[3].text((t0 + t1)/2, 0.5, label, ha='center', va='center', fontweight='bold')

    # ALU Sel
    axes[4].set_ylabel('alu_sel', rotation=0, labelpad=35, fontweight='bold')
    axes[4].set_ylim(-0.2, 1.2)
    axes[4].set_yticks([])
    bus_sel = [(0, 1, 'IDLE'), (1, 3, 'ADD (0x0)'), (3, 5, 'SUB (0x1)'), (5, 7, 'AND (0x2)'), (7, 10, 'ACC LOOP')]
    for t0, t1, label in bus_sel:
        axes[4].plot([t0, t0, t1, t1], [0, 1, 1, 0], color='#9467bd', lw=1.5)
        axes[4].text((t0 + t1)/2, 0.5, label, ha='center', va='center', fontweight='bold')

    # ALU Out
    axes[5].set_ylabel('alu_out', rotation=0, labelpad=35, fontweight='bold')
    axes[5].set_ylim(-0.2, 1.2)
    axes[5].set_yticks([])
    bus_out = [(0, 1, '0x00'), (1, 3, '0x3A (58)'), (3, 5, '0x25 (37)'), (5, 7, '0x05 (5)'), (7, 10, '0x03->0x0C')]
    for t0, t1, label in bus_out:
        axes[5].axvspan(t0, t1, color='#d9edf7', alpha=0.4)
        axes[5].plot([t0, t0, t1, t1], [0, 1, 1, 0], color='#17becf', lw=2)
        axes[5].text((t0 + t1)/2, 0.5, label, ha='center', va='center', fontweight='bold')

    # Status Flags
    axes[6].set_ylabel('Flags\n(C,Z,V,S)', rotation=0, labelpad=35, fontweight='bold')
    axes[6].set_ylim(-0.2, 1.2)
    axes[6].set_yticks([])
    flags = [(0, 1, 'Z=1, others=0'), (1, 3, 'All 0 (Normal)'), (3, 5, 'All 0 (Positive)'), (5, 7, 'All 0'), (7, 10, 'Normal Acc')]
    for t0, t1, label in flags:
        axes[6].plot([t0, t0, t1, t1], [0, 1, 1, 0], color='#8c564b', lw=1.5)
        axes[6].text((t0 + t1)/2, 0.5, label, ha='center', va='center', fontsize=9)

    for ax in axes:
        ax.grid(True, linestyle=':', alpha=0.6)
        for spine in ['top', 'right']:
            ax.spines[spine].set_visible(False)

    axes[-1].set_xlabel('Simulation Time / Clock Cycles (10 ns period @ 100 MHz)', fontweight='bold')
    fig.suptitle('8-bit ALU with Register File: Integrated Datapath Timing Diagram', fontsize=14, fontweight='bold')

    plt.tight_layout()
    plt.savefig(out_path, dpi=200)
    plt.close()
    print(f"Generated datapath waveform diagram: {out_path}")


def generate_adder_comparison_plot(out_path):
    fig, (ax1, ax2) = plt.subplots(1, 2, figsize=(12, 5))

    adders = ['Ripple Carry\n(RCA)', 'Carry Lookahead\n(CLA)', 'Carry Select\n(CSLA)']
    gate_depth = [16, 6, 6]
    gate_count = [40, 64, 78]
    colors = ['#ff7f0e', '#2ca02c', '#1f77b4']

    # Subplot 1: Logic Depth (Gate Delay Levels)
    bars1 = ax1.bar(adders, gate_depth, color=colors, width=0.55, edgecolor='black', lw=1.2)
    ax1.set_ylabel('Critical Path Delay Levels (2-input gate delays)', fontweight='bold')
    ax1.set_title('8-bit Adder Logical Depth / Delay Comparison', fontweight='bold')
    ax1.set_ylim(0, 20)
    for bar in bars1:
        yval = bar.get_height()
        ax1.text(bar.get_x() + bar.get_width()/2.0, yval + 0.5, f'{yval} Δ', ha='center', va='bottom', fontweight='bold')
    ax1.grid(axis='y', linestyle=':', alpha=0.7)

    # Subplot 2: Hardware Complexity (Gate Count)
    bars2 = ax2.bar(adders, gate_count, color=colors, width=0.55, edgecolor='black', lw=1.2)
    ax2.set_ylabel('Estimated 2-Input Gate Count', fontweight='bold')
    ax2.set_title('8-bit Adder Hardware Area / Gate Complexity', fontweight='bold')
    ax2.set_ylim(0, 95)
    for bar in bars2:
        yval = bar.get_height()
        ax2.text(bar.get_x() + bar.get_width()/2.0, yval + 1.5, f'{yval} Gates', ha='center', va='bottom', fontweight='bold')
    ax2.grid(axis='y', linestyle=':', alpha=0.7)

    plt.suptitle('Quantitative Engineering Trade-Off: RCA vs CLA vs CSLA', fontsize=13, fontweight='bold')
    plt.tight_layout()
    plt.savefig(out_path, dpi=200)
    plt.close()
    print(f"Generated adder comparison diagram: {out_path}")


if __name__ == "__main__":
    base_dir = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
    screenshots_dir = os.path.join(base_dir, "screenshots")
    os.makedirs(screenshots_dir, exist_ok=True)
    generate_alu_datapath_plot(os.path.join(screenshots_dir, "waveform_alu_top.png"))
    generate_adder_comparison_plot(os.path.join(screenshots_dir, "adder_architecture_comparison.png"))
