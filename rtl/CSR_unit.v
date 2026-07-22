module csr_unit (

    input wire clk,
    input wire reset,

    // CSR instruction access
    input wire csr_enable,

    input wire [2:0] csr_funct3,

    input wire [11:0] csr_address,

    input wire [31:0] rs1_value,
    input wire [4:0] zimm,

    output reg [31:0] csr_read_data,


    // Trap entry
    input wire trap_enter,

    input wire [31:0] trap_pc,
    input wire [31:0] trap_cause,
    input wire [31:0] trap_value,


    // MRET
    input wire mret,

    output wire [31:0] mtvec_out,
    output wire [31:0] mepc_out

);


// ============================================================
// MACHINE CSRs
// ============================================================

reg [31:0] mstatus;
reg [31:0] mtvec;

reg [31:0] mepc;
reg [31:0] mcause;
reg [31:0] mtval;

reg [63:0] mcycle;
reg [63:0] minstret;


assign mtvec_out = mtvec;

assign mepc_out = mepc;


// ============================================================
// CSR READ
// ============================================================

always @(*) begin

    case (csr_address)

        12'h300:
            csr_read_data = mstatus;

        12'h305:
            csr_read_data = mtvec;

        12'h341:
            csr_read_data = mepc;

        12'h342:
            csr_read_data = mcause;

        12'h343:
            csr_read_data = mtval;

        12'hB00:
            csr_read_data = mcycle[31:0];

        12'hB80:
            csr_read_data = mcycle[63:32];

        12'hB02:
            csr_read_data = minstret[31:0];

        12'hB82:
            csr_read_data = minstret[63:32];

        default:
            csr_read_data = 32'b0;

    endcase

end


// ============================================================
// CSR SOURCE
// ============================================================

reg [31:0] csr_source;

always @(*) begin

    if (csr_funct3[2])
        csr_source = {27'b0, zimm};
    else
        csr_source = rs1_value;

end


// ============================================================
// CSR WRITE VALUE
// ============================================================

reg [31:0] csr_write_value;

always @(*) begin

    case (csr_funct3[1:0])

        // CSRRW / CSRRWI
        2'b01:
            csr_write_value = csr_source;

        // CSRRS / CSRRSI
        2'b10:
            csr_write_value =
                csr_read_data | csr_source;

        // CSRRC / CSRRCI
        2'b11:
            csr_write_value =
                csr_read_data & ~csr_source;

        default:
            csr_write_value = csr_read_data;

    endcase

end


// ============================================================
// CSR UPDATE
// ============================================================

always @(posedge clk) begin

    if (reset) begin

        mstatus <= 32'b0;

        // Trap vector
        mtvec <= 32'h00000100;

        mepc   <= 32'b0;
        mcause <= 32'b0;
        mtval  <= 32'b0;

        mcycle   <= 64'b0;
        minstret <= 64'b0;

    end

    else begin

        mcycle <= mcycle + 64'd1;


        // --------------------------------------------------------
        // TRAP ENTRY
        // --------------------------------------------------------

        if (trap_enter) begin

            mepc   <= trap_pc;

            mcause <= trap_cause;

            mtval  <= trap_value;

            // MIE -> MPIE
            mstatus[7] <= mstatus[3];

            // Disable interrupts
            mstatus[3] <= 1'b0;

            // MPP = Machine
            mstatus[12:11] <= 2'b11;

        end


        // --------------------------------------------------------
        // MRET
        // --------------------------------------------------------

        else if (mret) begin

            mstatus[3] <= mstatus[7];

            mstatus[7] <= 1'b1;

            mstatus[12:11] <= 2'b00;

        end


        // --------------------------------------------------------
        // CSR WRITE
        // --------------------------------------------------------

        else if (csr_enable) begin

            case (csr_address)

                12'h300:
                    mstatus <= csr_write_value;

                12'h305:
                    mtvec <= csr_write_value;

                12'h341:
                    mepc <= csr_write_value;

                12'h342:
                    mcause <= csr_write_value;

                12'h343:
                    mtval <= csr_write_value;

                default: begin
                end

            endcase

        end

    end

end

endmodule