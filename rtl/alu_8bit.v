// ============================================================================
// Module Name: alu_8bit
// Description: Comprehensive 8-bit Arithmetic Logic Unit (ALU) supporting 12
//              operations with Carry, Zero, Overflow, and Sign status flags.
// Standard:    Verilog-2001 (Synthesizable)
// Author:      Senior RTL Design Engineer
// Project:     8-bit ALU with Register File & Adder Architecture Analysis
// ============================================================================

`timescale 1ns / 1ps

module alu_8bit #(
    parameter ADDER_TYPE = 1 // 0: RCA, 1: CLA, 2: CSLA
)(
    input  wire [7:0] a,             // 8-bit Input Operand A
    input  wire [7:0] b,             // 8-bit Input Operand B
    input  wire [3:0] alu_sel,       // 4-bit Operation Select
    output reg  [7:0] alu_out,       // 8-bit ALU Result
    output reg        carry_flag,    // Carry / Borrow Flag
    output wire       zero_flag,     // Zero Result Flag
    output reg        overflow_flag, // Two's Complement Signed Overflow Flag
    output wire       sign_flag      // Negative / Sign Flag (MSB)
);

    // ========================================================================
    // ALU Operation Codes
    // ========================================================================
    localparam OP_ADD  = 4'b0000; // 0: Addition (A + B)
    localparam OP_SUB  = 4'b0001; // 1: Subtraction (A - B)
    localparam OP_AND  = 4'b0010; // 2: Bitwise AND (A & B)
    localparam OP_OR   = 4'b0011; // 3: Bitwise OR (A | B)
    localparam OP_XOR  = 4'b0100; // 4: Bitwise XOR (A ^ B)
    localparam OP_NOT  = 4'b0101; // 5: Bitwise NOT (~A)
    localparam OP_SHL  = 4'b0110; // 6: Logical Left Shift (A << 1)
    localparam OP_SHR  = 4'b0111; // 7: Logical Right Shift (A >> 1)
    localparam OP_INC  = 4'b1000; // 8: Increment (A + 1)
    localparam OP_DEC  = 4'b1001; // 9: Decrement (A - 1)
    localparam OP_CMP  = 4'b1010; // 10: Comparison (Equal & Greater Than)
    localparam OP_PASS = 4'b1011; // 11: Pass-through A

    // ========================================================================
    // Modular Structural Adder Instantiation
    // ========================================================================
    wire [7:0] adder_b_op;
    wire       adder_cin;
    wire [7:0] adder_sum;
    wire       adder_cout;

    // Subtraction uses 2's complement addition: A + (~B) + 1
    assign adder_b_op = (alu_sel == OP_SUB) ? (~b) : b;
    assign adder_cin  = (alu_sel == OP_SUB) ? 1'b1 : 1'b0;

    generate
        if (ADDER_TYPE == 0) begin : gen_rca_adder
            ripple_carry_adder_8bit u_rca (
                .a   (a),
                .b   (adder_b_op),
                .cin (adder_cin),
                .sum (adder_sum),
                .cout(adder_cout)
            );
        end else if (ADDER_TYPE == 2) begin : gen_csla_adder
            carry_select_adder_8bit u_csla (
                .a   (a),
                .b   (adder_b_op),
                .cin (adder_cin),
                .sum (adder_sum),
                .cout(adder_cout)
            );
        end else begin : gen_cla_adder // Default: CLA
            carry_lookahead_adder_8bit u_cla (
                .a   (a),
                .b   (adder_b_op),
                .cin (adder_cin),
                .sum (adder_sum),
                .cout(adder_cout)
            );
        end
    endgenerate

    // ========================================================================
    // Combinational ALU Core Logic
    // ========================================================================
    always @(*) begin
        // Default assignments to prevent inferred latches
        alu_out       = 8'b00000000;
        carry_flag    = 1'b0;
        overflow_flag = 1'b0;

        case (alu_sel)
            OP_ADD: begin
                alu_out       = adder_sum;
                carry_flag    = adder_cout;
                // Signed overflow: positive + positive = negative, or negative + negative = positive
                overflow_flag = (a[7] == b[7]) && (alu_out[7] != a[7]);
            end

            OP_SUB: begin
                alu_out       = adder_sum;
                // In subtraction, adder_cout = 1 indicates no borrow (A >= B); borrow = ~adder_cout (A < B)
                carry_flag    = ~adder_cout;
                // Signed overflow: positive - negative = negative, or negative - positive = positive
                overflow_flag = (a[7] != b[7]) && (alu_out[7] != a[7]);
            end

            OP_AND: begin
                alu_out       = a & b;
                carry_flag    = 1'b0;
                overflow_flag = 1'b0;
            end

            OP_OR: begin
                alu_out       = a | b;
                carry_flag    = 1'b0;
                overflow_flag = 1'b0;
            end

            OP_XOR: begin
                alu_out       = a ^ b;
                carry_flag    = 1'b0;
                overflow_flag = 1'b0;
            end

            OP_NOT: begin
                alu_out       = ~a;
                carry_flag    = 1'b0;
                overflow_flag = 1'b0;
            end

            OP_SHL: begin
                alu_out       = {a[6:0], 1'b0};
                carry_flag    = a[7]; // Shifted-out MSB
                overflow_flag = 1'b0;
            end

            OP_SHR: begin
                alu_out       = {1'b0, a[7:1]};
                carry_flag    = a[0]; // Shifted-out LSB
                overflow_flag = 1'b0;
            end

            OP_INC: begin
                alu_out       = a + 8'd1;
                carry_flag    = (a == 8'hFF); // Roll-over carry
                // Overflow occurs if +127 (0x7F) increments to -128 (0x80)
                overflow_flag = (a == 8'h7F);
            end

            OP_DEC: begin
                alu_out       = a - 8'd1;
                carry_flag    = (a == 8'h00); // Borrow on underflow
                // Overflow occurs if -128 (0x80) decrements to +127 (0x7F)
                overflow_flag = (a == 8'h80);
            end

            OP_CMP: begin
                // Comparison output:
                // alu_out[0] = Equal (A == B)
                // alu_out[1] = Greater Than (A > B, unsigned)
                alu_out       = {6'b000000, (a > b), (a == b)};
                carry_flag    = (a > b);
                overflow_flag = 1'b0;
            end

            OP_PASS: begin
                alu_out       = a;
                carry_flag    = 1'b0;
                overflow_flag = 1'b0;
            end

            default: begin
                alu_out       = 8'b00000000;
                carry_flag    = 1'b0;
                overflow_flag = 1'b0;
            end
        endcase
    end

    // ========================================================================
    // Status Flags Generation
    // ========================================================================
    assign zero_flag = (alu_out == 8'b00000000);
    assign sign_flag = alu_out[7];

endmodule
