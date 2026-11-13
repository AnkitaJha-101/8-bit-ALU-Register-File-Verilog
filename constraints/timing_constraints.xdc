# ==============================================================================
# Timing & Physical Constraints: 8-bit ALU with Register File
# Target Device: Xilinx Artix-7 (xc7a35tcpg236-1)
# Standard:      Xilinx Design Constraints (XDC)
# Author:        Senior FPGA / Timing Engineer
# ==============================================================================

# ------------------------------------------------------------------------------
# 1. Primary Clock Definition
# ------------------------------------------------------------------------------
# 100 MHz target system clock (10.000 ns period, 50% duty cycle)
create_clock -period 10.000 -name clk -waveform {0.000 5.000} [get_ports clk]

# ------------------------------------------------------------------------------
# 2. Input / Output Delay Constraints
# ------------------------------------------------------------------------------
# Assume 2.0 ns setup requirement for upstream logic (20% of cycle time)
set_input_delay -clock [get_clocks clk] -max 2.000 [get_ports {rst rd_addr_a[*] rd_addr_b[*] wr_addr[*] wr_en wr_src_sel ext_wr_data[*] alu_sel[*]}]
set_input_delay -clock [get_clocks clk] -min 0.500 [get_ports {rst rd_addr_a[*] rd_addr_b[*] wr_addr[*] wr_en wr_src_sel ext_wr_data[*] alu_sel[*]}]

# Assume 2.0 ns delay budget for downstream capture
set_output_delay -clock [get_clocks clk] -max 2.000 [get_ports {reg_a_out[*] reg_b_out[*] alu_out[*] carry_flag zero_flag overflow_flag sign_flag}]
set_output_delay -clock [get_clocks clk] -min 0.500 [get_ports {reg_a_out[*] reg_b_out[*] alu_out[*] carry_flag zero_flag overflow_flag sign_flag}]

# ------------------------------------------------------------------------------
# 3. Electrical Characteristics & Drive Strength Template
# ------------------------------------------------------------------------------
set_property IOSTANDARD LVCMOS33 [get_ports -filter {NAME =~ *}]
set_property SLEW SLOW [get_ports {alu_out[*] carry_flag zero_flag overflow_flag sign_flag}]
set_property DRIVE 8 [get_ports {alu_out[*] carry_flag zero_flag overflow_flag sign_flag}]

# ------------------------------------------------------------------------------
# 4. Optional FPGA Package Pin Template (e.g. Digilent Basys 3 / Arty A7)
# ------------------------------------------------------------------------------
# Clock Pin (100 MHz oscillator)
# set_property PACKAGE_PIN W5 [get_ports clk]
# Reset Button
# set_property PACKAGE_PIN V17 [get_ports rst]
