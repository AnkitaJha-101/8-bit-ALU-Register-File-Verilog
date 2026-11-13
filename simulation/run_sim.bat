@echo off
REM ============================================================================
REM Automation Script: Run All Simulations
REM Checks for Icarus Verilog (iverilog/vvp) or Vivado (xvlog/xelab/xsim)
REM Falls back automatically to the cycle-accurate Python simulation engine.
REM ============================================================================

echo ======================================================================
echo   8-bit ALU with Register File & Adder Analysis Simulation Suite
echo ======================================================================

where iverilog >nul 2>nul
if %ERRORLEVEL% EQU 0 (
    echo [FOUND] Icarus Verilog detected. Running compiled simulations...
    
    echo [1/4] Compiling and simulating Adder Comparison...
    iverilog -g2001 -o sim_adder.vvp ../rtl/full_adder.v ../rtl/ripple_carry_adder_8bit.v ../rtl/cla_4bit.v ../rtl/carry_lookahead_adder_8bit.v ../rtl/carry_select_adder_8bit.v ../testbench/tb_adder_comparison.v
    vvp sim_adder.vvp > adder_comparison_sim.log
    type adder_comparison_sim.log

    echo [2/4] Compiling and simulating 8-bit ALU...
    iverilog -g2001 -o sim_alu.vvp ../rtl/full_adder.v ../rtl/ripple_carry_adder_8bit.v ../rtl/cla_4bit.v ../rtl/carry_lookahead_adder_8bit.v ../rtl/carry_select_adder_8bit.v ../rtl/alu_8bit.v ../testbench/tb_alu.v
    vvp sim_alu.vvp > alu_sim.log
    type alu_sim.log

    echo [3/4] Compiling and simulating Register File...
    iverilog -g2001 -o sim_regfile.vvp ../rtl/register_file_8x8.v ../testbench/tb_reg_file.v
    vvp sim_regfile.vvp > regfile_sim.log
    type regfile_sim.log

    echo [4/4] Compiling and simulating Top-Level ALU + Register File...
    iverilog -g2001 -o sim_top.vvp ../rtl/full_adder.v ../rtl/ripple_carry_adder_8bit.v ../rtl/cla_4bit.v ../rtl/carry_lookahead_adder_8bit.v ../rtl/carry_select_adder_8bit.v ../rtl/alu_8bit.v ../rtl/register_file_8x8.v ../rtl/alu_regfile_top.v ../testbench/tb_alu_regfile_top.v
    vvp sim_top.vvp > alu_regfile_top_sim.log
    type alu_regfile_top_sim.log

    del *.vvp 2>nul
    echo Simulations complete.
    exit /b 0
)

echo [INFO] Icarus Verilog not found in system PATH.
echo [RUNNING] Executing Python Cycle-Accurate Verilog Verification Engine...
python sim_engine.py
if %ERRORLEVEL% NEQ 0 (
    echo [ERROR] Simulation encountered failures.
    exit /b 1
)
echo [SUCCESS] All simulations executed and verified successfully.
exit /b 0
