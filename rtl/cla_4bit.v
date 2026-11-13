// ============================================================================
// Module Name: cla_4bit
// Description: 4-bit Carry Look-Ahead Adder block with internal carry lookahead
//              generator, block propagate (P_blk) and block generate (G_blk).
// Standard:    Verilog-2001 (Synthesizable)
// Author:      Senior RTL Design Engineer
// Project:     8-bit ALU with Register File & Adder Architecture Analysis
// ============================================================================

`timescale 1ns / 1ps

module cla_4bit (
    input  wire [3:0] a,
    input  wire [3:0] b,
    input  wire       cin,
    output wire [3:0] sum,
    output wire       cout,
    output wire       p_blk,
    output wire       g_blk
);

    wire [3:0] p; // Bit Propagate: p[i] = a[i] ^ b[i]
    wire [3:0] g; // Bit Generate:  g[i] = a[i] & b[i]
    wire [4:0] c; // Internal carries: c[0] = cin, c[4] = cout

    // Bit-level propagate and generate
    assign p = a ^ b;
    assign g = a & b;

    assign c[0] = cin;

    // Carry lookahead equations
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);

    // Sum calculation: sum[i] = p[i] ^ c[i]
    assign sum  = p ^ c[3:0];
    assign cout = c[4];

    // Block level propagate and generate for hierarchical expansion
    assign p_blk = p[3] & p[2] & p[1] & p[0];
    assign g_blk = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]);

endmodule
