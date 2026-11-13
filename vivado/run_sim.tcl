# ==============================================================================
# Script:  run_sim.tcl
# Purpose: Compiles and runs all testbenches using Vivado xsim
# ==============================================================================

set script_dir [file normalize [file dirname [info script]]]
set root_dir   [file normalize "$script_dir/.."]
set sim_dir    [file normalize "$root_dir/simulation"]

file mkdir $sim_dir

set testbenches [list "tb_adder_comparison" "tb_alu" "tb_reg_file" "tb_alu_regfile_top"]

foreach tb $testbenches {
    puts "======================================================================"
    puts "  RUNNING VIVADO XSIM: $tb"
    puts "======================================================================"
    
    # Parse Verilog sources
    exec xvlog [glob "$root_dir/rtl/*.v"] "$root_dir/testbench/$tb.v"
    
    # Elaborate design
    exec xelab -top $tb -snapshot "${tb}_snap" -debug typical
    
    # Simulate
    exec xsim "${tb}_snap" -tclbatch "$script_dir/xsim_cfg.tcl" -log "$sim_dir/${tb}_vivado.log"
}

puts "==> All Vivado simulations completed."
