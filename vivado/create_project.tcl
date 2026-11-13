# ==============================================================================
# Script:  create_project.tcl
# Purpose: Re-creates the complete Xilinx Vivado Project for 8-bit ALU with RegFile
# Target:  xc7a35tcpg236-1 (Artix-7)
# Tool:    Vivado 2020.1+
# ==============================================================================

set proj_name "project_1_8bit_alu"
set proj_dir  [file normalize [file dirname [info script]]]
set root_dir  [file normalize "$proj_dir/.."]
set part      "xc7a35tcpg236-1"

puts "==> Creating Vivado Project: $proj_name"
puts "==> Root Directory: $root_dir"
puts "==> Target FPGA:    $part"

# Close existing project if open
close_project -quiet

# Create project
create_project -force $proj_name "$proj_dir/$proj_name" -part $part

# Add RTL sources
puts "==> Adding RTL sources..."
add_files -fileset sources_1 [glob "$root_dir/rtl/*.v"]
update_compile_order -fileset sources_1

# Set top module
set_property top alu_regfile_top [current_fileset]
update_compile_order -fileset sources_1

# Add Simulation sources
puts "==> Adding Testbench sources..."
add_files -fileset sim_1 [glob "$root_dir/testbench/*.v"]
update_compile_order -fileset sim_1
set_property top tb_alu_regfile_top [get_filesets sim_1]
set_property top_lib xil_defaultlib [get_filesets sim_1]

# Add Timing Constraints
puts "==> Adding Timing Constraints..."
add_files -fileset constrs_1 "$root_dir/constraints/timing_constraints.xdc"

# Configure Simulation Settings
set_property -name {xsim.simulate.runtime} -value {5000ns} -objects [get_filesets sim_1]
set_property -name {xsim.simulate.log_all_signals} -value {true} -objects [get_filesets sim_1]

puts "==> Vivado Project Created Successfully!"
puts "==> To synthesize, run: launch_runs synth_1 -jobs 4"
