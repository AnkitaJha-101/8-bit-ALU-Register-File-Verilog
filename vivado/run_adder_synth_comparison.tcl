# ==============================================================================
# Script:  run_adder_synth_comparison.tcl
# Purpose: Synthesizes RCA, CLA, and CSLA architectures independently to
#          compare FPGA LUT utilization, logic levels, and path delay.
# Output:  ../reports/adder_synth_comparison.rpt
# ==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize "$script_dir/.."]
set rpt_dir    [file normalize "$root_dir/reports"]
set part       "xc7a35tcpg236-1"

file mkdir $rpt_dir

set rpt_file [open "$rpt_dir/adder_synth_comparison.rpt" "w"]
puts $rpt_file "======================================================================"
puts $rpt_file "  COMPARATIVE SYNTHESIS REPORT: 8-BIT ADDER ARCHITECTURES"
puts $rpt_file "  Target FPGA: $part (Xilinx Artix-7)"
puts $rpt_file "======================================================================"

set adders [list "ripple_carry_adder_8bit" "carry_lookahead_adder_8bit" "carry_select_adder_8bit"]

foreach top_mod $adders {
    puts "==> Synthesizing $top_mod..."
    reset_design -quiet
    read_verilog [glob "$root_dir/rtl/*.v"]
    synth_design -top $top_mod -part $part -flatten_hierarchy rebuilt
    
    report_utilization -file "$rpt_dir/utilization_${top_mod}.rpt"
    report_timing -file "$rpt_dir/timing_${top_mod}.rpt"
    
    puts $rpt_file "\nArchitecture: $top_mod"
    puts $rpt_file "--------------------------------------------------"
    set fp [open "$rpt_dir/utilization_${top_mod}.rpt" "r"]
    set content [read $fp]
    close $fp
    puts $rpt_file $content
}

close $rpt_file
puts "==> Adder Comparison Synthesis Finished: reports/adder_synth_comparison.rpt"
