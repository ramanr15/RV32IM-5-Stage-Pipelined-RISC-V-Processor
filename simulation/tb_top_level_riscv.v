`timescale 1ns / 1ps

module tb_top_level_riscv;

    reg clk;
    reg reset;

    integer cycle;
    integer i;
// ============================================================
// DEBUG OUTPUT WIRES FROM PROCESSOR
// ============================================================

wire [31:0] debug_pc;
wire [31:0] debug_instruction;
wire [31:0] debug_alu_result;
wire [31:0] debug_wb_data;
wire [4:0]  debug_wb_rd;
wire        debug_reg_write;
wire        debug_stall;
wire        debug_branch_taken;
    // ============================================================
    // DUT
    // ============================================================

top_level_riscv DUT (
    .clk                (clk),
    .reset              (reset),

    .debug_pc            (debug_pc),
    .debug_instruction   (debug_instruction),
    .debug_alu_result    (debug_alu_result),
    .debug_wb_data       (debug_wb_data),
    .debug_wb_rd         (debug_wb_rd),
    .debug_reg_write     (debug_reg_write),
    .debug_stall         (debug_stall),
    .debug_branch_taken  (debug_branch_taken)
);

    // ============================================================
    // CLOCK
    // ============================================================

    initial begin

        clk = 1'b0;

        forever #5 clk = ~clk;

    end

    // ============================================================
    // INITIALIZATION
    // ============================================================

    initial begin

        cycle = 0;

        reset = 1'b1;

        // Reset for 2 clock periods
        #20;

        reset = 1'b0;

        // Run for 300 cycles
        #4000;

        // ========================================================
        // FINAL REGISTER DUMP
        // ========================================================

        $display("");
        $display("");
        $display("================================================================================");
        $display("                         FINAL RV32IM REGISTER DUMP");
        $display("================================================================================");
        $display(" REGISTER       HEX VALUE        SIGNED DECIMAL       UNSIGNED DECIMAL");
        $display("--------------------------------------------------------------------------------");

        for (i = 0; i < 32; i = i + 1) begin

            $display(
                " x%02d           %08h         %12d         %12d",
                i,
                DUT.REGISTER_FILE.registers[i],
                $signed(DUT.REGISTER_FILE.registers[i]),
                DUT.REGISTER_FILE.registers[i]
            );

        end

        $display("================================================================================");

        $display("");
        $display("FINAL PC       = 0x%08h", DUT.pc);

        $display("MTVEC          = 0x%08h", DUT.CSR_UNIT.mtvec);
        $display("MEPC           = 0x%08h", DUT.CSR_UNIT.mepc);
        $display("MCAUSE         = 0x%08h", DUT.CSR_UNIT.mcause);
        $display("MTVAL          = 0x%08h", DUT.CSR_UNIT.mtval);
        $display("MSTATUS        = 0x%08h", DUT.CSR_UNIT.mstatus);

        $display("");
        $display("================================================================================");
        $display("                           SIMULATION COMPLETED");
        $display("================================================================================");
        $display("");

        $finish;

    end

    // ============================================================
    // CYCLE COUNTER
    // ============================================================

    always @(posedge clk) begin

        if (reset)

            cycle <= 0;

        else

            cycle <= cycle + 1;

    end

    // ============================================================
    // PIPELINE TABLE
    // ============================================================

    initial begin

        $display("");
        $display("==========================================================================================================================================================================================");
        $display("                                                   RV32IM 5-STAGE PIPELINE EXECUTION TABLE");
        $display("==========================================================================================================================================================================================");

        $display(
        "CYCLE | IF_PC    | IF_INSTR | ID_PC    | ID_INSTR | EX_PC    | EX_INSTR | EX_RESULT | MEM_RESULT | WB_RD | WB_RESULT | STALL | FWD_A | FWD_B | BR | PRED | REDIR | TRAP"
        );

        $display(
        "------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------"
        );

    end

    always @(posedge clk) begin

        if (!reset) begin

            #1;

            $display(
                "%5d | %08h | %08h | %08h | %08h | %08h | %08h | %08h | %08h   | x%02d  | %08h  |   %b   |  %02b   |  %02b   | %b  |  %b   |   %b   |  %b",

                cycle,

                DUT.pc,
                DUT.instruction_if,

                DUT.pc_id,
                DUT.instruction_id,

                DUT.pc_ex,
                DUT.instruction_ex,

                DUT.execute_result_ex,

                DUT.execute_result_mem,

                DUT.rd_wb,

                DUT.wb_result,

                DUT.stall,

                DUT.forward_a,

                DUT.forward_b,

                DUT.actual_branch_taken_ex,

                DUT.predicted_taken_ex,

                DUT.redirect_ex,

                DUT.exception_ex
            );

        end

    end

    // ============================================================
    // WRITEBACK MONITOR
    // ============================================================

    always @(posedge clk) begin

        if (!reset &&
            DUT.reg_write_wb &&
            (DUT.rd_wb != 0)) begin

            #1;

            $display(
                "      >>> WRITEBACK : x%0d <= 0x%08h   signed=%0d",
                DUT.rd_wb,
                DUT.wb_result,
                $signed(DUT.wb_result)
            );

        end

    end

    // ============================================================
    // STALL MONITOR
    // ============================================================

    always @(posedge clk) begin

        if (!reset && DUT.stall) begin

            $display("");
            $display(
                "      >>> LOAD-USE STALL detected at ID PC = 0x%08h",
                DUT.pc_id
            );
            $display("");

        end

    end

    // ============================================================
    // FORWARDING MONITOR
    // ============================================================

    always @(posedge clk) begin

        if (!reset) begin

            if (DUT.forward_a != 2'b00)

                $display(
                    "      >>> FORWARD A : selector = %02b",
                    DUT.forward_a
                );

            if (DUT.forward_b != 2'b00)

                $display(
                    "      >>> FORWARD B : selector = %02b",
                    DUT.forward_b
                );

        end

    end

    // ============================================================
    // RV32M MONITOR
    // ============================================================

    always @(posedge clk) begin

        if (!reset && DUT.is_muldiv_ex) begin

            $display("");
            $display(
                "      >>> RV32M OPERATION : PC=%08h FUNCT3=%03b A=%08h B=%08h RESULT=%08h",
                DUT.pc_ex,
                DUT.funct3_ex,
                DUT.forwarded_a,
                DUT.forwarded_b,
                DUT.muldiv_result_ex
            );
            $display("");

        end

    end

    // ============================================================
    // BRANCH MONITOR
    // ============================================================

    always @(posedge clk) begin

        if (!reset && DUT.branch_ex) begin

            $display("");
            $display(
                "      >>> BRANCH : PC=%08h ACTUAL=%b PREDICTED=%b TARGET=%08h",
                DUT.pc_ex,
                DUT.actual_branch_taken_ex,
                DUT.predicted_taken_ex,
                DUT.branch_target_ex
            );

            if (DUT.branch_mispredict_ex)

                $display(
                    "      >>> BRANCH MISPREDICTION -> RECOVERY PC = %08h",
                    DUT.recovery_pc_ex
                );

            $display("");

        end

    end

    // ============================================================
    // JUMP MONITOR
    // ============================================================

    always @(posedge clk) begin

        if (!reset && DUT.jump_ex) begin

            $display("");
            $display(
                "      >>> JUMP : PC=%08h TARGET=%08h",
                DUT.pc_ex,
                DUT.jump_target_ex
            );
            $display("");

        end

    end

// ============================================================
// MEMORY ACCESS MONITOR
// Synchronous BRAM-style Data Memory
// ============================================================

always @(negedge clk) begin

    // --------------------------------------------------------
    // STORE
    // Current MEM-stage store request
    // --------------------------------------------------------
if (!reset && DUT.mem_write_mem_reg) begin

    $display("");

    $display(
        "      >>> MEMORY WRITE : ADDR=%08h DATA=%08h MASK=%04b",
        DUT.execute_result_mem,
        DUT.formatted_store_data,
        DUT.write_mask
    );

    $display("");

end
    // --------------------------------------------------------
    // LOAD REQUEST
    // Address currently presented to synchronous Data Memory
    // --------------------------------------------------------

    if (!reset && DUT.mem_read_mem_reg) begin

        $display("");

        $display(
            "      >>> MEMORY READ REQUEST : ADDR=%08h",
            DUT.execute_result_mem
        );

        $display("");

    end


    // --------------------------------------------------------
    // LOAD RESPONSE
    //
    // memory_read_data corresponds to the previous memory
    // request. Therefore use the delayed address/control.
    // --------------------------------------------------------

    if (!reset && DUT.mem_to_reg_delay) begin

        $display("");

        $display(
            "      >>> MEMORY READ RESPONSE : ADDR=%08h RAW=%08h FORMATTED=%08h",
            DUT.load_address_delay,
            DUT.memory_read_data,
            DUT.formatted_load_data
        );

        $display("");

    end

end
    // ============================================================
    // CSR MONITOR
    // ============================================================

    always @(posedge clk) begin

        if (!reset && DUT.csr_instruction_ex) begin

            $display("");
            $display(
                "      >>> CSR OPERATION : PC=%08h CSR=%03h OLD_VALUE=%08h",
                DUT.pc_ex,
                DUT.instruction_ex[31:20],
                DUT.csr_read_data_ex
            );
            $display("");

        end

    end

    // ============================================================
    // EXCEPTION / TRAP MONITOR
    // ============================================================

    always @(posedge clk) begin

        if (!reset && DUT.exception_ex) begin

            $display("");
            $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            $display("                     EXCEPTION / TRAP");
            $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");

            $display(
                "PC       = 0x%08h",
                DUT.pc_ex
            );

            $display(
                "INSTR    = 0x%08h",
                DUT.instruction_ex
            );

            $display(
                "CAUSE    = %0d",
                DUT.exception_cause_ex
            );

            $display(
                "MTVAL    = 0x%08h",
                DUT.exception_value_ex
            );

            $display(
                "MTVEC    = 0x%08h",
                DUT.mtvec
            );

            $display(
                "REDIRECT = 0x%08h",
                DUT.mtvec
            );

            $display("!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!");
            $display("");

        end

    end

    // ============================================================
    // MRET MONITOR
    // ============================================================

    always @(posedge clk) begin

        if (!reset && DUT.mret_ex) begin

            $display("");
            $display(
                "      >>> MRET : Returning to MEPC = 0x%08h",
                DUT.mepc
            );
            $display("");

        end

    end

    // ============================================================
    // FENCE.I MONITOR
    // ============================================================

    always @(posedge clk) begin

        if (!reset && DUT.fence_i_ex) begin

            $display("");
            $display(
                "      >>> FENCE.I : Fetch pipeline flushed"
            );
            $display("");

        end

    end

endmodule