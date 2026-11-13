// ============================================================================
// Module Name: carry_select_adder_8bit
// Description: 8-bit Carry Select Adder (CSLA). Computes lower 4 bits directly
//              and pre-computes upper 4 bits for both cin=0 and cin=1 in parallel,
//              using 2:1 multiplexers to select the correct upper sum and carry.
// Standard:    Verilog-2001 (Synthesizable)
// Author:      Senior RTL Design Engineer
// Project:     8-bit ALU with Register File & Adder Architecture Analysis
// ============================================================================

`timescale 1ns / 1ps

module carry_select_adder_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);

    wire       c4;            // Actual carry out from lower 4-bit stage
    wire [3:0] sum_upper_0;   // Speculative upper sum assuming cin = 0
    wire [3:0] sum_upper_1;   // Speculative upper sum assuming cin = 1
    wire       cout_upper_0;  // Speculative carry out assuming cin = 0
    wire       cout_upper_1;  // Speculative carry out assuming cin = 1

    // Lower 4-bit block: Computes actual sum[3:0] and carry c4
    cla_4bit adder_lower (
        .a    (a[3:0]),
        .b    (b[3:0]),
        .cin  (cin),
        .sum  (sum[3:0]),
        .cout (c4),
        .p_blk(),
        .g_blk()
    );

    // Speculative upper block 0: Assumes cin = 0
    cla_4bit adder_upper_cin0 (
        .a    (a[7:4]),
        .b    (b[7:4]),
        .cin  (1'b0),
        .sum  (sum_upper_0),
        .cout (cout_upper_0),
        .p_blk(),
        .g_blk()
    );

    // Speculative upper block 1: Assumes cin = 1
    cla_4bit adder_upper_cin1 (
        .a    (a[7:4]),
        .b    (b[7:4]),
        .cin  (1'b1),
        .sum  (sum_upper_1),
        .cout (cout_upper_1),
        .p_blk(),
        .g_blk()
    );

    // 2:1 Multiplexer selection driven by lower carry (c4)
    assign sum[7:4] = (c4) ? sum_upper_1 : sum_upper_0;
    assign cout     = (c4) ? cout_upper_1 : cout_upper_0;

endmodule
