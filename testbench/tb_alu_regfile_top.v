// ============================================================================
// Module Name: tb_alu_regfile_top
// Description: Comprehensive self-checking top-level integration testbench
//              for the 8-bit ALU with 8x8 Register File.
//              Verifies datapath loading, dual register reads, ALU operations,
//              write-back feedback loops, accumulator behavior, and status flags.
// Standard:    Verilog-2001
// Author:      Senior Verification Engineer
// Project:     8-bit ALU with Register File & Adder Architecture Analysis
// ============================================================================

`timescale 1ns / 1ps

module tb_alu_regfile_top;

    reg        clk;
    reg        rst;
    reg  [2:0] rd_addr_a;
    reg  [2:0] rd_addr_b;
    reg  [2:0] wr_addr;
    reg        wr_en;
    reg        wr_src_sel;
    reg  [7:0] ext_wr_data;
    reg  [3:0] alu_sel;

    wire [7:0] reg_a_out;
    wire [7:0] reg_b_out;
    wire [7:0] alu_out;
    wire       carry_flag;
    wire       zero_flag;
    wire       overflow_flag;
    wire       sign_flag;

    integer pass_count;
    integer fail_count;
    integer test_index;

    // ALU Operation Codes
    localparam OP_ADD  = 4'b0000;
    localparam OP_SUB  = 4'b0001;
    localparam OP_AND  = 4'b0010;
    localparam OP_OR   = 4'b0011;
    localparam OP_XOR  = 4'b0100;
    localparam OP_NOT  = 4'b0101;
    localparam OP_SHL  = 4'b0110;
    localparam OP_SHR  = 4'b0111;
    localparam OP_INC  = 4'b1000;
    localparam OP_DEC  = 4'b1001;
    localparam OP_CMP  = 4'b1010;
    localparam OP_PASS = 4'b1011;

    // Instantiate Top-Level Design Under Test (DUT)
    alu_regfile_top #(
        .ADDER_TYPE(1) // CLA Adder
    ) dut (
        .clk          (clk),
        .rst          (rst),
        .rd_addr_a    (rd_addr_a),
        .rd_addr_b    (rd_addr_b),
        .wr_addr      (wr_addr),
        .wr_en        (wr_en),
        .wr_src_sel   (wr_src_sel),
        .ext_wr_data  (ext_wr_data),
        .alu_sel      (alu_sel),
        .reg_a_out    (reg_a_out),
        .reg_b_out    (reg_b_out),
        .alu_out      (alu_out),
        .carry_flag   (carry_flag),
        .zero_flag    (zero_flag),
        .overflow_flag(overflow_flag),
        .sign_flag    (sign_flag)
    );

    // 100 MHz clock generation
    always #5 clk = ~clk;

    // Task: Load register from external data input
    task load_register;
        input [2:0] addr;
        input [7:0] data;
        begin
            @(posedge clk);
            wr_src_sel  = 1'b0; // External input
            wr_en       = 1'b1;
            wr_addr     = addr;
            ext_wr_data = data;
            @(posedge clk);
            wr_en       = 1'b0;
            #1;
        end
    endtask

    // Task: Execute ALU operation and optionally write back to destination register
    task exec_alu_op;
        input [2:0] src_a;
        input [2:0] src_b;
        input [3:0] op;
        input       do_writeback;
        input [2:0] dst_addr;
        input [7:0] exp_alu_out;
        input       exp_c;
        input       exp_z;
        input       exp_v;
        input       exp_s;
        input [127:0] test_name;
        reg match;
        begin
            rd_addr_a = src_a;
            rd_addr_b = src_b;
            alu_sel   = op;
            #2; // Allow combinational read and ALU evaluation

            match = 1'b1;
            if (alu_out !== exp_alu_out) begin
                $display("FAIL [ALU_OUT] %s | Exp=0x%02h Got=0x%02h", test_name, exp_alu_out, alu_out);
                match = 1'b0;
            end
            if (carry_flag !== exp_c) begin
                $display("FAIL [CARRY] %s | Exp_C=%b Got_C=%b", test_name, exp_c, carry_flag);
                match = 1'b0;
            end
            if (zero_flag !== exp_z) begin
                $display("FAIL [ZERO] %s | Exp_Z=%b Got_Z=%b", test_name, exp_z, zero_flag);
                match = 1'b0;
            end
            if (overflow_flag !== exp_v) begin
                $display("FAIL [OVERFLOW] %s | Exp_V=%b Got_V=%b", test_name, exp_v, overflow_flag);
                match = 1'b0;
            end
            if (sign_flag !== exp_s) begin
                $display("FAIL [SIGN] %s | Exp_S=%b Got_S=%b", test_name, exp_s, sign_flag);
                match = 1'b0;
            end

            if (do_writeback) begin
                @(posedge clk);
                wr_src_sel = 1'b1; // ALU feedback
                wr_en      = 1'b1;
                wr_addr    = dst_addr;
                @(posedge clk);
                wr_en      = 1'b0;
                #1;
            end

            if (match) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
            end
            test_index = test_index + 1;
        end
    endtask

    initial begin
        $dumpfile("simulation/alu_regfile_top_sim.vcd");
        $dumpvars(0, tb_alu_regfile_top);

        clk         = 0;
        rst         = 0;
        rd_addr_a   = 0;
        rd_addr_b   = 0;
        wr_addr     = 0;
        wr_en       = 0;
        wr_src_sel  = 0;
        ext_wr_data = 0;
        alu_sel     = 0;
        pass_count  = 0;
        fail_count  = 0;
        test_index  = 1;

        $display("==================================================================");
        $display("  STARTING TOP-LEVEL ALU + REGISTER FILE INTEGRATION VERIFICATION ");
        $display("==================================================================");

        // Step 1: System Reset
        $display("[STEP 1] Applying System Reset...");
        @(posedge clk);
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        #2;

        // Step 2: Load Initial Data into Register File
        $display("[STEP 2] Loading Initial Data into Registers R0..R3...");
        load_register(3'd0, 8'h25); // R0 = 0x25 (37 decimal)
        load_register(3'd1, 8'h15); // R1 = 0x15 (21 decimal)
        load_register(3'd2, 8'h00); // R2 = 0x00
        load_register(3'd3, 8'h80); // R3 = 0x80 (-128 decimal)

        // Step 3: Execute R2 = R0 + R1 (0x25 + 0x15 = 0x3A = 58)
        $display("[STEP 3] Datapath Add: R2 <= R0 + R1...");
        exec_alu_op(3'd0, 3'd1, OP_ADD, 1'b1, 3'd2, 8'h3A, 0, 0, 0, 0, "R2 = R0 + R1");

        // Verify R2 now holds 0x3A via pass-through
        exec_alu_op(3'd2, 3'd0, OP_PASS, 1'b0, 3'd0, 8'h3A, 0, 0, 0, 0, "Verify R2 Content");

        // Step 4: Execute R4 = R2 - R1 (0x3A - 0x15 = 0x25)
        $display("[STEP 4] Datapath Sub: R4 <= R2 - R1...");
        exec_alu_op(3'd2, 3'd1, OP_SUB, 1'b1, 3'd4, 8'h25, 0, 0, 0, 0, "R4 = R2 - R1");
        exec_alu_op(3'd4, 3'd0, OP_PASS, 1'b0, 3'd0, 8'h25, 0, 0, 0, 0, "Verify R4 Content");

        // Step 5: Logical Operations in Datapath (R5 <= R0 & R1: 0x25 & 0x15 = 0x05)
        $display("[STEP 5] Datapath Bitwise AND: R5 <= R0 & R1...");
        exec_alu_op(3'd0, 3'd1, OP_AND, 1'b1, 3'd5, 8'h05, 0, 0, 0, 0, "R5 = R0 & R1");
        exec_alu_op(3'd5, 3'd0, OP_PASS, 1'b0, 3'd0, 8'h05, 0, 0, 0, 0, "Verify R5 Content");

        // Step 6: Accumulator Loop (Iterative Feedback)
        // R6 = 0x00 initially; load R7 = 0x03.
        // Loop 4 times: R6 <= R6 + R7 -> 0x03 -> 0x06 -> 0x09 -> 0x0C
        $display("[STEP 6] Accumulator Feedback Loop: R6 <= R6 + R7 (4 iterations)...");
        load_register(3'd6, 8'h00);
        load_register(3'd7, 8'h03);

        exec_alu_op(3'd6, 3'd7, OP_ADD, 1'b1, 3'd6, 8'h03, 0, 0, 0, 0, "Acc Iter 1: 0x03");
        exec_alu_op(3'd6, 3'd7, OP_ADD, 1'b1, 3'd6, 8'h06, 0, 0, 0, 0, "Acc Iter 2: 0x06");
        exec_alu_op(3'd6, 3'd7, OP_ADD, 1'b1, 3'd6, 8'h09, 0, 0, 0, 0, "Acc Iter 3: 0x09");
        exec_alu_op(3'd6, 3'd7, OP_ADD, 1'b1, 3'd6, 8'h0C, 0, 0, 0, 0, "Acc Iter 4: 0x0C");

        // Step 7: Comparison in Datapath (Compare R2 (0x3A) and R4 (0x25): R2 > R4)
        $display("[STEP 7] Datapath Comparison: Compare R2 and R4...");
        exec_alu_op(3'd2, 3'd4, OP_CMP, 1'b0, 3'd0, 8'h02, 1, 0, 0, 0, "Compare R2 > R4");

        // Compare equal: R2 and R2
        exec_alu_op(3'd2, 3'd2, OP_CMP, 1'b0, 3'd0, 8'h01, 0, 0, 0, 0, "Compare R2 == R2");

        // Step 8: Signed Overflow in Datapath (R3 is 0x80; R3 - 0x01 = 0x7F with overflow)
        $display("[STEP 8] Signed Overflow Check in Datapath...");
        load_register(3'd1, 8'h01);
        exec_alu_op(3'd3, 3'd1, OP_SUB, 1'b0, 3'd0, 8'h7F, 0, 0, 1, 0, "Overflow: -128 - 1 = +127");

        // Summary
        $display("==================================================================");
        $display("  TOP-LEVEL INTEGRATION VERIFICATION SUMMARY                      ");
        $display("==================================================================");
        $display("  Total Tests Executed : %0d", (test_index - 1));
        $display("  Passed Tests         : %0d", pass_count);
        $display("  Failed Tests         : %0d", fail_count);
        if (fail_count == 0) begin
            $display("  VERIFICATION RESULT  : >>> ALL INTEGRATION TESTS PASSED <<<");
        end else begin
            $display("  VERIFICATION RESULT  : >>> INTEGRATION TESTS FAILED <<<");
        end
        $display("==================================================================");

        $finish;
    end

endmodule
