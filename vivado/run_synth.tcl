# ==============================================================================
# Script:  run_synth.tcl
# Purpose: Non-Project Batch Synthesis and Implementation in Xilinx Vivado
# Output:  Generates Utilization, Timing, Power, and DRC Reports in ../reports/
# ==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize "$script_dir/.."]
set rpt_dir    [file normalize "$root_dir/reports"]
set part       "xc7a35tcpg236-1"

file mkdir $rpt_dir

puts "======================================================================"
puts "  STARTING BATCH FPGA SYNTHESIS: alu_regfile_top"
puts "  Target Device: $part"
puts "======================================================================"

# Read RTL Sources
read_verilog [glob "$root_dir/rtl/*.v"]

# Read Timing Constraints
read_xdc "$root_dir/constraints/timing_constraints.xdc"

# Run Synthesis
puts "==> Synthesizing Design..."
synth_design -top alu_regfile_top -part $part -flatten_hierarchy rebuilt

# Generate Post-Synthesis Reports
puts "==> Generating Synthesis Utilization & Timing Reports..."
report_utilization -file "$rpt_dir/utilization_synth.rpt" -pb "$rpt_dir/utilization_synth.pb"
report_timing_summary -file "$rpt_dir/timing_summary_synth.rpt"

# Optional Implementation Flow
puts "==> Running Logic Optimization..."
opt_design

puts "==> Running Placement..."
place_design

puts "==> Running Routing..."
route_design

# Post-Implementation Reports
puts "==> Generating Post-Implementation Reports..."
report_utilization -file "$rpt_dir/utilization_impl.rpt"
report_timing_summary -file "$rpt_dir/timing_summary_impl.rpt"
report_power -file "$rpt_dir/power_impl.rpt"
report_drc -file "$rpt_dir/drc_impl.rpt"

puts "======================================================================"
puts "  SYNTHESIS AND IMPLEMENTATION COMPLETE!"
puts "  Reports stored in: $rpt_dir"
puts "======================================================================"
