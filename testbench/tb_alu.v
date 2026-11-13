// ============================================================================
// Module Name: tb_alu
// Description: Comprehensive self-checking testbench for the 8-bit ALU.
//              Tests all 12 functional operations, flag logic (Carry, Zero,
//              Overflow, Sign), corner cases, and randomized vectors.
// Standard:    Verilog-2001
// Author:      Senior Verification Engineer
// Project:     8-bit ALU with Register File & Adder Architecture Analysis
// ============================================================================

`timescale 1ns / 1ps

module tb_alu;

    reg  [7:0] a;
    reg  [7:0] b;
    reg  [3:0] alu_sel;
    wire [7:0] alu_out;
    wire       carry_flag;
    wire       zero_flag;
    wire       overflow_flag;
    wire       sign_flag;

    integer pass_count;
    integer fail_count;
    integer test_index;

    // Operation codes matching RTL
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

    // Instantiate ALU (using default CLA adder)
    alu_8bit #(
        .ADDER_TYPE(1)
    ) dut (
        .a            (a),
        .b            (b),
        .alu_sel      (alu_sel),
        .alu_out      (alu_out),
        .carry_flag   (carry_flag),
        .zero_flag    (zero_flag),
        .overflow_flag(overflow_flag),
        .sign_flag    (sign_flag)
    );

    // Self-checking task
    task check_alu;
        input [7:0] in_a;
        input [7:0] in_b;
        input [3:0] sel;
        input [7:0] exp_out;
        input       exp_c;
        input       exp_z;
        input       exp_v;
        input       exp_s;
        input [127:0] test_name;
        reg match;
        begin
            a       = in_a;
            b       = in_b;
            alu_sel = sel;
            #10; // Settle combinational logic

            match = 1'b1;

            if (alu_out !== exp_out) begin
                $display("FAIL [DATA] %s | Sel=%0d A=0x%02h B=0x%02h | Exp=0x%02h Got=0x%02h",
                         test_name, sel, in_a, in_b, exp_out, alu_out);
                match = 1'b0;
            end
            if (carry_flag !== exp_c) begin
                $display("FAIL [CARRY] %s | Sel=%0d A=0x%02h B=0x%02h | Exp_C=%b Got_C=%b",
                         test_name, sel, in_a, in_b, exp_c, carry_flag);
                match = 1'b0;
            end
            if (zero_flag !== exp_z) begin
                $display("FAIL [ZERO] %s | Sel=%0d A=0x%02h B=0x%02h | Exp_Z=%b Got_Z=%b",
                         test_name, sel, in_a, in_b, exp_z, zero_flag);
                match = 1'b0;
            end
            if (overflow_flag !== exp_v) begin
                $display("FAIL [OVERFLOW] %s | Sel=%0d A=0x%02h B=0x%02h | Exp_V=%b Got_V=%b",
                         test_name, sel, in_a, in_b, exp_v, overflow_flag);
                match = 1'b0;
            end
            if (sign_flag !== exp_s) begin
                $display("FAIL [SIGN] %s | Sel=%0d A=0x%02h B=0x%02h | Exp_S=%b Got_S=%b",
                         test_name, sel, in_a, in_b, exp_s, sign_flag);
                match = 1'b0;
            end

            if (match) begin
                pass_count = pass_count + 1;
            end else begin
                fail_count = fail_count + 1;
            end
            test_index = test_index + 1;
        end
    endtask

    // Helper task to compute golden reference for any A, B, Sel
    task check_random_alu;
        input [7:0] in_a;
        input [7:0] in_b;
        input [3:0] sel;
        reg [7:0] exp_out;
        reg       exp_c;
        reg       exp_z;
        reg       exp_v;
        reg       exp_s;
        reg [8:0] temp_arith;
        begin
            case (sel)
                OP_ADD: begin
                    temp_arith = in_a + in_b;
                    exp_out    = temp_arith[7:0];
                    exp_c      = temp_arith[8];
                    exp_v      = (in_a[7] == in_b[7]) && (exp_out[7] != in_a[7]);
                end
                OP_SUB: begin
                    temp_arith = in_a - in_b;
                    exp_out    = temp_arith[7:0];
                    exp_c      = (in_a < in_b); // Borrow
                    exp_v      = (in_a[7] != in_b[7]) && (exp_out[7] != in_a[7]);
                end
                OP_AND: begin
                    exp_out = in_a & in_b;
                    exp_c   = 1'b0;
                    exp_v   = 1'b0;
                end
                OP_OR: begin
                    exp_out = in_a | in_b;
                    exp_c   = 1'b0;
                    exp_v   = 1'b0;
                end
                OP_XOR: begin
                    exp_out = in_a ^ in_b;
                    exp_c   = 1'b0;
                    exp_v   = 1'b0;
                end
                OP_NOT: begin
                    exp_out = ~in_a;
                    exp_c   = 1'b0;
                    exp_v   = 1'b0;
                end
                OP_SHL: begin
                    exp_out = {in_a[6:0], 1'b0};
                    exp_c   = in_a[7];
                    exp_v   = 1'b0;
                end
                OP_SHR: begin
                    exp_out = {1'b0, in_a[7:1]};
                    exp_c   = in_a[0];
                    exp_v   = 1'b0;
                end
                OP_INC: begin
                    exp_out = in_a + 8'd1;
                    exp_c   = (in_a == 8'hFF);
                    exp_v   = (in_a == 8'h7F);
                end
                OP_DEC: begin
                    exp_out = in_a - 8'd1;
                    exp_c   = (in_a == 8'h00);
                    exp_v   = (in_a == 8'h80);
                end
                OP_CMP: begin
                    exp_out = {6'b000000, (in_a > in_b), (in_a == in_b)};
                    exp_c   = (in_a > in_b);
                    exp_v   = 1'b0;
                end
                OP_PASS: begin
                    exp_out = in_a;
                    exp_c   = 1'b0;
                    exp_v   = 1'b0;
                end
                default: begin
                    exp_out = 8'h00;
                    exp_c   = 1'b0;
                    exp_v   = 1'b0;
                end
            endcase
            exp_z = (exp_out == 8'h00);
            exp_s = exp_out[7];

            check_alu(in_a, in_b, sel, exp_out, exp_c, exp_z, exp_v, exp_s, "Random Vector");
        end
    endtask

    integer i;

    initial begin
        $dumpfile("simulation/alu_sim.vcd");
        $dumpvars(0, tb_alu);

        pass_count = 0;
        fail_count = 0;
        test_index = 1;

        $display("==================================================================");
        $display("  STARTING 8-BIT ALU COMPREHENSIVE VERIFICATION                  ");
        $display("==================================================================");

        // 1. ADDITION TESTS
        $display("[OP 00] Testing Addition (A + B)...");
        check_alu(8'h10, 8'h20, OP_ADD, 8'h30, 0, 0, 0, 0, "ADD Basic");
        check_alu(8'h00, 8'h00, OP_ADD, 8'h00, 0, 1, 0, 0, "ADD Zero Result");
        check_alu(8'hFF, 8'h01, OP_ADD, 8'h00, 1, 1, 0, 0, "ADD Carry & Zero");
        check_alu(8'h7F, 8'h01, OP_ADD, 8'h80, 0, 0, 1, 1, "ADD Signed Overflow (+ to -)");
        check_alu(8'h80, 8'h80, OP_ADD, 8'h00, 1, 1, 1, 0, "ADD Signed Overflow (- to +)");

        // 2. SUBTRACTION TESTS
        $display("[OP 01] Testing Subtraction (A - B)...");
        check_alu(8'h30, 8'h10, OP_SUB, 8'h20, 0, 0, 0, 0, "SUB Basic Positive");
        check_alu(8'h20, 8'h20, OP_SUB, 8'h00, 0, 1, 0, 0, "SUB Equal / Zero Flag");
        check_alu(8'h10, 8'h20, OP_SUB, 8'hF0, 1, 0, 0, 1, "SUB Borrow & Negative");
        check_alu(8'h7F, 8'h80, OP_SUB, 8'hFF, 1, 0, 1, 1, "SUB Signed Overflow (+ - - = -)");
        check_alu(8'h80, 8'h01, OP_SUB, 8'h7F, 0, 0, 1, 0, "SUB Signed Overflow (- - + = +)");

        // 3. BITWISE AND
        $display("[OP 02] Testing Bitwise AND (A & B)...");
        check_alu(8'hF0, 8'h33, OP_AND, 8'h30, 0, 0, 0, 0, "AND Mask");
        check_alu(8'hAA, 8'h55, OP_AND, 8'h00, 0, 1, 0, 0, "AND Disjoint (Zero)");

        // 4. BITWISE OR
        $display("[OP 03] Testing Bitwise OR (A | B)...");
        check_alu(8'hF0, 8'h0F, OP_OR,  8'hFF, 0, 0, 0, 1, "OR Combine (Sign=1)");
        check_alu(8'h00, 8'h00, OP_OR,  8'h00, 0, 1, 0, 0, "OR Zero");

        // 5. BITWISE XOR
        $display("[OP 04] Testing Bitwise XOR (A ^ B)...");
        check_alu(8'hAA, 8'h55, OP_XOR, 8'hFF, 0, 0, 0, 1, "XOR Alternating");
        check_alu(8'hCC, 8'hCC, OP_XOR, 8'h00, 0, 1, 0, 0, "XOR Self (Zero)");

        // 6. BITWISE NOT
        $display("[OP 05] Testing Bitwise NOT (~A)...");
        check_alu(8'hFF, 8'h00, OP_NOT, 8'h00, 0, 1, 0, 0, "NOT All 1s -> 0");
        check_alu(8'h00, 8'h00, OP_NOT, 8'hFF, 0, 0, 0, 1, "NOT All 0s -> 0xFF");

        // 7. LOGICAL LEFT SHIFT
        $display("[OP 06] Testing Logical Left Shift (A << 1)...");
        check_alu(8'h01, 8'h00, OP_SHL, 8'h02, 0, 0, 0, 0, "SHL 1 -> 2");
        check_alu(8'h80, 8'h00, OP_SHL, 8'h00, 1, 1, 0, 0, "SHL Carry Out & Zero");
        check_alu(8'hC0, 8'h00, OP_SHL, 8'h80, 1, 0, 0, 1, "SHL Carry Out & Sign=1");

        // 8. LOGICAL RIGHT SHIFT
        $display("[OP 07] Testing Logical Right Shift (A >> 1)...");
        check_alu(8'h02, 8'h00, OP_SHR, 8'h01, 0, 0, 0, 0, "SHR 2 -> 1");
        check_alu(8'h01, 8'h00, OP_SHR, 8'h00, 1, 1, 0, 0, "SHR Carry Out & Zero");
        check_alu(8'h80, 8'h00, OP_SHR, 8'h40, 0, 0, 0, 0, "SHR MSB cleared");

        // 9. INCREMENT
        $display("[OP 08] Testing Increment (A + 1)...");
        check_alu(8'h05, 8'h00, OP_INC, 8'h06, 0, 0, 0, 0, "INC Normal");
        check_alu(8'hFF, 8'h00, OP_INC, 8'h00, 1, 1, 0, 0, "INC Rollover (Carry & Zero)");
        check_alu(8'h7F, 8'h00, OP_INC, 8'h80, 0, 0, 1, 1, "INC Signed Overflow (+127 -> -128)");

        // 10. DECREMENT
        $display("[OP 09] Testing Decrement (A - 1)...");
        check_alu(8'h06, 8'h00, OP_DEC, 8'h05, 0, 0, 0, 0, "DEC Normal");
        check_alu(8'h00, 8'h00, OP_DEC, 8'hFF, 1, 0, 0, 1, "DEC Underflow (Borrow)");
        check_alu(8'h80, 8'h00, OP_DEC, 8'h7F, 0, 0, 1, 0, "DEC Signed Overflow (-128 -> +127)");

        // 11. COMPARISON
        $display("[OP 10] Testing Comparison (A == B, A > B)...");
        check_alu(8'h45, 8'h45, OP_CMP, 8'h01, 0, 0, 0, 0, "CMP Equal (out=1)");
        check_alu(8'h80, 8'h20, OP_CMP, 8'h02, 1, 0, 0, 0, "CMP Greater (out=2, carry=1)");
        check_alu(8'h10, 8'h90, OP_CMP, 8'h00, 0, 1, 0, 0, "CMP Less (out=0, zero=1)");

        // 12. PASS-THROUGH
        $display("[OP 11] Testing Pass-Through (A)...");
        check_alu(8'hA5, 8'h33, OP_PASS, 8'hA5, 0, 0, 0, 1, "PASS Normal Non-zero");
        check_alu(8'h00, 8'hFF, OP_PASS, 8'h00, 0, 1, 0, 0, "PASS Zero");

        // 13. RANDOMIZED VERIFICATION (120 Random Vectors across all opcodes)
        $display("[RANDOM] Executing 120 Randomized Operations...");
        for (i = 0; i < 120; i = i + 1) begin
            check_random_alu($random, $random, $random % 12);
        end

        // SUMMARY
        $display("==================================================================");
        $display("  ALU VERIFICATION SUMMARY                                        ");
        $display("==================================================================");
        $display("  Total Tests Executed : %0d", (test_index - 1));
        $display("  Passed Tests         : %0d", pass_count);
        $display("  Failed Tests         : %0d", fail_count);
        if (fail_count == 0) begin
            $display("  VERIFICATION RESULT  : >>> ALL ALU TESTS PASSED <<<");
        end else begin
            $display("  VERIFICATION RESULT  : >>> ALU TESTS FAILED <<<");
        end
        $display("==================================================================");

        $finish;
    end

endmodule
