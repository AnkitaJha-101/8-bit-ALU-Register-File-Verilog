// ============================================================================
// Module Name: tb_adder_comparison
// Description: Comprehensive self-checking testbench comparing RCA, CLA, and
//              CSLA 8-bit adder architectures across directed edge cases and
//              randomized stimulus.
// Standard:    Verilog-2001
// Author:      Senior Verification Engineer
// Project:     8-bit ALU with Register File & Adder Architecture Analysis
// ============================================================================

`timescale 1ns / 1ps

module tb_adder_comparison;

    reg  [7:0] a;
    reg  [7:0] b;
    reg        cin;

    // Outputs from Ripple Carry Adder
    wire [7:0] sum_rca;
    wire       cout_rca;

    // Outputs from Carry Lookahead Adder
    wire [7:0] sum_cla;
    wire       cout_cla;

    // Outputs from Carry Select Adder
    wire [7:0] sum_csla;
    wire       cout_csla;

    // Golden reference
    reg  [8:0] expected;

    integer pass_count;
    integer fail_count;
    integer test_index;

    // Instantiate 8-bit Ripple Carry Adder
    ripple_carry_adder_8bit u_rca (
        .a   (a),
        .b   (b),
        .cin (cin),
        .sum (sum_rca),
        .cout(cout_rca)
    );

    // Instantiate 8-bit Carry Lookahead Adder
    carry_lookahead_adder_8bit u_cla (
        .a   (a),
        .b   (b),
        .cin (cin),
        .sum (sum_cla),
        .cout(cout_cla)
    );

    // Instantiate 8-bit Carry Select Adder
    carry_select_adder_8bit u_csla (
        .a   (a),
        .b   (b),
        .cin (cin),
        .sum (sum_csla),
        .cout(cout_csla)
    );

    // Verification task to compare all 3 adders against golden model
    task check_adders;
        input [7:0] in_a;
        input [7:0] in_b;
        input       in_cin;
        reg [8:0] gold;
        reg       match;
        begin
            a   = in_a;
            b   = in_b;
            cin = in_cin;
            #10; // Propagation delay

            gold = in_a + in_b + in_cin;
            match = 1'b1;

            if ({cout_rca, sum_rca} !== gold) begin
                $display("ERROR [RCA Mismatch] Test #%0d: A=0x%02h B=0x%02h Cin=%b | Expected=0x%03h Got=0x%03h",
                         test_index, in_a, in_b, in_cin, gold, {cout_rca, sum_rca});
                match = 1'b0;
            end

            if ({cout_cla, sum_cla} !== gold) begin
                $display("ERROR [CLA Mismatch] Test #%0d: A=0x%02h B=0x%02h Cin=%b | Expected=0x%03h Got=0x%03h",
                         test_index, in_a, in_b, in_cin, gold, {cout_cla, sum_cla});
                match = 1'b0;
            end

            if ({cout_csla, sum_csla} !== gold) begin
                $display("ERROR [CSLA Mismatch] Test #%0d: A=0x%02h B=0x%02h Cin=%b | Expected=0x%03h Got=0x%03h",
                         test_index, in_a, in_b, in_cin, gold, {cout_csla, sum_csla});
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

    initial begin
        // Setup waveform dumping
        $dumpfile("simulation/adder_comparison.vcd");
        $dumpvars(0, tb_adder_comparison);

        pass_count = 0;
        fail_count = 0;
        test_index = 1;

        $display("==================================================================");
        $display("  STARTING ADDER ARCHITECTURE COMPARISON VERIFICATION (8-BIT)     ");
        $display("  Architectures: Ripple Carry (RCA) vs CLA vs Carry Select (CSLA) ");
        $display("==================================================================");

        // --------------------------------------------------------------------
        // Phase 1: Directed Edge Cases
        // --------------------------------------------------------------------
        $display("[PHASE 1] Running Directed Edge Cases...");
        check_adders(8'h00, 8'h00, 1'b0); // 0 + 0 + 0 = 0
        check_adders(8'h00, 8'h00, 1'b1); // 0 + 0 + 1 = 1
        check_adders(8'hFF, 8'h00, 1'b0); // 255 + 0 = 255
        check_adders(8'hFF, 8'h00, 1'b1); // 255 + 0 + 1 = 256 (Cout=1, Sum=0)
        check_adders(8'hFF, 8'h01, 1'b0); // 255 + 1 = 256 (Cout=1, Sum=0)
        check_adders(8'hFF, 8'hFF, 1'b0); // 255 + 255 = 510 (Cout=1, Sum=0xFE)
        check_adders(8'hFF, 8'hFF, 1'b1); // 255 + 255 + 1 = 511 (Cout=1, Sum=0xFF)
        check_adders(8'h0F, 8'h01, 1'b0); // Lower nibble rollover (carry to bit 4)
        check_adders(8'h0F, 8'h00, 1'b1); // Lower nibble rollover via Cin
        check_adders(8'h7F, 8'h01, 1'b0); // Signed max positive + 1 = 0x80
        check_adders(8'h80, 8'h80, 1'b0); // Signed min + signed min = 0x100
        check_adders(8'h55, 8'hAA, 1'b0); // Alternating bit pattern (0101... + 1010...)
        check_adders(8'h55, 8'hAA, 1'b1); // Alternating bit pattern + 1 (generates all carries)
        check_adders(8'hAA, 8'h55, 1'b0); // Symmetrical alternating bits
        check_adders(8'hF0, 8'h0F, 1'b0); // Upper/Lower nibble split

        // --------------------------------------------------------------------
        // Phase 2: Randomized Verification (100 Randomized Vectors)
        // --------------------------------------------------------------------
        $display("[PHASE 2] Running 100 Randomized Test Vectors...");
        repeat (100) begin
            check_adders($random, $random, $random % 2);
        end

        // --------------------------------------------------------------------
        // Summary Report
        // --------------------------------------------------------------------
        $display("==================================================================");
        $display("  ADDER ARCHITECTURE COMPARISON VERIFICATION SUMMARY              ");
        $display("==================================================================");
        $display("  Total Tests Executed : %0d", (test_index - 1));
        $display("  Passed Tests         : %0d", pass_count);
        $display("  Failed Tests         : %0d", fail_count);
        if (fail_count == 0) begin
            $display("  VERIFICATION RESULT  : >>> ALL ADDER TESTS PASSED <<<");
        end else begin
            $display("  VERIFICATION RESULT  : >>> ADDER TESTS FAILED <<<");
        end
        $display("==================================================================");

        $finish;
    end

endmodule
