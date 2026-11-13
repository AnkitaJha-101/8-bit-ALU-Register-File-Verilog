# Hardware Architecture Specification: 8-Bit ALU with Register File

## 1. Top-Level Datapath Architecture

The top-level design (`alu_regfile_top`) integrates an **8x8 Dual-Port Register File** with a modular **8-bit Arithmetic Logic Unit (ALU)**. The datapath is designed for single-cycle execution of register-to-register ALU operations, external register initialization, and iterative feedback accumulation.

```
                         +-----------------------------------+
                         |         alu_regfile_top           |
                         |                                   |
    clk, rst ----------->|                                   |
                         |   +---------------------------+   |
    rd_addr_a [2:0] ---->|-->|                           |   |
    rd_addr_b [2:0] ---->|-->|     register_file_8x8     |   |
                         |   |                           |   |
                         |   |  Port A Read  Port B Read |   |
                         |   +------+-------------+------+   |
                         |          |             |          |
                         |     reg_a_out     reg_b_out       |
                         |          |             |          |
                         |          +------+------+          |
                         |                 |                 |
                         |                 v                 |
                         |   +---------------------------+   |
    alu_sel [3:0] ------>|-->|         alu_8bit          |   |
                         |   |                           |-->|---> carry_flag
                         |   | (RCA / CLA / CSLA Select) |-->|---> zero_flag
                         |   |                           |-->|---> overflow_flag
                         |   +-------------+-------------+-->|---> sign_flag
                         |                 |                 |
                         |              alu_out              |
                         |                 |                 |
                         |                 +-----------+     |
                         |                             |     |
    wr_src_sel --------->|---+                         |     |
    ext_wr_data [7:0] -->|   |   +--------------+      |     |
                         |   +-->| 2:1 Write Mux|<-----+     |
                         |       +-------+------+            |
                         |               |                   |
    wr_addr [2:0] ------>|---------------+                   |
    wr_en -------------->|-----------------------------------+
                         +-----------------------------------+
```

---

## 2. Port Definitions and Interface Signals

### A. Top-Level Module (`alu_regfile_top`)
| Port Name | Direction | Width | Description |
| :--- | :--- | :--- | :--- |
| `clk` | Input | 1 bit | Global system clock (100 MHz target) |
| `rst` | Input | 1 bit | Synchronous active-high reset |
| `rd_addr_a` | Input | 3 bits | Read address for Register File Port A |
| `rd_addr_b` | Input | 3 bits | Read address for Register File Port B |
| `wr_addr` | Input | 3 bits | Destination address for Register File write |
| `wr_en` | Input | 1 bit | Synchronous write enable for Register File |
| `wr_src_sel` | Input | 1 bit | Write source select: `0` = External data, `1` = ALU output feedback |
| `ext_wr_data` | Input | 8 bits | External data input for direct register loading |
| `alu_sel` | Input | 4 bits | ALU operation select code (12 operations) |
| `reg_a_out` | Output | 8 bits | Observable operand A fetched from Port A |
| `reg_b_out` | Output | 8 bits | Observable operand B fetched from Port B |
| `alu_out` | Output | 8 bits | 8-bit output result from ALU |
| `carry_flag` | Output | 1 bit | Carry out / Borrow flag |
| `zero_flag` | Output | 1 bit | High when `alu_out == 8'h00` |
| `overflow_flag`| Output | 1 bit | Two's complement signed arithmetic overflow flag |
| `sign_flag` | Output | 1 bit | High when MSB of result is 1 (`alu_out[7] == 1`) |

---

## 3. Register File Architecture (`register_file_8x8`)

The register file contains eight 8-bit general-purpose registers ($R0$ to $R7$):
- **Dual Asynchronous Read Ports:** Read data is combinational, allowing immediate operand access during the same clock cycle that read addresses are applied.
  $$\text{rd\_data\_a} = \text{registers}[\text{rd\_addr\_a}]$$
  $$\text{rd\_data\_b} = \text{registers}[\text{rd\_addr\_b}]$$
- **Synchronous Write Port:** Data is written on the rising clock edge when `wr_en` is asserted:
  $$\text{registers}[\text{wr\_addr}] \leftarrow \text{wr\_data} \quad (\text{if } \text{wr\_en} = 1)$$
- **Synchronous Reset:** When `rst = 1` at the rising clock edge, all 8 registers are initialized to `8'h00`.

---

## 4. ALU Opcode Decoding and Flag Logic (`alu_8bit`)

The ALU supports 12 operations decoded via `alu_sel[3:0]`:

| Opcode `[3:0]` | Name | Operation | Carry Flag (`carry_flag`) | Overflow Flag (`overflow_flag`) |
| :---: | :--- | :--- | :--- | :--- |
| `4'b0000` (`0x0`) | **ADD** | $A + B$ | Adder Carry Out ($C_8$) | $(A_7 == B_7) \land (\text{Out}_7 \neq A_7)$ |
| `4'b0001` (`0x1`) | **SUB** | $A - B = A + \overline{B} + 1$ | Borrow ($\text{Adder } \overline{C_8}$) | $(A_7 \neq B_7) \land (\text{Out}_7 \neq A_7)$ |
| `4'b0010` (`0x2`) | **AND** | $A \land B$ | `1'b0` | `1'b0` |
| `4'b0011` (`0x3`) | **OR** | $A \lor B$ | `1'b0` | `1'b0` |
| `4'b0100` (`0x4`) | **XOR** | $A \oplus B$ | `1'b0` | `1'b0` |
| `4'b0101` (`0x5`) | **NOT** | $\sim A$ | `1'b0` | `1'b0` |
| `4'b0110` (`0x6`) | **SHL** | $A \ll 1$ (Shift Left) | Shifted-out MSB ($A_7$) | `1'b0` |
| `4'b0111` (`0x7`) | **SHR** | $A \gg 1$ (Shift Right) | Shifted-out LSB ($A_0$) | `1'b0` |
| `4'b1000` (`0x8`) | **INC** | $A + 1$ | Roll-over carry ($A == 8\text{'hFF}$) | Positive overflow ($A == 8\text{'h7F}$) |
| `4'b1001` (`0x9`) | **DEC** | $A - 1$ | Underflow borrow ($A == 8\text{'h00}$) | Negative overflow ($A == 8\text{'h80}$) |
| `4'b1010` (`0xA`) | **CMP** | $\text{Out}[0]=(A==B), \text{Out}[1]=(A>B)$ | $(A > B)$ | `1'b0` |
| `4'b1011` (`0xB`) | **PASS**| $A$ (Transparent pass) | `1'b0` | `1'b0` |

### Common Flag Equations:
- **Zero Flag (`zero_flag`):** Asserted when all 8 output bits are zero:
  $$\text{zero\_flag} = (\text{alu\_out} == 8\text{'b00000000})$$
- **Sign Flag (`sign_flag`):** Reflects the most significant bit (two's complement negative indicator):
  $$\text{sign\_flag} = \text{alu\_out}[7]$$
