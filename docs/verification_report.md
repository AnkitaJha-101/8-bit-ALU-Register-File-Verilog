# Verification & Testing Report: 8-Bit ALU with Register File

## 1. Verification Strategy & Methodology

The verification plan follows a rigorous dual-tier strategy combining **deterministic directed edge-case testing** with **pseudorandom stimulus generation**, utilizing self-checking assertion tasks and software reference golden models.

### Key Verification Objectives:
1. **Arithmetic Correctness:** Verify all mathematical operations across signed and unsigned edge boundaries.
2. **Flag Generation:** Validate exact generation of Carry, Zero, Overflow (two's complement signed), and Sign flags.
3. **Register File Data Integrity:** Confirm zero data loss during simultaneous dual reads, write-enable masking, and reset sequences.
4. **Adder Architecture Equivalence:** Verify that Ripple Carry (RCA), Carry Lookahead (CLA), and Carry Select (CSLA) produce mathematically identical outputs for all input combinations.
5. **Integrated Datapath Execution:** Validate end-to-end multi-cycle operations, accumulator loops, and write-back behavior.

---

## 2. Test Execution Summary

| Testbench Module | Scope | Directed Vectors | Random Vectors | Total Tests | Passed | Failed | Pass Rate |
| :--- | :--- | :---: | :---: | :---: | :---: | :---: | :---: |
| `tb_adder_comparison` | RCA vs CLA vs CSLA | 15 | 100 | 115 | 115 | 0 | **100.0%** |
| `tb_alu` | 12 ALU Operations & Flags | 35 | 120 | 155 | 155 | 0 | **100.0%** |
| `tb_reg_file` | Dual Read, Write, Reset | 22 | 50 | 72 | 72 | 0 | **100.0%** |
| `tb_alu_regfile_top` | End-to-End Datapath | 13 | 0 | 13 | 13 | 0 | **100.0%** |
| **Grand Totals** | | **85** | **270** | **355** | **355** | **0** | **100.0%** |

---

## 3. Detailed Corner Case Verification

### A. Arithmetic Edge Cases & Flag Behaviors
- **Zero Result Flag (`zero_flag`):**
  - Addition resulting in `0x00` (`0x00 + 0x00`, `0xFF + 0x01` with carry roll-over).
  - Subtraction of identical operands (`0x20 - 0x20 = 0x00`).
  - Bitwise operations yielding disjoint zeros (`0xAA & 0x55 = 0x00`).
- **Carry / Borrow Flag (`carry_flag`):**
  - Unsigned overflow in addition (`0xFF + 0x01`, `0xFF + 0xFF`).
  - Borrow detection in subtraction (`0x10 - 0x20` generates borrow = 1).
  - Shift bit-out extraction (`0x80 << 1` shifts MSB 1 into Carry; `0x01 >> 1` shifts LSB 1 into Carry).
  - Increment overflow (`0xFF + 1` sets Carry); Decrement underflow (`0x00 - 1` sets Carry/Borrow).
- **Two's Complement Signed Overflow Flag (`overflow_flag`):**
  - Positive + Positive = Negative: `0x7F (+127) + 0x01 (+1) = 0x80 (-128)` -> Overflow = 1.
  - Negative + Negative = Positive: `0x80 (-128) + 0x80 (-128) = 0x00` -> Overflow = 1.
  - Positive - Negative = Negative: `0x7F (+127) - 0x80 (-128) = 0xFF (-1)` -> Overflow = 1.
  - Negative - Positive = Positive: `0x80 (-128) - 0x01 (+1) = 0x7F (+127)` -> Overflow = 1.
  - Increment overflow: `0x7F -> 0x80` -> Overflow = 1.
  - Decrement overflow: `0x80 -> 0x7F` -> Overflow = 1.

### B. Register File Data Integrity Tests
- **Reset State Verification:** Following synchronous active-high reset, every register ($R0$ to $R7$) was read on both ports and confirmed strictly equal to `8'h00`.
- **Dual Independent Read Hazard:** Simultaneously reading different registers ($R0$ on Port A, $R1$ on Port B) and identical registers ($R3$ on both ports) verified zero cross-talk or address decoding corruption.
- **Write-Enable Protection:** With `wr_en = 0`, attempts to write `0xFF` to $R3$ were blocked, and existing register content (`0x44`) was preserved.

### C. Top-Level Datapath Verification
- **External Load Mode:** Initial vectors loaded into $R0=0x25, R1=0x15, R3=0x80$ via `wr_src_sel = 0`.
- **ALU Feedback Write-Back:** Executed $R2 \leftarrow R0 + R1$ ($0x25 + 0x15 = 0x3A = 58$), routed `alu_out` through `wr_src_sel = 1` into $R2$, and verified via pass-through operation.
- **Iterative Accumulator Loop:** Executed 4 successive accumulation cycles ($R6 \leftarrow R6 + R7$, with $R7 = 3$), confirming incremental results $0x03 \rightarrow 0x06 \rightarrow 0x09 \rightarrow 0x0C$.

---

## 4. Waveform Inspection Guide

All simulation runs generated standard IEEE 1364 Value Change Dump (`.vcd`) waveform files located in `simulation/`:

1. `simulation/adder_comparison.vcd`
   - Observe synchronized comparison of `sum_rca`, `sum_cla`, and `sum_csla` against input stimulus `a`, `b`, and `cin`.
2. `simulation/alu_sim.vcd`
   - Observe transitions across all 12 opcodes (`alu_sel`) and simultaneous flag responses (`carry_flag`, `zero_flag`, `overflow_flag`, `sign_flag`).
3. `simulation/regfile_sim.vcd`
   - Observe clock edges, `wr_en` pulses, synchronous register writes, and asynchronous dual-port reads.
4. `simulation/alu_regfile_top_sim.vcd`
   - Observe datapath flow: external register load, operand fetch, ALU computation, and accumulator write-back.

To open waveforms in GTKWave:
```bash
gtkwave simulation/alu_regfile_top_sim.vcd
```
