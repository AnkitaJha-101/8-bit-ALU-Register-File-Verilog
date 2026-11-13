// ============================================================================
// Module Name: tb_reg_file
// Description: Comprehensive self-checking testbench for the 8x8 Dual-Port
//              Register File. Verifies reset, sequential write/read, simultaneous
//              dual reads, write-enable masking, and randomized access.
// Standard:    Verilog-2001
// Author:      Senior Verification Engineer
// Project:     8-bit ALU with Register File & Adder Architecture Analysis
// ============================================================================

`timescale 1ns / 1ps

module tb_reg_file;

    reg        clk;
    reg        rst;
    reg  [2:0] rd_addr_a;
    wire [7:0] rd_data_a;
    reg  [2:0] rd_addr_b;
    wire [7:0] rd_data_b;
    reg        wr_en;
    reg  [2:0] wr_addr;
    reg  [7:0] wr_data;

    integer pass_count;
    integer fail_count;
    integer test_index;
    integer i;

    // Instantiate Register File DUT
    register_file_8x8 dut (
        .clk      (clk),
        .rst      (rst),
        .rd_addr_a(rd_addr_a),
        .rd_data_a(rd_data_a),
        .rd_addr_b(rd_addr_b),
        .rd_data_b(rd_data_b),
        .wr_en    (wr_en),
        .wr_addr  (wr_addr),
        .wr_data  (wr_data)
    );

    // Clock Generation: 100 MHz (10ns period)
    always #5 clk = ~clk;

    // Helper write task
    task write_reg;
        input [2:0] addr;
        input [7:0] data;
        begin
            @(posedge clk);
            wr_en   = 1'b1;
            wr_addr = addr;
            wr_data = data;
            @(posedge clk);
            wr_en   = 1'b0;
            #1; // Delay after clock edge
        end
    endtask

    // Helper verify task for both ports
    task verify_read;
        input [2:0] addr_a;
        input [7:0] exp_data_a;
        input [2:0] addr_b;
        input [7:0] exp_data_b;
        input [127:0] test_name;
        reg match;
        begin
            rd_addr_a = addr_a;
            rd_addr_b = addr_b;
            #2; // Combinational propagation delay

            match = 1'b1;
            if (rd_data_a !== exp_data_a) begin
                $display("FAIL [PORT A] %s | AddrA=%0d Exp=0x%02h Got=0x%02h",
                         test_name, addr_a, exp_data_a, rd_data_a);
                match = 1'b0;
            end
            if (rd_data_b !== exp_data_b) begin
                $display("FAIL [PORT B] %s | AddrB=%0d Exp=0x%02h Got=0x%02h",
                         test_name, addr_b, exp_data_b, rd_data_b);
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

    // Shadow model for randomized testing
    reg [7:0] shadow_regs [0:7];

    initial begin
        $dumpfile("simulation/regfile_sim.vcd");
        $dumpvars(0, tb_reg_file);

        clk        = 0;
        rst        = 0;
        wr_en      = 0;
        wr_addr    = 0;
        wr_data    = 0;
        rd_addr_a  = 0;
        rd_addr_b  = 0;
        pass_count = 0;
        fail_count = 0;
        test_index = 1;

        $display("==================================================================");
        $display("  STARTING REGISTER FILE (8x8) COMPREHENSIVE VERIFICATION         ");
        $display("==================================================================");

        // --------------------------------------------------------------------
        // Test 1: Reset Behavior
        // --------------------------------------------------------------------
        $display("[TEST 1] Testing Synchronous Reset on All Registers...");
        @(posedge clk);
        rst = 1'b1;
        @(posedge clk);
        rst = 1'b0;
        #1;

        for (i = 0; i < 8; i = i + 1) begin
            verify_read(i[2:0], 8'h00, i[2:0], 8'h00, "Reset Check");
            shadow_regs[i] = 8'h00;
        end

        // --------------------------------------------------------------------
        // Test 2: Sequential Write & Dual Read
        // --------------------------------------------------------------------
        $display("[TEST 2] Writing Unique Values to R0 through R7...");
        for (i = 0; i < 8; i = i + 1) begin
            write_reg(i[2:0], (8'h11 * (i + 1)));
            shadow_regs[i] = (8'h11 * (i + 1));
        end

        $display("[TEST 2] Verifying Dual Independent Read Ports...");
        verify_read(3'd0, 8'h11, 3'd1, 8'h22, "Dual Read R0 & R1");
        verify_read(3'd2, 8'h33, 3'd3, 8'h44, "Dual Read R2 & R3");
        verify_read(3'd4, 8'h55, 3'd5, 8'h66, "Dual Read R4 & R5");
        verify_read(3'd6, 8'h77, 3'd7, 8'h88, "Dual Read R6 & R7");

        // --------------------------------------------------------------------
        // Test 3: Simultaneous Same-Address Read
        // --------------------------------------------------------------------
        $display("[TEST 3] Simultaneous Read from Same Address on Both Ports...");
        for (i = 0; i < 8; i = i + 1) begin
            verify_read(i[2:0], shadow_regs[i], i[2:0], shadow_regs[i], "Same Address Dual Read");
        end

        // --------------------------------------------------------------------
        // Test 4: Write Enable = 0 (Data Protection)
        // --------------------------------------------------------------------
        $display("[TEST 4] Testing Write Inhibit when wr_en = 0...");
        @(posedge clk);
        wr_en   = 1'b0;
        wr_addr = 3'd3;
        wr_data = 8'hFF; // Should NOT be written
        @(posedge clk);
        #1;
        verify_read(3'd3, 8'h44, 3'd3, 8'h44, "Write Enable Disabled Check");

        // --------------------------------------------------------------------
        // Test 5: Overwrite Register
        // --------------------------------------------------------------------
        $display("[TEST 5] Testing Overwrite of Existing Register...");
        write_reg(3'd3, 8'hAA);
        shadow_regs[3] = 8'hAA;
        verify_read(3'd3, 8'hAA, 3'd3, 8'hAA, "Overwrite R3 Check");

        // --------------------------------------------------------------------
        // Test 6: Randomized Write and Read Verification
        // --------------------------------------------------------------------
        $display("[TEST 6] Running 50 Randomized Write & Read Transactions...");
        repeat (50) begin
            reg [2:0] rand_waddr;
            reg [7:0] rand_wdata;
            reg [2:0] rand_raddr_a;
            reg [2:0] rand_raddr_b;

            rand_waddr   = $random % 8;
            rand_wdata   = $random;
            rand_raddr_a = $random % 8;
            rand_raddr_b = $random % 8;

            write_reg(rand_waddr, rand_wdata);
            shadow_regs[rand_waddr] = rand_wdata;

            verify_read(rand_raddr_a, shadow_regs[rand_raddr_a],
                        rand_raddr_b, shadow_regs[rand_raddr_b],
                        "Random Access Test");
        end

        // --------------------------------------------------------------------
        // Summary
        // --------------------------------------------------------------------
        $display("==================================================================");
        $display("  REGISTER FILE VERIFICATION SUMMARY                              ");
        $display("==================================================================");
        $display("  Total Tests Executed : %0d", (test_index - 1));
        $display("  Passed Tests         : %0d", pass_count);
        $display("  Failed Tests         : %0d", fail_count);
        if (fail_count == 0) begin
            $display("  VERIFICATION RESULT  : >>> ALL REGISTER FILE TESTS PASSED <<<");
        end else begin
            $display("  VERIFICATION RESULT  : >>> REGISTER FILE TESTS FAILED <<<");
        end
        $display("==================================================================");

        $finish;
    end

endmodule
