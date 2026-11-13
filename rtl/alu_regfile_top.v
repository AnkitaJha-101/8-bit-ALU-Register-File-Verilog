// ============================================================================
// Module Name: alu_regfile_top
// Description: Top-level integration of the 8-bit ALU with the 8x8 Dual-Port
//              Register File. Supports loading registers externally, reading
//              operands directly into the ALU, and writing back ALU results.
// Standard:    Verilog-2001 (Synthesizable)
// Author:      Senior RTL Design Engineer
// Project:     8-bit ALU with Register File & Adder Architecture Analysis
// ============================================================================

`timescale 1ns / 1ps

module alu_regfile_top #(
    parameter ADDER_TYPE = 1 // 0: RCA, 1: CLA, 2: CSLA
)(
    input  wire       clk,            // System Clock
    input  wire       rst,            // Synchronous Active-High Reset
    // Register File Control
    input  wire [2:0] rd_addr_a,      // Read Address Port A (Source 1)
    input  wire [2:0] rd_addr_b,      // Read Address Port B (Source 2)
    input  wire [2:0] wr_addr,        // Destination Write Address
    input  wire       wr_en,          // Write Enable
    input  wire       wr_src_sel,     // Write Source Mux: 0 = ext_wr_data, 1 = alu_out
    input  wire [7:0] ext_wr_data,    // External Write Data Input
    // ALU Control
    input  wire [3:0] alu_sel,        // ALU 4-bit Opcode
    // Top-Level Status & Data Observability Outputs
    output wire [7:0] reg_a_out,      // Operand A from RegFile Port A
    output wire [7:0] reg_b_out,      // Operand B from RegFile Port B
    output wire [7:0] alu_out,        // ALU Result Output
    output wire       carry_flag,     // Carry / Borrow Flag
    output wire       zero_flag,      // Zero Result Flag
    output wire       overflow_flag,  // Two's Complement Overflow Flag
    output wire       sign_flag       // Sign / Negative Result Flag
);

    // Write Data Multiplexer: Selects between external data and ALU feedback
    wire [7:0] regfile_wr_data;
    assign regfile_wr_data = (wr_src_sel) ? alu_out : ext_wr_data;

    // ------------------------------------------------------------------------
    // 8x8 Dual-Port Register File Instantiation
    // ------------------------------------------------------------------------
    register_file_8x8 u_register_file (
        .clk      (clk),
        .rst      (rst),
        .rd_addr_a(rd_addr_a),
        .rd_data_a(reg_a_out),
        .rd_addr_b(rd_addr_b),
        .rd_data_b(reg_b_out),
        .wr_en    (wr_en),
        .wr_addr  (wr_addr),
        .wr_data  (regfile_wr_data)
    );

    // ------------------------------------------------------------------------
    // 8-bit Arithmetic Logic Unit (ALU) Instantiation
    // ------------------------------------------------------------------------
    alu_8bit #(
        .ADDER_TYPE(ADDER_TYPE)
    ) u_alu (
        .a            (reg_a_out),
        .b            (reg_b_out),
        .alu_sel      (alu_sel),
        .alu_out      (alu_out),
        .carry_flag   (carry_flag),
        .zero_flag    (zero_flag),
        .overflow_flag(overflow_flag),
        .sign_flag    (sign_flag)
    );

endmodule
