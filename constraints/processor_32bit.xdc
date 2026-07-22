# =============================================================================
# 32-BIT RV32IM 5-STAGE PIPELINED RISC-V PROCESSOR
# Vivado Timing Constraints
# =============================================================================


# -----------------------------------------------------------------------------
# CLOCK CONSTRAINT
# -----------------------------------------------------------------------------
# Target clock frequency: 90 MHz
#
# 90 MHz -> clock period = 11.111 ns
#
# The clock period is selected to provide timing margin for the
# implemented RV32IM five-stage pipelined processor.
# -----------------------------------------------------------------------------

create_clock -name sys_clk -period 11.111 -waveform {0.000 5.555} [get_ports clk]


# -----------------------------------------------------------------------------
# RESET
# -----------------------------------------------------------------------------
# Reset is treated as an asynchronous/external control input for timing
# purposes. No physical PACKAGE_PIN is assigned here because the actual
# FPGA board/pin has not been specified.
# -----------------------------------------------------------------------------

set_false_path -from [get_ports reset]


# =============================================================================
# DEBUG OUTPUTS
# =============================================================================
#
# These signals are intentionally exposed from top_level_riscv for synthesis
# observability:
#
# debug_pc[31:0]
# debug_instruction[31:0]
# debug_alu_result[31:0]
# debug_wb_data[31:0]
# debug_wb_rd[4:0]
# debug_reg_write
# debug_stall
# debug_branch_taken
#
# No PACKAGE_PIN assignments are made here.
#
# For the final FPGA implementation, these should preferably be observed
# using an ILA/debug interface rather than attempting to connect every
# debug bit to physical FPGA pins.
# =============================================================================