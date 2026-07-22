`timescale 1ns / 1ps

module instr_mem (
    input  wire [31:0] addr,
    output wire [31:0] instruction
);

    reg [31:0] memory [0:1023];

    integer i;

    initial begin

        // Fill instruction memory with NOPs first
        for (i = 0; i < 1024; i = i + 1)
            memory[i] = 32'h00000013;

        // Load RISC-V machine-code program
        $readmemh("program.mem", memory);

    end

    // Word-addressed instruction memory
    assign instruction = memory[addr[11:2]];

endmodule