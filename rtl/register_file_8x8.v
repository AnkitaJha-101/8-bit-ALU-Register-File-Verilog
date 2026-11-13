// ============================================================================
// Module Name: register_file_8x8
// Description: 8 x 8-bit Register File featuring two independent asynchronous
//              read ports and one synchronous write port with synchronous reset.
// Standard:    Verilog-2001 (Synthesizable)
// Author:      Senior RTL Design Engineer
// Project:     8-bit ALU with Register File & Adder Architecture Analysis
// ============================================================================

`timescale 1ns / 1ps

module register_file_8x8 (
    input  wire       clk,        // System Clock
    input  wire       rst,        // Synchronous Active-High Reset
    // Read Port A
    input  wire [2:0] rd_addr_a,  // 3-bit Read Address A (R0 to R7)
    output wire [7:0] rd_data_a,  // 8-bit Read Data Output A
    // Read Port B
    input  wire [2:0] rd_addr_b,  // 3-bit Read Address B (R0 to R7)
    output wire [7:0] rd_data_b,  // 8-bit Read Data Output B
    // Write Port
    input  wire       wr_en,      // Synchronous Write Enable
    input  wire [2:0] wr_addr,    // 3-bit Write Address (R0 to R7)
    input  wire [7:0] wr_data     // 8-bit Write Data Input
);

    // Array of 8 registers, each 8-bit wide
    reg [7:0] registers [0:7];

    integer i;

    // Synchronous Write Port with Synchronous Active-High Reset
    always @(posedge clk) begin
        if (rst) begin
            for (i = 0; i < 8; i = i + 1) begin
                registers[i] <= 8'h00;
            end
        end else if (wr_en) begin
            registers[wr_addr] <= wr_data;
        end
    end

    // Dual Independent Combinational Read Ports (Asynchronous Read)
    assign rd_data_a = registers[rd_addr_a];
    assign rd_data_b = registers[rd_addr_b];

endmodule
