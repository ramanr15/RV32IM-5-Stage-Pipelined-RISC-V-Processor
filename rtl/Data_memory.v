`timescale 1ns / 1ps

module data_mem (

    input  wire        clk,

    input  wire        mem_read,
    input  wire        mem_write,

    input  wire [31:0] address,
    input  wire [31:0] write_data,

    input  wire [3:0]  write_mask,

    output reg  [31:0] read_data

);

    // ============================================================
    // 4 KB DATA MEMORY
    //
    // 1024 words x 32 bits = 4096 bytes = 4 KB
    //
    // address[11:2] selects one 32-bit word.
    // write_mask provides byte enables:
    //
    // write_mask[0] -> bits  7:0
    // write_mask[1] -> bits 15:8
    // write_mask[2] -> bits 23:16
    // write_mask[3] -> bits 31:24
    //
    // RAM_STYLE encourages Vivado to infer Block RAM.
    // ============================================================

    (* ram_style = "block" *)
    reg [31:0] memory [0:1023];

    wire [9:0] word_address;

    assign word_address = address[11:2];


    // ============================================================
    // SYNCHRONOUS WRITE
    // ============================================================

    always @(posedge clk) begin

        if (mem_write) begin

            if (write_mask[0])
                memory[word_address][7:0] <= write_data[7:0];

            if (write_mask[1])
                memory[word_address][15:8] <= write_data[15:8];

            if (write_mask[2])
                memory[word_address][23:16] <= write_data[23:16];

            if (write_mask[3])
                memory[word_address][31:24] <= write_data[31:24];

        end

    end


    // ============================================================
    // SYNCHRONOUS READ
    // ============================================================

    always @(posedge clk) begin

        if (mem_read)
            read_data <= memory[word_address];

        else
            read_data <= 32'b0;

    end


endmodule