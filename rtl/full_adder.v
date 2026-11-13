// ============================================================================
// Module Name: full_adder
// Description: Standard 1-bit Full Adder with Carry In and Carry Out.
// Standard:    Verilog-2001 (Synthesizable)
// Author:      Senior RTL Design Engineer
// Project:     8-bit ALU with Register File & Adder Architecture Analysis
// ============================================================================

`timescale 1ns / 1ps

module full_adder (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire sum,
    output wire cout
);

    // Gate-level implementation
    // sum  = a ^ b ^ cin
    // cout = (a & b) | (cin & (a ^ b))
    assign sum  = a ^ b ^ cin;
    assign cout = (a & b) | (cin & (a ^ b));

endmodule
