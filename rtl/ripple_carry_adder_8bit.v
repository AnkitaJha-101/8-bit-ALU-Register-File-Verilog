// ============================================================================
// Module Name: ripple_carry_adder_8bit
// Description: 8-bit Ripple Carry Adder (RCA) constructed by cascading
//              eight 1-bit full adder instances.
// Standard:    Verilog-2001 (Synthesizable)
// Author:      Senior RTL Design Engineer
// Project:     8-bit ALU with Register File & Adder Architecture Analysis
// ============================================================================

`timescale 1ns / 1ps

module ripple_carry_adder_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire       cin,
    output wire [7:0] sum,
    output wire       cout
);

    wire [7:0] c; // Internal ripple carry chain

    // First bit full adder
    full_adder fa0 (
        .a   (a[0]),
        .b   (b[0]),
        .cin (cin),
        .sum (sum[0]),
        .cout(c[0])
    );

    // Generate loop for full adders bit 1 to 7
    genvar i;
    generate
        for (i = 1; i < 8; i = i + 1) begin : gen_rca
            full_adder fa_inst (
                .a   (a[i]),
                .b   (b[i]),
                .cin (c[i-1]),
                .sum (sum[i]),
                .cout(c[i])
            );
        end
    endgenerate

    assign cout = c[7];

endmodule
